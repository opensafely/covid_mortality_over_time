## ###########################################################

##  This script:
## - Contains a general function that is used to extract data to create table 1

## linda.nab@thedatalab.com - 20220328
## ###########################################################

# Load libraries & functions ---
library(readr)
library(here)

# Function ---
## Extracts data and maps columns to the correct format (integer, factor etc)
## args:
## - file_name: string with the location of the input file extracted by the 
##   cohortextracter
## output:
## data.frame of the input file, with columns of the correct type
extract_data <- function(file_name) {
  data_extracted <-
    read_csv(
      file = file_name,
      col_types = cols_only(
        # only read the columns defined here
        patient_id = col_integer(),
        
        # demographics
        agegroup = col_character(),
        sex = col_character(),
        bmi = col_character(),
        smoking_status = col_character(),
        imd = col_character(),
        region = col_character(),
        
        # comorbidities
        hypertension = col_logical(),
        chronic_respiratory_disease = col_logical(),
        asthma = col_character(),
        chronic_cardiac_disease = col_logical(),
        diabetes_controlled = col_character(),
        cancer = col_logical(),
        haem_cancer = col_logical(),
        dialysis_kidney_transplant = col_character(),
        ckd = col_character(),
        chronic_liver_disease = col_logical(),
        stroke = col_logical(),
        dementia = col_logical(),
        other_neuro = col_logical(),
        organ_kidney_transplant = col_character(),
        asplenia = col_logical(),
        ra_sle_psoriasis = col_logical(),
        immunosuppression = col_logical(),
        learning_disability = col_logical(),
        sev_mental_ill = col_logical(),
        
        # outcome
        died_ons_covid_flag_any = col_logical(),
      )
    )
  data_extracted
}
