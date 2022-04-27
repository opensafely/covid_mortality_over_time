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
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/extract_data.R")) # function extract_data()
source(paste0(utils_dir, "/process_data.R")) # function process_data()
# Load json config for dates of waves
config <- fromJSON(here("analysis", "config.json"))

# Load data ---
## Search input files by globbing
input_files <-
  Sys.glob(here("output", "joined", "input_wave*.csv.gz"))
## Extract data from the input_files and formats colums to correct type 
## (e.g., integer, logical etc)
data_extracted <-
  map(.x = input_files,
      .f = ~ extract_data(file_name = .x))
## Process data_extracted by using correct levels for each column of type factor
data_processed <- 
  map2(.x = data_extracted,
       .y = list(config$wave1, 
                 config$wave2,
                 config$wave3),
       .f = ~ process_data(data_extracted = .x,
                           waves_dates_list = .y))

## Name data.frames in list (used as file name when output is saved)
names(data_processed) <-
  c("wave1", "wave2", "wave3")
 
# Save output ---
output_dir <- here("output", "processed")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = data_processed,
     .f = ~ saveRDS(object = .x,
                    file = paste0(output_dir, "/input_", .y, ".rds"),
                    compress = TRUE))
