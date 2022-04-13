## ###########################################################

##  This script:
## - Imports effect estimates ./output/tables/wave*_effect_estimates.csv
## - Makes 'table two'

## linda.nab@thedatalab.com - 20220413
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# create vector containing subgroups
# each model is stratified by region so region is excluded here
subgroups_vctr <- c(config$demographics[config$demographics != "region"], 
                    config$comorbidities)
comorbidities_multilevel_vctr <- c("asthma",
                                   "bp",
                                   "diabetes_controlled",
                                   "dialysis_kidney_transplant",
                                   "ckd",
                                   "organ_kidney_transplant")
comorbidities_binary_vctr <-
  config$comorbidities[!config$comorbidities %in% comorbidities_multilevel_vctr]
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3")
source(here("analysis", "utils", "reference_values.R"))

# Import data extracts of waves ---
input_files_effect_estimates <-
  Sys.glob(here("output", "tables", "wave*_effect_estimates.csv"))
effect_estimates <- 
  map(.x = input_files_effect_estimates,
      .f = ~ read_csv(.x,
                      col_types = c("c", "c", "d", "d", "d")))
names(effect_estimates) <- waves_vctr

effect_estimates[[1]] <- 
  effect_estimates[[1]] %>% 
  mutate(HR = round(HR, 2),
         LowerCI = round(LowerCI, 2),
         UpperCI = round(UpperCI, 2)) %>%
  mutate(HR_95CI = paste0(HR, " (", LowerCI, ";", UpperCI, ")"))
effect_estimates[[1]] <- 
  effect_estimates[[1]] %>% 
  select(subgroup, level, HR_95CI)
effect_estimates[[1]] <- 
  effect_estimates[[1]] %>% 
  add_row(subgroup = "bmi", level = "Not obese", HR_95CI = "1.00 (ref)", .before = 1)
colnames(effect_estimates[[1]]) <-
  c("Characteristic", "Category", "COVID-19 Death HR (95% CI)")



gt(effect_estimates[[1]])
