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
# levels of the 'variable' minus one. First column contains the names of the 
# coefficients of the model, second column contains the HR, third
# and fourth column contain the lower and upper CI. The row.names are name of 
# the variable.
# - 'ph_test'
# named data.frame with 2 columns and one row: contains the global test of 
# the proportional hazards assumption of the Cox regression.
coxmodel <- function(data, variable) {
  # init formula adjusted for age using rcs with 4 knots, sex, stratified by 
  # stp to account for regional differences in infection rates
  # init 'n_vars' (= number of terms in formula) which is used to make matrix
  # ph_test if error occurs (mostly of use for dummy data)
  if (variable == "agegroup") {
    formula <- as.formula(paste0("Surv(fu, status == 1) ~", 
                                 variable, 
                                 "+ sex + strata(stp)"))
    n_vars <- 2
  } else if (variable == "sex") {
    formula <- as.formula(paste0("Surv(fu, status == 1) ~", 
                                 variable, 
                                 "+ rcs(age, 4) + strata(stp)")) 
    n_vars <- 2
  } else {
    formula <- as.formula(paste0("Surv(fu, status == 1) ~", 
                                 variable, 
                                 "+ rcs(age, 4) + sex + strata(stp)"))
    n_vars <- 3
  }
  # init objects in which output is saved ---
  # create data.frame 'out' where output is saved 
  # out has 5 columns with the HR and upper and lower limit of CI
  # and number of rows is equal to number of levels of 'variable' minus one
  if ({v <- data %>% pull(variable)} %>% is.factor){
    n_levels_variable <- v %>% levels() %>% length()
  } else if (v %>% is.logical()){
    n_levels_variable <- 2
  }
  out <- matrix(nrow = n_levels_variable - 1, ncol = 5) %>% as.data.frame()
  # give column names
  colnames(out) <- c("subgroup", "level", "HR", "LowerCI", "UpperCI")
  # save variable for reference
  out[, 1] <- rep(variable, n_levels_variable - 1)
  # create data.frame 'out_ph' where global test for ph assumption is saved
  out_ph <- matrix(nrow = 1, ncol = 2) %>% as.data.frame()
  # give column names
  colnames(out_ph) <- c("subgroup", "p")
  # save variable for reference
  out_ph[1, 1] <- variable
  # create data.frame 'log_file' where error and warning messages are saved
  log_file <- matrix(nrow = 1, ncol = 3) %>% as.data.frame()
  # give column names
  colnames(log_file) <- c("subgroup", "warning_coxph", "error_cox.zph")
  # save variable in 'log_file' for reference
  log_file[1, 1] <- variable
  # Cox regression
  # returns function model() with components result, output, messages and warnings
  model <- safely(.f = ~ quietly(.f = ~ coxph(formula, data)),
                  otherwise = NULL)
  if (!is.null(model()$result)){
    # Test PH assumption
    # returns function test_ph() with components result and error
    # if error, return matrix with NAs with the same
    # dimensions as when there is no error
    # nrow is 3 (variable, rcs(age,4) and sex) 
    # plus 1 (global test) (= 4)
    # ncol is 3, chisq, df and p
    test_ph <- safely(.f = ~ cox.zph(model()$result()$result)$table,
                      otherwise = matrix(nrow = n_vars + 1, ncol = 3))
    # output processing ---
    # create vector with booleans (TRUE for main effect else FALSE) used to 
    # select main effects from 'model'
    selection <- model()$result()$result$coefficients %>% names %>% startsWith(variable)
    # save output ---
    # save coefficients of model and CIs in out
    out[, 2] <- names(model()$result()$result$coefficients)[selection] %>% 
      sub(variable, "", .)
    out[, 3] <- model()$result()$result$coefficients[selection] %>% exp()
    out[, 4:5] <- confint(model()$result()$result)[selection,] %>% exp()
    # save global test in 'out_ph'
    out_ph[1, 2] <- test_ph()$result[n_vars + 1, 3]
    # save warnings
    if(length(model()$result()$warnings) != 0){
      log_file[, 2] <- model()$result()$warnings
    } else log_file[, 2] <- NA_character_
    if(!is.null(test_ph()$error)){
      log_file[, 3] <- test_ph()$error$message
    } else log_file[, 3] <- NA_character_
  }
  list(effect_estimates = out, 
       ph_test = out_ph,
       log_file = log_file)
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
  coxmodels_output <- 
    map(.x = variables,
        .f = ~ coxmodel(data, .x)) 
  # output
  effect_estimates <- coxmodels_output[[1]]$effect_estimates
  ph_tests <- coxmodels_output[[1]]$ph_test
  log_file <- coxmodels_output[[1]]$log_file
  for (i in seq_along(coxmodels_output)[-1]) {
    effect_estimates <-
      rbind(effect_estimates,
            coxmodels_output[[i]]$effect_estimates)
    ph_tests <- 
      rbind(ph_tests,
            coxmodels_output[[i]]$ph_test)
    log_file <- 
      rbind(log_file,
            coxmodels_output[[i]]$log_file)
  }
  list(effect_estimates = effect_estimates, 
       ph_tests = ph_tests,
       log_file = log_file)
}
