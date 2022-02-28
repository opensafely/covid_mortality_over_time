## ###########################################################

##  This script:
## - Imports the monthly cohorts extracted from the cohort extractor
## - Imports the ethnicity data extracted from the cohort extractor
## - Joins each monthly cohort with the ethnicity data

## linda.nab@thedatalab.com - 2022024
## ###########################################################

# Load libraries ---
library(here)
library(lubridate)
library(dplyr)
library(purrr)
library(readr)

# Import data ---
## COMPOSE FILE NAMES OF THE MONTHLY COHORTS
### Monthly cohorts are extracted defined in study_definition.py
### Argument --index-date-range "2020-02-01 to 2021-12-01 by month"
### in project.yaml is used to extract 21 monthly cohorts
### these data extracts are saved in ./output/input_*.csv (* = month).
start_date <- ymd("20200201")
end_date <- ymd("20211201")
### Calculate number of months between these two dates:
number_of_months <- interval(start_date, end_date) %/% months(1)
### Create a sequence of dates, starting with start_date:
months <- seq(start_date, by = "month", length.out = number_of_months)
### Add end_date to sequence:
months_including_end_date <- c(months, end_date)
### Make a vector consisting of the file names of the data: 
input_file_names <- paste0("input_", months_including_end_date, ".csv.gz")
## READ FILES
### Read cohort data:
data <- 
  map(.x = here("output", input_file_names), 
      .f = read_csv)
### Name list using the input_file_names, which will be used to save the files
### later on:
names(data) <- input_file_names 
### Read ethnicity data:
data_ethnicity <- 
  read_csv(here("output", "input_ethnicity.csv.gz"))

# Work horse ---
## JOIN DATA
data_joined <- 
  map(.x = data, 
      .f = ~ left_join(.x, y = data_ethnicity, by = "patient_id"))

# Save output ---
walk2(.x = data_joined,
      .y = names(data_joined), # used to save files
      .f = ~ write_csv(.x, here("output", .y)))