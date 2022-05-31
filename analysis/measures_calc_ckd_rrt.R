## ###########################################################

##  This script:
## - Generates file './output/joined/measure_ckd_rrt_mortality_rate.csv

## linda.nab@thedatalab.com - 20220529
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(here)
library(lubridate)
library(jsonlite)
library(readr)
library(purrr)
source(here("analysis", "utils", "add_kidney_vars_to_data.R"))
# Load json config for range of dates
config <- fromJSON(here("analysis", "config.json"))
date_range <- 
  seq(ymd(config$dates$start_date), ymd(config$dates$end_date), by = "1 month")
## Function
## Extracts data and maps columns to the correct format (integer, factor etc)
## args:
## - file_name: string with the location of the input file extracted by the 
##   cohortextracter
## output:
## data.frame of the input file, with columns of the correct type
## only the columns needed for the calculation of the kidney vars are extracted
extract_data <- function(file_name) {
  data_extracted <-
    read_csv(
      file_name,
      col_types = cols_only(
        patient_id = col_integer(),
        # demographics
        age = col_integer(),
        agegroup_std = col_character(),
        sex = col_character(),
        ## ckd/rrt
        ### dialysis or kidney transplant
        rrt_cat = col_number(),
        ### calc of egfr
        creatinine = col_number(), 
        creatinine_operator = col_character(),
        creatinine_age = col_number(),
        # outcomes
        died_ons_covid_flag_any = col_logical())
      )
  data_extracted
}

# Load data ---
## Search input files by globbing
input_files <-
  Sys.glob(here("output", "joined", "input_20*.csv.gz"))
## Extract data from the input_files and formats columns to correct type 
## (e.g., integer, logical etc)
data <-
  map(.x = input_files,
      .f = ~ extract_data(file_name = .x))
names(data) <- date_range # used as .y in imap to add date to data.frames

# Calc mortality rates --
## Add Kidney columns to data (egfr and ckd_rrt)
data <- 
  map(.x = data,
      .f = ~ add_kidney_vars_to_data(data_extracted = .x))
## Add column 'date' 
data <- 
  imap(.x = data,
       .f = ~ .x %>% mutate(date = ymd(.y)))
## Make measure file, identical to output from measures framework
measure <- 
  map(.x = data,
      .f = ~ .x %>% 
        group_by(agegroup_std, sex, ckd_rrt, date) %>%
        summarise(died_ons_covid_flag_any = sum(died_ons_covid_flag_any), 
                  population = n(),
                  .groups = "keep") %>%
        mutate(value = died_ons_covid_flag_any / population)) %>%
  bind_rows() %>%
  relocate(date, .after = last_col())

# Save output ---
output_dir <- here("output", "joined")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(x = measure,
          path = paste0(output_dir, "/measure_ckd_rrt_mortality_rate.csv"))
