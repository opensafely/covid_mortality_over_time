## ###########################################################

##  This script:
## - Imports the monthly cohorts extracted from the cohort extractor
## - Imports the ethnicity data extracted from the cohort extractor
## - Joins each monthly cohort with the ethnicity data

## linda.nab@thedatalab.com - 2022024
## ###########################################################

# Load libraries & functions ---
library(here)
library(lubridate)
library(dplyr)
library(purrr)
library(readr)
### Load the function (create_seq_dates()) that returns a vector with a 
### sequence of dates that is equal to the dates used in project.yaml to create 
### the monthly cohorts
source(here("analysis", "config.R"))

# Import data ---
## COMPOSE FILE NAMES FOR THE MONTHLY COHORTS
### Monthly cohorts are extracted as defined in study_definition.py
### Argument --index-date-range "2020-02-01 to 2021-12-01 by month"
### in project.yaml is used to extract 21 monthly cohorts
### these data extracts are saved in ./output/input_*.csv (* = month).
### Make a vector with the sequence of starting dates of the monthly cohorts:
seq_dates <- create_seq_dates()
### Make a vector containing the file names of the data: 
input_file_names <- paste0("input_", seq_dates, ".csv.gz")
## READ FILES
### Read cohort data:
data <- 
  map(.x = here("output", input_file_names), 
      .f = ~ read_csv(file = .x))
### Name list using the input_file_names, which will be used to save the files
### later on:
names(data) <- input_file_names 
### Read ethnicity data:
data_ethnicity <- 
  read_csv(file = here("output", "input_ethnicity.csv.gz"))

# Work horse ---
## JOIN DATA
data_joined <- 
  map(.x = data, 
      .f = ~ left_join(.x, y = data_ethnicity, by = "patient_id"))

# Save output ---
walk2(.x = data_joined,
      .y = names(data_joined), # used to save files
      .f = ~ write_csv(.x, path = here("output", .y)))