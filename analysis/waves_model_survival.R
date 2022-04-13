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
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# load functions 'coxmodel_list()'
source(here("analysis", "utils", "model_coxph.R"))
# create vector containing subgroups
subgroups_vctr <- c(config$demographics, config$comorbidities)
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3")

# Import data extracts of waves ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
names(data_processed) <- waves_vctr

# Survival modeling ---
# creates list with 2 levels, first level is 'wave1', 'wave2', 'wave3' and 
# second level is 'effect_estimates' and 'ph_tests'
# (second level = output of function 'coxmodel_list')
output_cox_models <- map(.x = data_processed,
                         .f = ~ coxmodel_list(data = .x,
                                              variables = subgroups_vctr))
# removes upper level --> names of list will be 'wave1.effect_estimates', 
# 'wave1.ph_tests' etc...
output_cox_models <- unlist(output_cox_models, recursive = FALSE)
# replace . in new names with _ (used to save output later)
names(output_cox_models) <- str_replace(names(output_cox_models),
                                        "[.]",
                                        "_")

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
# .y is equal to names of output_cox_models
iwalk(.x = output_cox_models,
      .f = ~ write.csv(.x,
                       paste0(output_dir, "/", .y, ".csv")))
