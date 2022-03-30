## ###########################################################

##  This script:
## - Imports the subgroup specific standardised rates
## - Changes levels of factor

## linda.nab@thedatalab.com - 20220329
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(lubridate)
library(jsonlite)
## Load function fct_case_when() to be used to change level of factors
source(here("analysis", "utils", "fct_case_when.R")) 
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

# Load rates ---
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c(config$demographics, config$comorbidities)
# Import the standardised mortality rates:
subgroups_vctr <- c(config$demographics, config$comorbidities)
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  paste0(.x,"_monthly_std.csv")),
                      col_types = cols("D", "f", "f", "d")))
names(subgroups_rates_std) <- subgroups_vctr

# Change levels of factors (demographics + comorbidities) ---
## BMI
subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] %>%
  mutate(bmi = fct_case_when(
    bmi == "Not obese" ~ "Not obese",
    bmi == "Obese I (30-34.9)" ~ "Obese I (30-34.9 kg/m2)",
    bmi == "Obese II (35-39.9)" ~ "Obese II (35-39.9 kg/m2)",
    bmi == "Obese III (40+)" ~ "Obese III (40+ kg/m2)",
    TRUE ~ NA_character_
  ))
## Ethnicity
subgroups_rates_std[[which(names(subgroups_rates_std) == "ethnicity")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "ethnicity")]] %>%
  mutate(ethnicity = fct_case_when(
    ethnicity == 1 ~ "White - British",
    ethnicity == 2 ~ "White - Irish",
    ethnicity == 3 ~ "White - Any other White background",
    ethnicity == 4 ~ "Mixed - White and Black Caribbean",
    ethnicity == 5 ~ "Other",
    ethnicity == 6 ~ "Unknown",
    TRUE ~ NA_character_
  ))
## Smoking_status
subgroups_rates_std[[which(names(subgroups_rates_std) == "smoking_status_comb")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "smoking_status_comb")]] %>%
  mutate(smoking_status_comb = fct_case_when(
    smoking_status_comb == "E" ~ "Former",
    smoking_status_comb == "S" ~ "Current",
    smoking_status_comb == "N + M" ~ "Never and unknown",
    TRUE ~ NA_character_
  ))
# IMD
subgroups_rates_std[[which(names(subgroups_rates_std) == "imd")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "imd")]] %>%
  mutate(imd = fct_case_when(
    imd == "1" ~ "1 (least)",
    imd == "2" ~ "2",
    imd == "3" ~ "3",
    imd == "4" ~ "4",
    imd == "5" ~ "5 (most)",
    imd == "0" ~ NA_character_
  ))
# comorbidities
subgroups_rates_std[[which(names(subgroups_rates_std) == "asthma")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "asthma")]] %>%
  mutate(asthma = fct_case_when(
    asthma == "0.0" ~ "No asthma",
    asthma == "1.0" ~ "With no oral steroid use",
    asthma == "2.0" ~ "With oral steroid use"
  ))
subgroups_rates_std[[which(names(subgroups_rates_std) == "diabetes_controlled")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "diabetes_controlled")]] %>%
  mutate(diabetes_controlled = fct_case_when(
    diabetes_controlled == "0.0" ~ "No diabetes",
    diabetes_controlled == "1.0" ~ "Controlled",
    diabetes_controlled == "2.0" ~ "Not controlled",
    diabetes_controlled == "3.0" ~ "Without recent Hb1ac measure"
  ))
subgroups_rates_std[[which(names(subgroups_rates_std) == "dialysis_kidney_transplant")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "dialysis_kidney_transplant")]] %>%
  mutate(dialysis_kidney_transplant = fct_case_when(
    dialysis_kidney_transplant == "0.0" ~ "No dialysis",
    dialysis_kidney_transplant == "1.0" ~ "With previous kidney transplant",
    dialysis_kidney_transplant == "2.0" ~ "Without previous kidney transplant"
  ))
subgroups_rates_std[[which(names(subgroups_rates_std) == "ckd")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "ckd")]] %>%
  mutate(ckd = fct_case_when(
    ckd == "No CKD" ~ "No CKD",
    ckd == "0" ~ "Stage 0",
    ckd == "3a" ~ "Stage 3a",
    ckd == "3b" ~ "Stage 3b",
    ckd == "4" ~ "Stage 4",
    ckd == "5" ~ "Stage 5"
  ))
subgroups_rates_std[[which(names(subgroups_rates_std) == "organ_kidney_transplant")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "organ_kidney_transplant")]] %>%
  mutate(organ_kidney_transplant = fct_case_when(
    organ_kidney_transplant == "No transplant" ~ "No transplant",
    organ_kidney_transplant == "Kidney" ~ "Kidney transplant",
    organ_kidney_transplant == "Organ" ~ "Other organ transplant"
  ))
# Create data.frame mapping reference levels of vars ---
reference_values <- 
  cbind(subgroup = subgroups_vctr, reference = NA) %>%
  as.data.frame()

# Save output ---
output_dir <- here("output", "rates")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = subgroups_rates_std,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_monthly_std.csv")))
