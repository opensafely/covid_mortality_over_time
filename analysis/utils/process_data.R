## ###########################################################

##  This script:
## - Contains a general function that is used to process data that is extracted
##   for table 1

## linda.nab@thedatalab.com - 20220328
## ###########################################################

# Load libraries & functions ---
library(here)
library(dplyr)
# Function fct_case_when needed inside process_data
source(here("analysis", "utils", "fct_case_when.R"))

# Function ---
## Processes the extracted data in extract_data(): changes levels of factors in 
## data
## args:
## - data_extracted: a data.frame extracted by function extract_data() in 
##   ./analysis/utils/extract_data.R
## output:
## data.frame of data_extracted with factor columns with correct levels
process_data <- function(data_extracted, waves_dates_list) {
  data_processed <-
    data_extracted %>%
    mutate(
      agegroup = fct_case_when(
        agegroup == "50-59" ~ "50-59", # = reference
        agegroup == "18-39" ~ "18-39",
        agegroup == "40-49" ~ "40-49",
        agegroup == "60-69" ~ "60-69",
        agegroup == "70-79" ~ "70-79",
        agegroup == "80plus" ~ "80plus",
        TRUE ~ NA_character_
      ),
      # no missings should occur as individuals with
      # missing age are not included in the study
      
      sex = fct_case_when(sex == "F" ~ "Female",
                          sex == "M" ~ "Male",
                          TRUE ~ NA_character_),
      # no missings should occur as only of
      # individuals with a female/male sex, data is extracted
      
      bmi = fct_case_when(
        bmi == "Not obese" ~ "Not obese",
        bmi == "Obese I (30-34.9)" ~ "Obese I (30-34.9 kg/m2)",
        bmi == "Obese II (35-39.9)" ~ "Obese II (35-39.9 kg/m2)",
        bmi == "Obese III (40+)" ~ "Obese III (40+ kg/m2)",
        TRUE ~ NA_character_
      ),
      
      ethnicity = fct_case_when(
        ethnicity == 1 ~ "White",
        ethnicity == 2 ~ "Mixed",
        ethnicity == 3 ~ "South Asian",
        ethnicity == 4 ~ "Black",
        ethnicity == 5 ~ "Other",
        ethnicity == 0 ~ "Unknown",
        TRUE ~ NA_character_ # no missings in real data expected 
        # (all mapped into 0) but dummy data will have missings (data is joined
        # and patient ids are not necessarily the same in both cohorts)
      ),
      
      smoking_status_comb = fct_case_when(
        smoking_status_comb == "N + M" ~ "Never and unknown",
        smoking_status_comb == "E" ~ "Former",
        smoking_status_comb == "S" ~ "Current",
        TRUE ~ NA_character_
      ),
      
      imd = fct_case_when(
        imd == "1" ~ "1 (least)",
        imd == "2" ~ "2",
        imd == "3" ~ "3",
        imd == "4" ~ "4",
        imd == "5" ~ "5 (most)",
        imd == "0" ~ NA_character_
      ),
      
      region = fct_case_when(
        region == "North East" ~ "North East",
        region == "North West" ~ "North West",
        region == "Yorkshire and The Humber" ~ "Yorkshire and the Humber",
        region == "East Midlands" ~ "East Midlands",
        region == "West Midlands" ~ "West Midlands",
        region == "East" ~ "East of England",
        region == "London" ~ "London",
        region == "South East" ~ "South East",
        region == "South West" ~ "South West",
        TRUE ~ NA_character_
      ),
      
      
      # comorbidities
      asthma = fct_case_when(
        asthma == "0" ~ "No asthma",
        asthma == "1" ~ "With no oral steroid use",
        asthma == "2" ~ "With oral steroid use"
      ),
      
      bp = fct_case_when(
        bp == "1" ~ "Normal",
        bp == "2" ~ "Elevated/High",
        bp == "0" ~ "Unknown"
      ),
      
      diabetes_controlled = fct_case_when(
        diabetes_controlled == "0" ~ "No diabetes",
        diabetes_controlled == "1" ~ "Controlled",
        diabetes_controlled == "2" ~ "Not controlled",
        diabetes_controlled == "3" ~ "Without recent Hb1ac measure"
      ),
      
      dialysis_kidney_transplant = fct_case_when(
        dialysis_kidney_transplant == "0" ~ "No dialysis",
        dialysis_kidney_transplant == "1" ~ "With previous kidney transplant",
        dialysis_kidney_transplant == "2" ~ "Without previous kidney transplant"
      ),
      
      ckd = fct_case_when(
        ckd == "No CKD" ~ "No CKD",
        ckd == "0" ~ "Stage 0",
        ckd == "3a" ~ "Stage 3a",
        ckd == "3b" ~ "Stage 3b",
        ckd == "4" ~ "Stage 4",
        ckd == "5" ~ "Stage 5"
      ),
      
      organ_kidney_transplant = fct_case_when(
        organ_kidney_transplant == "No transplant" ~ "No transplant",
        organ_kidney_transplant == "Kidney" ~ "Kidney transplant",
        organ_kidney_transplant == "Organ" ~ "Other organ transplant"
      ), 
      
      died_ons_covid_flag_any = case_when(
        !is.na(died_ons_covid_any_date) ~ TRUE,
        TRUE ~ FALSE
      ),
      
      # died from covid (1); died from other cause (2); 
      # alive at the end of study (0)
      status = fct_case_when(
        !is.na(died_ons_covid_any_date) ~ "1",
        # died from other cause
        (is.na(died_ons_covid_any_date) &
           !is.na(died_any_date)) ~ "2",
        TRUE ~ "0"
      )
    ) %>%
    # add variable 'fu', follow up time for status == 1 and status == 0 and
    # fu is end_date - start_date of wave if no event occured (administrative
    # censoring)
    mutate(
      fu = case_when(
        status == "1" ~
          difftime(
            died_ons_covid_any_date,
            waves_dates_list$start_date,
            tz = "UTC"
          ),
        status == "2" ~
          difftime(
            died_any_date,
            waves_dates_list$start_date,
            tz = "UTC"),
        TRUE ~
          difftime(
            waves_dates_list$end_date,
            waves_dates_list$start_date,
            tz = "UTC")
      ))
  data_processed
}
