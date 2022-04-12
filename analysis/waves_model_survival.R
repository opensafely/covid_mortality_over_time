## ###########################################################

##  This script:
## - Imports data of the three waves
## - Models Cox PH
## - Test Cox models for PH assumption
## - Saves effect estimates + associated CIs in 
##   ./output/tables/wave*_effect_estimates
## - Saves PH tests in 
##   ./output/tables/wave*_ph_tests

## linda.nab@thedatalab.com - 20220304
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(survival)
library(rms)
## Load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# create vector containing subgroups
subgroups_vctr <- c(config$demographics, config$comorbidities)

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
## add variable fu
data_processed <-
  map2(.x = data_processed,
       .y = c(config$wave1$start_date, 
              config$wave2$start_date,
              config$wave3$start_date),
       .f = ~ mutate(.x, 
                     fu = difftime(died_ons_covid_flag_any_date, .y)))
names(data_processed) <- c("wave1", "wave2", "wave3")

# Survival modelling ---
# Function 'coxmodel()'
# arguments:
# - data: data.frame with the data extract of one of the pandemic waves
# - variable: string with the variable (one of the subgroups, usually one of the
#   variables in config$demographics/ config$comorbidities)
# output:
# list of:
# - named data.frame with 4 columns and number of rows equal to the number of 
# levels of the 'variable' minus one. First column contains the HR, second 
# and third column contains the lower and upper CI, 
# - named data.frame with 2 columns and one row: contains the global test of 
# the proportional hazards assumption of the Cox regression
coxmodel <- function(data, variable) {
  # init formula adjusted for age using rcs with 4 knots, sex, stratified by 
  # region to account for regional differences in infection rates
  formula <- as.formula(paste0("Surv(fu, died_ons_covid_flag_any) ~", 
                        variable, 
                        "+ rcs(age, 4) + sex + strata(region)"))
  # Cox regression
  model <- coxph(formula, data)
  # Test PH assumption
  test_ph <- tryCatch(cox.zph(model)$table,
                      error = 
                        # if error, return matrix with NAs with the same
                        # dimensions as when there is no error
                        # nrow is 3 (variable, rcs(age,4) and sex) 
                        # plus 1 (global test) (= 4)
                        # ncol is 3, chisq, df and p
                        function(e) {
                          out <- matrix(nrow = 4,
                                        ncol = 3)
                          return(out)}
  )
  # output processing
  # create vector with booleans (TRUE for main effect)
  selection <- model$coefficients %>% names %>% startsWith(variable)
  # count number of estimated main effects (levels of 'variable' minus one)
  # which is used to create the data.frame 'out' with output
  n_selection <- sum(selection)
  # init objects in whcih output is saved ---
  # create data.frame 'out' where output is saved 
  # out has 3 columns with the HR and upper and lower limit of CI
  # and number of rows is equal to number of levels of 'variable' minus one
  out <- matrix(nrow = n_selection, ncol = 3) %>% as.data.frame()
  # give row and column names
  dimnames(out) <- list(names(model$coefficients)[selection],
                        c("HR", "LowerCI", "UpperCI"))
  # create data.frame 'out_ph' where global test for ph assumption is saved
  out_ph <- matrix(nrow = 1, ncol = 1) %>% as.data.frame()
  # give row and column names
  dimnames(out_ph) <- list(variable, "p")
  # save output ---
  # save coefficients of model and CIs in out
  out[, 1] <- model$coefficients[selection] %>% exp()
  out[, 2:3] <- confint(model)[selection,] %>% exp()
  # save global test in 'out_ph'
  out_ph[1, 1] <- test_ph[4, 3]
  list(effects = out, ph_test = out_ph)
}
# Function 'coxmodel_list()'
# arguments:
# - data: data.frame with the data extract of one of the pandemic waves
# - variables: vector with strings of the variables (all subgroups, usually the
#   variables in config$demographics + config$comorbidities)
# output:
# list of:
# - 'effect_estimates': named data.frame with 3 columns and number of rows 
# equal to the number of variables in argument 'variables' times (the number of 
# levels minus one)
# - 'ph_test' named data.frame with 1 column named 'p' and number of rows equal 
# to number of items in argument 'variable' (+ rownames equal to 'variable')
coxmodel_list <- function(data, variables) {
  # create data.frame with all main effect estimates + CIs
  effects_list <- 
    map_dfr(.x = variables,
            .f = ~ coxmodel(data, .x)$effect) 
  # create list with global PH test
  ph_list <- 
    map_dfr(.x = variables,
            .f = ~ coxmodel(data, .x)$ph_test) 
  # output
  list(effect_estimates = effects_list, 
       ph_tests = ph_list)
}
# create list with 2 levels, first level is 'wave1', 'wave2', 'wave3' and 
# second level is 'effect_estimates' and 'ph_tests'
# (second level = output of function 'coxmodel_list')
output_cox_models <- map(.x = data_processed,
                         .f = ~ coxmodel_list(data = .x,
                                              variables = subgroups_vctr))
# remove upper level --> names of list will be 'wave1.effect_estimates', 
# 'wave1.ph_tests' etc...
output_cox_models <- unlist(output_cox_models, recursive = FALSE)
# replace . in new names with _ (used to save output later)
names(output_cox_models) <- str_replace(names(output_cox_models),
                                        "[.]",
                                        "_")
# to do: 
# - account for competing risk death from other cause

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
# .y is equal to names of output_cox_models
iwalk(.x = output_cox_models,
      .f = ~ write.csv(.x,
                       paste0(output_dir, "/", .y, ".csv")))

