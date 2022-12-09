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
library(gt)
library(stringr)
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# create vector containing subgroups
# each model is stratified by region so region is excluded here
comorbidities <- 
  c(config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))],
    "imp_vax")
# multilevel comorbidities get a reference in table two
comorbidities_multilevel_vctr <- c("asthma",
                                   "diabetes_controlled",
                                   "ckd_rrt",
                                   "organ_kidney_transplant")
comorbidities_binary_vctr <-
  comorbidities[!comorbidities %in% comorbidities_multilevel_vctr]
# needed to add reference values to table two
source(here("analysis", "utils", "reference_values.R"))
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))

# Import data extracts of waves ---
input_files_effect_estimates <-
  Sys.glob(here("output", "tables", "wave*_effect_estimates.csv"))
# vector with waves
waves_vctr <- str_extract(input_files_effect_estimates, "wave[:digit:]")
effect_estimates_list <- 
  map(.x = input_files_effect_estimates,
      .f = ~ read_csv(.x))
names(effect_estimates_list) <- waves_vctr

# Make reference_table_two ---
# Needed to add reference values to table two
reference_table_two <- 
  reference_values %>%
  filter(subgroup %in% c(config$demographics[config$demographics != "region"],
                         "agegroup",
                         "sex",
                         comorbidities_multilevel_vctr)) %>%
  mutate(reference = 
           case_when(subgroup == "sex" & reference == "F" ~ "Female",
                     TRUE ~ reference)) %>%
  mutate(HR_95CI = "1.00 (ref)")
colnames(reference_table_two) <- c("subgroup", "level", "HR_95CI")

# Mutate table with effect estimates ---
# Function 'mutate_table_two' 
# arguments:
# - effect_estimates: data.frame with HR and CIs (typically found in 
#   ./output/tables/wave*_effect_estimates.csv)
# - subgroups_vctr: vector of strings with all subgroups in the study
# - reference_table_two: data.frame with columns 'subgroup' and 'level', 
#   and a third column "HR_95CI' with "1.00 (ref)" for every combination of 
#   subgroup and level
# output:
# mutated data.frame with three columns, 'Characteristic', 'Category' and 
# 'COVID-19 Death HR (95% CI)'
mutate_table_two <- function(effect_estimates, 
                             subgroups_vctr,
                             reference_table_two,
                             suffix){
  effect_estimates <- 
    effect_estimates %>% 
    filter(subgroup %in% subgroups_vctr) %>%
    mutate(HR = round(HR, 2),
           LowerCI = round(LowerCI, 2),
           UpperCI = round(UpperCI, 2)) %>%
    mutate(HR_95CI = paste0(HR, " (", LowerCI, ";", UpperCI, ")")) %>% 
    select(subgroup, level, HR_95CI) %>%
    rbind(reference_table_two, .)
  # group by subgroup
  effect_estimates <-
    effect_estimates[
      match(effect_estimates$subgroup, subgroups_vctr) %>% order(), ] 
  colnames(effect_estimates)[which(colnames(effect_estimates) == "HR_95CI")] <-
    paste0("HR_95CI.", suffix)
  effect_estimates
}

# Mutate table with effect_estimates to one with three columns and with 
# reference values using function 'mutate_table_two' (see output of function
# for names of the three columns)
subgroups_selected <- c("agegroup", "sex", config$demographics, comorbidities)
effect_estimates_list <-
  imap(.x = effect_estimates_list,
       .f = ~ mutate_table_two(.x, subgroups_selected, reference_table_two, .y))

# Create table two ---
# Join three waves to one table
table2 <- 
  plyr::join_all(effect_estimates_list,
                 by = c("subgroup", "level"))
table2 <- 
  rename_subgroups(table2)
# relocate reference value agegroup 
# references values is first, but for agegroup it should be third since
# reference value for agegroup is 50-59
table2 <- table2[c(2, 3, 1, 4:nrow(table2)),]

# Save output --
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(table2, paste0(output_dir, "/table2.csv"))
