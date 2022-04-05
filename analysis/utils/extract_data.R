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
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
comorbidities_multilevel_vctr <- c("asthma",
                                   "diabetes_controlled",
                                   "dialysis_kidney_transplant",
                                   "ckd",
                                   "organ_kidney_transplant")
comorbidities_binary_vctr <-
  config$comorbidities[!config$comorbidities %in% comorbidities_multilevel_vctr]

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
    read_csv(file_name)
  ## select only columns needed and map to correct col type
  data_extracted <- 
    data_extracted %>%
    select(patient_id,
           # demographics 
           agegroup,
           sex,
           config$demographics,
           # comorbidities
           config$comorbidities,
           # outcome
           died_ons_covid_flag_any,
           died_ons_covid_flag_any_date) %>%
    mutate(patient_id = as.integer(patient_id),
           across(c(agegroup, sex, config$demographics), as.character),
           across(all_of(comorbidities_multilevel_vctr), as.character),
           across(all_of(comorbidities_binary_vctr), as.logical),
           died_ons_covid_flag_any = as.logical(died_ons_covid_flag_any),
           died_ons_covid_flag_any_date = as_date(died_ons_covid_flag_any_date))
  data_extracted
}
