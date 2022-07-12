## ###########################################################

##  This script:
## - Contains a general function that is used to extract data to create table 1

## linda.nab@thedatalab.com - 20220328
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(here)
library(lubridate)
library(jsonlite)
library(readr)

# Function ---
## Extracts data and maps columns to the correct format (integer, factor etc)
## args:
## - file_name: string with the location of the input file extracted by the 
##   cohortextracter
## output:
## data.frame of the input file, with columns of the correct type
extract_data <- function(file_name) {
  ## read all data with default col_types 
  data_extracted <-
    read_csv(
      file_name,
      col_types = cols_only(
        patient_id = col_integer(),
        # demographics
        age = col_integer(),
        agegroup = col_character(),
        agegroup_std = col_character(),
        sex = col_character(),
        stp = col_character(),
        bmi_value = col_double(),
        bmi = col_character(),
        ethnicity = col_number(),
        smoking_status = col_character(),
        smoking_status_comb = col_character(),
        imd = col_number(),
        region = col_character(),
        # comorbidities (multilevel)
        asthma = col_number(),
        bp = col_number(),
        bp_ht = col_logical(),
        diabetes_controlled = col_number(),
        ## ckd/rrt
        ### dialysis or kidney transplant
        rrt_cat = col_number(),
        ### calc of egfr
        creatinine = col_number(), 
        creatinine_operator = col_character(),
        creatinine_age = col_number(),
        ## organ or kidney transplant
        organ_kidney_transplant = col_character(),
        # comorbidities (binary)
        hypertension = col_logical(),
        chronic_respiratory_disease = col_logical(),
        chronic_cardiac_disease = col_logical(),
        cancer = col_logical(),
        haem_cancer = col_logical(),
        chronic_liver_disease = col_logical(),
        stroke = col_logical(),
        dementia = col_logical(),
        other_neuro = col_logical(),
        asplenia = col_logical(),
        ra_sle_psoriasis = col_logical(),
        immunosuppression = col_logical(),
        learning_disability = col_logical(),
        sev_mental_ill = col_logical(),
        # vaccination dates
        covid_vax_date_1 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_2 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_3 = col_date(format = "%Y-%m-%d"),
        # outcomes
        died_ons_covid_any_date = col_date(format = "%Y-%m-%d"),
        died_any_date = col_date(format = "%Y-%m-%d")
      )
    )
  data_extracted
}
