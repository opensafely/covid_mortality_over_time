## ###########################################################

##  This script:
## - Contains a function that renames the subgroups to names
## visible in the manuscript

## linda.nab@thedatalab.com - 20220608
## ###########################################################

# Load libraries & functions ---
library(dplyr)

# Function ---
## Function 'rename_subgroups'
## Arguments:
## table: table with column 'subgroup' equal to subgroups in config.yaml
## output:
## table with column 'subgroup' that is renamed 
## (e.g., agegroup = Age Group etc.)
rename_subgroups <- function(table){
  table <- 
    table %>%
    mutate(
      subgroup = case_when(
      subgroup == "agegroup" ~ "Age Group",
      subgroup == "sex" ~ "Sex",
      subgroup == "bmi" ~ "Body Mass Index",
      subgroup == "ethnicity" ~ "Ethnicity",
      subgroup == "smoking_status_comb" ~ "Smoking status",
      subgroup == "region" ~ "Region",
      subgroup == "imd" ~ "IMD quintile",
      subgroup == "hypertension" ~ "Hypertension",
      subgroup == "chronic_respiratory_disease" ~ "Chronic respiratory disease",
      subgroup == "asthma" ~ "Asthma",
      subgroup == "bp" ~ "Blood pressure",
      subgroup == "bp_ht" ~ "High blood pressure or diagnosed hypertension",
      subgroup == "chronic_cardiac_disease" ~ "Chronic cardiac disease",
      subgroup == "diabetes_controlled" ~ "Diabetes",
      subgroup == "cancer" ~ "Cancer (non haematological)",
      subgroup == "haem_cancer" ~ "Haematological malignancy",
      subgroup == "ckd_rrt" ~ "Chronic kidney disease or renal replacement therapy",
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
}
