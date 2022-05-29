## ###########################################################

##  This script:
## - Creates a data.frame containing the reference values of the subgroups

## linda.nab@thedatalab.com - 20220330
## ###########################################################

# Load libraries & functions ---
library(here)
library(dplyr)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

# Create data.frame 'reference_values' ---
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c("agegroup", "sex", config$demographics, config$comorbidities)
reference_values <- 
  cbind(subgroup = subgroups_vctr, reference = NA) %>%
  as.data.frame()

reference_values <-
  reference_values %>%
  mutate(reference = case_when(
    subgroup == "agegroup" ~ "50-59",
    subgroup == "sex" ~ "F",
    subgroup == "bmi" ~ "Not obese",
    subgroup == "ethnicity" ~ "White",
    subgroup == "smoking_status_comb" ~ "Never and unknown", 
    subgroup == "imd" ~ "5 (least deprived)",
    subgroup == "region" ~ "London" ,
    subgroup %in% config$comorbidities[!config$comorbidities %in% 
                                         c("asthma", 
                                           "bp",
                                           "diabetes_controlled",
                                           "ckd_rrt",
                                           "organ_kidney_transplant")] ~ "0",
    subgroup == "asthma" ~ "No asthma",
    subgroup == "bp" ~ "Normal",
    subgroup == "diabetes_controlled" ~ "No diabetes",
    subgroup == "ckd_rrt" ~ "No CKD or RRT",
    subgroup == "organ_kidney_transplant" ~ "No transplant",
    TRUE ~ NA_character_)
  )
