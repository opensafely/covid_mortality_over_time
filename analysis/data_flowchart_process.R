## ###########################################################

##  This script:
## - Processed the flowchart data and saves in output/processed/input_flowchart.rds

## linda.nab@thedatalab.com - 20220705
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)
library(purrr)
library(fs)
input_files <-
  Sys.glob(here("output", "input_flowchart*.csv.gz"))

data <- 
  map(.x = input_files,
      .f = ~ read_csv(.x, 
               col_types = cols_only(
                 patient_id = col_integer(),
                 has_follow_up = col_logical(),
                 age = col_integer(),
                 sex = col_character(),
                 stp = col_character(),
                 index_of_multiple_deprivation = col_integer())))
names(data) <- c("wave1", "wave2", "wave3", "wave4", "wave5")

# Save output ---
output_dir <- here("output", "processed")
dir_create(output_dir)
iwalk(.x = data,
      .f = ~ saveRDS(object = .x,
                     file = path(output_dir, paste0("input_flowchart_", 
                                                   .y, 
                                                   ".rds")),
                     compress = TRUE))
