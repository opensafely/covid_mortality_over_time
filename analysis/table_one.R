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
library(purrr)
library(tidyverse)
library(gtsummary)
library(gt)

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))

data_waves <- 
  data_processed %>%
  bind_rows(.id = "wave") %>%
  mutate(wave = wave %>% as_factor())

table1 <- 
  data_waves %>%
  select(
    wave,
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
  tbl_strata(
    strata = wave,
    .tbl_fun = 
      ~ .x %>%
        tbl_summary(by = died_ons_covid_flag_any,
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
                    )) %>%
      add_overall(),
    .header = "**Wave {strata}**, N = {n}"
  )
table1
  
# number of deaths 
n_deaths <- map(.x = data_processed,
                .f = ~ .x %>% 
                       filter(died_ons_covid_flag_any == TRUE) %>%
                       nrow())

n_deaths_wave1 <- 
  wave1 %>% 
    filter(died_ons_covid_flag_any == TRUE) %>% 
    nrow()
n_deaths_wave2 <- 
  wave2 %>% 
  filter(died_ons_covid_flag_any == TRUE) %>% 
  nrow()
n_deaths_wave3 <- 
  wave3 %>% 
  filter(died_ons_covid_flag_any == TRUE) %>% 
  nrow()

table1 <- 
  table1 %>% 
  modify_table_body(
  filter,
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
  modify_column_hide(columns = c(stat_1_1, stat_1_2, stat_1_3)) %>%
  modify_header(stat_2_1 = paste0("**COVID-19 related deaths**, N = ", n_deaths[[1]]),
                stat_2_2 = paste0("**COVID-19 related deaths**, N = ", n_deaths[[2]]),
                stat_2_3 = paste0("**COVID-19 related deaths**, N = ", n_deaths[[3]]))

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
gtsave(table1 %>% as_gt(), paste0(output_dir, "/table1.html"))
