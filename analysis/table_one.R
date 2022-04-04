## ###########################################################

##  This script:
## - Imports data of the three waves
## - Makes 'table 1' (description of demographics / comorbidities)

## linda.nab@thedatalab.com - 20220304
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(gtsummary)
library(gt)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

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
    config$demographics,
    config$comorbidities,
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
                      ethnicity ~ "Ethnicity",
                      smoking_status_comb ~ "Smoking status",
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

# number of deaths in waves
n_deaths <- map(.x = data_processed,
                .f = ~ .x %>% 
                       filter(died_ons_covid_flag_any == TRUE) %>%
                       nrow())
## Change labels in table
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
