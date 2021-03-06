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
      
      agegroup_std = fct_case_when(
        agegroup_std == "15-19 years" ~ "15-19 years",
        agegroup_std == "20-24 years" ~ "20-24 years",
        agegroup_std == "25-29 years" ~ "25-29 years",
        agegroup_std == "30-34 years" ~ "30-34 years",
        agegroup_std == "35-39 years" ~ "35-39 years",
        agegroup_std == "40-44 years" ~ "40-44 years",
        agegroup_std == "45-49 years" ~ "45-49 years",
        agegroup_std == "50-54 years" ~ "50-54 years",
        agegroup_std == "55-59 years" ~ "55-59 years",
        agegroup_std == "60-64 years" ~ "60-64 years",
        agegroup_std == "65-69 years" ~ "65-69 years",
        agegroup_std == "70-74 years" ~ "70-74 years",
        agegroup_std == "75-79 years" ~ "75-79 years",
        agegroup_std == "80-84 years" ~ "80-84 years",
        agegroup_std == "85-89 years" ~ "85-89 years",
        agegroup_std == "90plus years" ~ "90plus years",
        TRUE ~ NA_character_
      ),
      
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
        ethnicity == "1" ~ "White",
        ethnicity == "2" ~ "Mixed",
        ethnicity == "3" ~ "South Asian",
        ethnicity == "4" ~ "Black",
        ethnicity == "5" ~ "Other",
        ethnicity == "0" ~ "Unknown",
        TRUE ~ NA_character_ # no missings in real data expected 
        # (all mapped into 0) but dummy data will have missings (data is joined
        # and patient ids are not necessarily the same in both cohorts)
      ),
      
      smoking_status = fct_case_when(
        smoking_status == "M" ~ "Missing",
        smoking_status == "N" ~ "Never",
        smoking_status == "E" ~ "Former",
        smoking_status == "S" ~ "Current",
        TRUE ~ NA_character_
      ),
      
      smoking_status_comb = fct_case_when(
        smoking_status_comb == "N + M" ~ "Never and unknown",
        smoking_status_comb == "E" ~ "Former",
        smoking_status_comb == "S" ~ "Current",
        TRUE ~ NA_character_
      ),
      
      imd = fct_case_when(
        imd == "5" ~ "5 (least deprived)",
        imd == "4" ~ "4",
        imd == "3" ~ "3",
        imd == "2" ~ "2",
        imd == "1" ~ "1 (most deprived)",
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
      
      ckd_rrt = fct_case_when(
        ckd_rrt == "No CKD or RRT" ~ "No CKD or RRT",
        ckd_rrt == "Stage 3a" ~ "CKD stage 3a",
        ckd_rrt == "Stage 3b" ~ "CKD stage 3b",
        ckd_rrt == "Stage 4" ~ "CKD stage 4",
        ckd_rrt == "Stage 5" ~ "CKD stage 5",
        ckd_rrt == "RRT (dialysis)" ~ "RRT (dialysis)",
        ckd_rrt == "RRT (transplant)" ~ "RRT (transplant)"
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
            tz = "UTC",
            units = "days"
          ),
        status == "2" ~
          difftime(
            died_any_date,
            waves_dates_list$start_date,
            tz = "UTC",
            units = "days"),
        TRUE ~
          difftime(
            waves_dates_list$end_date,
            waves_dates_list$start_date,
            tz = "UTC",
            units = "days")
      ))
  data_processed
}
