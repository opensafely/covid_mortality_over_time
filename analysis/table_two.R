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
# multilevel comorbidities get a reference in table two
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
# needed to add reference values to table two
source(here("analysis", "utils", "reference_values.R"))

# Import data extracts of waves ---
input_files_effect_estimates <-
  Sys.glob(here("output", "tables", "wave*_effect_estimates.csv"))
effect_estimates_list <- 
  map(.x = input_files_effect_estimates,
      .f = ~ read_csv(.x,
                      col_types = c("c", "c", "d", "d", "d")))
names(effect_estimates_list) <- waves_vctr

# Make reference_table_two ---
# Needed to add reference values to table two
reference_table_two <- 
  reference_values %>%
  filter(subgroup %in% c(config$demographics[config$demographics != "region"], 
                         comorbidities_multilevel_vctr)) %>%
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
                             reference_table_two){
  effect_estimates <- 
    effect_estimates %>% 
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
  effect_estimates
}

# Mutate table with effect_estimates to one with three columns and with 
# reference values using function 'mutate_table_two' (see output of function
# for names of the three columns)
effect_estimates_list <-
  map(.x = effect_estimates_list,
      .f = ~ mutate_table_two(.x, subgroups_vctr, reference_table_two))

# Create table two ---
# Join three waves to one table
table2 <-
  effect_estimates_list$wave1 %>%
  left_join(effect_estimates_list$wave2,
            by = c("subgroup", "level"),
            suffix = c(".1", ".2")) %>%
  left_join(effect_estimates_list$wave3,
            by = c("subgroup", "level"))
# Add suffix to last column
colnames(table2)[5] <- paste0(colnames(table2)[5], ".3") 
table2 <- 
  table2 %>%
  mutate(subgroup = case_when(
      #agegroup ~ "Age Group",
      #sex ~ "Sex",
      subgroup == "bmi" ~ "Body Mass Index",
      subgroup == "ethnicity" ~ "Ethnicity",
      subgroup == "smoking_status_comb" ~ "Smoking status",
      subgroup == "imd" ~ "IMD quintile",
      subgroup == "hypertension" ~ "Hypertension",
      subgroup == "chronic_respiratory_disease" ~ "Chronic respiratory disease",
      subgroup == "asthma" ~ "Asthma",
      subgroup == "bp" ~ "Blood pressure",
      subgroup == "chronic_cardiac_disease" ~ "Chronic cardiac disease",
      subgroup == "diabetes_controlled" ~ "Diabetes",
      subgroup == "cancer" ~ "Cancer (non haematological)",
      subgroup == "haem_cancer" ~ "Haematological malignancy",
      subgroup == "dialysis_kidney_transplant" ~ "Dialysis",
      subgroup == "ckd" ~ "Chronic kidney disease",
      subgroup == "chronic_liver_disease" ~ "Chronic liver disease",
      subgroup == "stroke" ~ "Stroke",
      subgroup == "dementia" ~ "Dementia",
      subgroup == "other_neuro" ~ "Other neurological disease",
      subgroup == "organ_kidney_transplant" ~ "Organ transplant",
      subgroup == "asplenia" ~ "Asplenia",
      subgroup == "ra_sle_psoriasis" ~ "Rheumatoid arthritis/ lupus/ psoriasis",
      subgroup == "immunosuppression" ~ "Immunosuppressive condition",
      subgroup == "learning_disability" ~ "Learning disability",
      subgroup == "sev_mental_ill" ~ "Severe mental illness"
    )
  )
# modify table (rename columns and add spanner)
table2 <-
  table2 %>%
  gt() %>%
  cols_label(
    subgroup = "Characteristic",
    level = "Category",
    HR_95CI.1 = "Wave 1",
    HR_95CI.2 = "Wave 2",
    HR_95CI.3 = "Wave 3"
  ) %>%
  tab_spanner(label = "COVID-19 Death HR (95% CI) (adjusted for age and sex)",
              columns = c(HR_95CI.1, HR_95CI.2, HR_95CI.3))

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
gtsave(table2, paste0(output_dir, "/table2.html"))

