## ###########################################################

##  This script:
## - Imports data of the three waves
## - Models Cox PH
## - Saves effect estimates + associated CIs

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

# Kaplan-Meiers

# Survival modelling ---
# Function 'coxmodel()'
# arguments:
# - data: data.frame with the data extract of one of the pandemic waves
# - variable: string with the variable (one of the subgroups, usually one of the
#   variables in config$demographics/ config$comorbidities)
# output:
# named data.frame with 3 columns and number of rows equal to the number of 
# levels of the 'variable' minus one. First column contains the HR and second 
# and third column contains the lower and upper CI
coxmodel <- function(data, variable) {
  # init formula
  formula <- as.formula(paste0("Surv(fu, died_ons_covid_flag_any) ~", 
                        variable, 
                        "+ rcs(age, 4) + sex + strata(region)"))
  # Cox regression
  model <- coxph(formula, data)
  # output processing
  # create vector with booleans (TRUE for main effect)
  selection <- model$coefficients %>% names %>% startsWith(variable)
  # count number of estimated main effects (levels of 'variable' minus one)
  n_selection <- sum(selection)
  # create data.frame with output 
  # out has 3 columns with the HR and upper and lower limit of CI
  # and number of rows is equal to number of levels of 'variable' minus one
  out <- matrix(nrow = n_selection, ncol = 3) %>% as.data.frame()
  # append row and column names
  dimnames(out) <- list(names(model$coefficients)[selection],
                        c("HR", "LowerCI", "UpperCI"))
  # save coefficients of model and CIs
  out[, 1] <- model$coefficients[selection] %>% exp()
  out[, 2:3] <- confint(model)[selection,]
  return(out)
}
# Function 'coxmodel_list()'
# arguments:
# - data: data.frame with the data extract of one of the pandemic waves
# - variables: vector with strings of the variables (all subgroups, usually the
#   variables in config$demographics + config$comorbidities)
# output:
# named data.frame with 3 columns and number of rows equal to the number of 
# variables in argument 'variables' times (the number of levels minus one) of 
# these variables.
coxmodel_list <- function(data, variables) {
  map_dfr(.x = variables,
          .f = ~ coxmodel(data, .x)) 
}

effect_estimates <- map(.x = data_processed,
                        .f = ~ coxmodel_list(data = .x,
                                             variables = subgroups_vctr))
# to do: 
# - account for competing risk death from other cause
# - check proportional hazard assumption

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = effect_estimates,
      .f = ~ write.csv(.x,
                       paste0(output_dir, "/effect_estimates_", .y, ".csv")))
