## ###########################################################

##  This script:
## - Imports data of the cohort in april (20200401)
## - Makes 'table 1' (description of demographics / comorbidities)

## linda.nab@thedatalab.com - 20220304
## ###########################################################
## NOTE: THIS SCRIPT WILL EVENTUALLY BE CHANGED TO CAPTURE A TABLE 1 
## OF WAVE 1 / WAVE 2 / WAVE 3

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)
library(gtsummary)

# Import data cohort in April  ---
data <- 
  readRDS(file = here("output", 
                      "data_processed", 
                      "data_processed_2020-04-01.rds"))

table1 <-
  data %>%
  select(
    agegroup,
    sex,
    bmi,
    smoking_status,
    imd,
    region,
    hypertension,
    chronic_respiratory_disease,
    asthma,
    chronic_cardiac_disease,
    diabetes_controlled,
    cancer,
    haem_cancer,
    dialysis_kidney_transplant,
    ckd,
    chronic_liver_disease,
    stroke,
    dementia,
    other_neuro,
    organ_kidney_transplant,
    asplenia,
    ra_sle_psoriasis,
    immunosuppression,
    learning_disability,
    sev_mental_ill,
    died_ons_covid_flag_any
  ) %>%
  tbl_summary(
    by = died_ons_covid_flag_any,
    label = list(
        agegroup ~ "Age Group",
        sex ~ "Sex",
        bmi ~ "Body Mass Index",
        smoking_status ~ "Smoking status",
        imd ~ "IMD quintile",
        region ~ "Region",
        hypertension ~ "Hypertension",
        chronic_respiratory_disease ~ "Chronic respiratory disease",
        asthma ~ "Asthma",
        chronic_cardiac_disease ~ "Chronic cardiac disease",
        diabetes_controlled ~ "Diabetes",
        cancer ~ "Cancer (non haematological)",
        haem_cancer ~ "Haematological malignancy",
        dialysis_kidney_transplant ~ "Dialysis",
        ckd ~ "Chronic kidney disease",
        chronic_liver_disease ~ "Chronic liver disease",
        stroke ~ "Stroke",
        dementia ~ "Dementia",
        other_neuro ~ "Other neurological disease",
        organ_kidney_transplant ~ "Organ transplant",
        asplenia ~ "Asplenia",
        ra_sle_psoriasis ~ "Rheumatoid arthritis/ lupus/ psoriasis",
        immunosuppression ~ "Immunosuppressive condition",
        learning_disability ~ "Learning disability",
        sev_mental_ill ~ "Severe mental illness"
        )
  ) %>%
  add_overall() %>%
  modify_table_body(
    filter,
    !(variable == "bmi" & label == "Not obese") &
      !(variable == "asthma" &
          label == "No asthma") &
      !(variable == "diabetes_controlled" &
          label == "No diabetes") &
      !(variable == "dialysis_kidney_transplant" &
          label == "No dialysis") &
      !(variable == "ckd" &
          label == "No CKD") &
      !(variable == "organ_kidney_transplant" &
          label == "No transplant")
  ) %>%
  modify_column_hide(columns = stat_1) %>%
  modify_header(stat_2 = "**COVID-19 related deaths**")
# organ_kidney_transplant does not work (filtering, not sure why)
# Save output --
table1
table1$inputs