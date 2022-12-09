## ###########################################################

##  This script:
## - Imports data of the five waves
## - Calculates % of people on each vax dose at start of the wave and at the end
##   of the wave

## linda.nab@thedatalab.com - 20221208
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(stringr)
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# source functions for calc of ir
source(here("analysis", "utils", "calc_ir.R"))

# Import data extracts of waves ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))

data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
# vector with waves
waves_vctr <- str_extract(input_files_processed, "wave[:digit:]")
names(data_processed) <- waves_vctr

# percentage of people on each dose at start of each wave
doses_start_waves_list <- 
  imap(.x = data_processed,
       .f = ~ .x %>%
         group_by(doses_no_start, .drop = FALSE) %>%
         tally(name = paste0("n_", .y)))
doses_end_waves_list <- 
  imap(.x = data_processed,
       .f = ~ .x %>%
         group_by(doses_no_end, .drop = FALSE) %>%
         tally(name = paste0("n_", .y)))

# merge all 
doses_start_waves <- 
  plyr::join_all(doses_start_waves_list, by = "doses_no_start")
doses_end_waves <- 
  plyr::join_all(doses_end_waves_list, by = "doses_no_end")

# Save output --
## saved as '/output/tables/wave*ir.csv
output_dir <- here("output", "tables", "vax")
fs::dir_create(here("output", "tables"))
fs::dir_create(output_dir)
write_csv(doses_start_waves,
          fs::path(output_dir, "start_doses_waves.csv"))
write_csv(doses_end_waves,
          fs::path(output_dir, "end_doses_waves.csv"))
