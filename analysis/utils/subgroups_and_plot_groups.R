## ###########################################################

##  This script:
## - Creates a data.frame containing the 'plot_group' for data viz

## linda.nab@thedatalab.com - 20220609
## ###########################################################

# Load libraries & functions ---
library(here)
library(dplyr)
library(jsonlite)

## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c("agegroup", "sex", config$demographics, config$comorbidities)

# Create data.frame 'subgroups_and_plot_groups' ---
## Create vector containing the demographics and comorbidities
subgroups_and_plot_groups <- 
  cbind.data.frame(subgroup = subgroups_vctr, plot_group = NA_character_)
subgroups_and_plot_groups <- 
  subgroups_and_plot_groups %>%
  filter(subgroup != "region") %>% # region not included as cox models are 
  # stratifed by region
  mutate(plot_group = case_when(subgroup == "agegroup" ~ "Age",
                                subgroup == "sex" ~ "Sex",
                                subgroup == "ethnicity" ~ "Ethnicity",
                                subgroup == "imd" ~ "IMD",
                                subgroup == "bmi" ~ "BMI",
                                subgroup == "smoking_status_comb" ~ "SMK",
                                subgroup == "bp" ~ "BP",
                                subgroup == "asthma" ~ "Asthma",
                                subgroup == "diabetes_controlled" ~ "Diabetes",
                                subgroup == "ckd_rrt" ~ "CKD/RRT",
                                subgroup == "organ_kidney_transplant" ~ "Tx",
                                TRUE ~ "Clinical risk group (other)"))