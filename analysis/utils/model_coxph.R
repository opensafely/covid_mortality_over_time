## ###########################################################

##  This script:
## - Contains functions used for cox PH modeling

## linda.nab@thedatalab.com - 20220413
## ###########################################################

# Load libraries & functions ---
library(purrr)
library(dplyr)
library(survival)
library(rms)

# Survival modelling ---
# Function 'coxmodel()'
# arguments:
# - data: data.frame with the data extract of one of the pandemic waves
# - variable: string with the variable (one of the subgroups, usually one of the
#   variables in config$demographics/ config$comorbidities)
# output:
# list of:
# - 'effect_estimates'
# named data.frame with 4 columns and number of rows equal to the number of 
# levels of the 'variable' minus one. First column contains the HR, second 
# and third column contains the lower and upper CI, 
# - 'ph_test'
# named data.frame with 2 columns and one row: contains the global test of 
# the proportional hazards assumption of the Cox regression
coxmodel <- function(data, variable) {
  # init formula adjusted for age using rcs with 4 knots, sex, stratified by 
  # stp to account for regional differences in infection rates
  formula <- as.formula(paste0("Surv(fu, status == 1) ~", 
                               variable, 
                               "+ rcs(age, 4) + sex + strata(stp)"))
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
  print(variable)
  print(test_ph)
  # output processing ---
  # create vector with booleans (TRUE for main effect else FALSE) used to 
  # select main effects from 'model'ß
  selection <- model$coefficients %>% names %>% startsWith(variable)
  # count number of estimated main effects (levels of 'variable' minus one)
  # which is used to create the data.frame 'out' with output
  n_selection <- sum(selection)
  # init objects in which output is saved ---
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
  list(effect_estimates = out, ph_test = out_ph)
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
# - 'ph_tests' named data.frame with 1 column named 'p' and number of rows equal 
# to number of items in argument 'variable' (--> rownames equal to 'variable')
coxmodel_list <- function(data, variables) {
  # create data.frame with all main effect estimates + CIs
  effect_estimates_df <- 
    map_dfr(.x = variables,
            .f = ~ coxmodel(data, .x)$effect) 
  # create data.frame with global PH test
  ph_tests_df <- 
    map_dfr(.x = variables,
            .f = ~ coxmodel(data, .x)$ph_test) 
  # output
  list(effect_estimates = effect_estimates_df, 
       ph_tests = ph_tests_df)
}
