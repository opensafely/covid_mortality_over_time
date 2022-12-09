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
library(stringr)
library(fs)
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# load functions 'coxmodel_list()'
source(here("analysis", "utils", "model_coxph.R"))
# create vector containing subgroups
# each model is stratified by stp so region is excluded here
subgroups_vctr <- c(config$demographics[config$demographics != "region"], 
                    config$comorbidities)
# add agegroup and sex
subgroups_vctr <- c("agegroup", "sex", subgroups_vctr, "imp_vax")

# Import data extracts of waves ---
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  wave <- "wave1"
  output_dir <- "output/tables"
} else {
  wave <- args[[1]]
  output_dir <- args[[2]]
}

rds_file <- here("output", "processed", paste0("input_", wave, ".rds"))
data_processed <- readRDS(rds_file)

# Survival modeling ---
# creates list with 2 levels, first level is 'wave1', 'wave2', 'wave3' and 
# second level is 'effect_estimates' and 'ph_tests'
# (second level = output of function 'coxmodel_list')
output_cox_models <- coxmodel_list(data = data_processed,
                                   variables = subgroups_vctr)

# Save output --
dir_create(output_dir)

# .y is equal to names of output_cox_models
iwalk(.x = output_cox_models,
      .f = ~ write.csv(.x,
                       row.names = FALSE,
                       path(output_dir, paste0(wave, "_", .y, ".csv"))))
