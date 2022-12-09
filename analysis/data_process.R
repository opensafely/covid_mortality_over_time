## ###########################################################

##  This script:
##  - Imports data extracted from the cohort extractor (wave1, wave2, wave3)
##  - Formats column types and levels of factors in data
##  - Saves processed data in ./output/processed/input_wave*.rds

## linda.nab@thedatalab.com - 2022024
## ###########################################################

# Load libraries & custom functions ---
library(here)
library(dplyr)
library(readr)
library(purrr)
library(stringr)
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/extract_data.R")) # function extract_data()
source(paste0(utils_dir, "/add_kidney_vars_to_data.R")) # function add_kidney_vars_to_data()
source(paste0(utils_dir, "/process_data.R")) # function process_data()
# Load json config for dates of waves
config <- fromJSON(here("analysis", "config.json"))

# Load data ---
## Search input files by globbing
input_files <-
  Sys.glob(here("output", "joined", "input_wave*.csv.gz"))
# vector with waves
waves_vctr <- str_extract(input_files, "wave[:digit:]")
## Extract data from the input_files and formats columns to correct type 
## (e.g., integer, logical etc)
data_extracted <-
  map(.x = input_files,
      .f = ~ extract_data(file_name = .x))
## Add Kidney columns to data (egfr and ckd_rrt)
data_extracted_with_kidney_vars <- 
  map(.x = data_extracted,
      .f = ~ add_kidney_vars_to_data(data_extracted = .x))
## Process data_extracted by using correct levels for each column of type factor
data_processed <- 
  map2(.x = data_extracted_with_kidney_vars,
       .y = list(config$wave1, 
                 config$wave2,
                 config$wave3,
                 config$wave4,
                 config$wave5),
       .f = ~ process_data(data_extracted = .x,
                           waves_dates_list = .y))

## Name data.frames in list (used as file name when output is saved)
names(data_processed) <- waves_vctr
 
# Save output ---
output_dir <- here("output", "processed")
fs::dir_create(output_dir)
iwalk(.x = data_processed,
      .f = ~ saveRDS(object = .x,
                     file = paste0(output_dir, "/input_", .y, ".rds"),
                     compress = TRUE))
