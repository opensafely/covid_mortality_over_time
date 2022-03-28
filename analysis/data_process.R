## ###########################################################

##  This script:
##  - Imports data extracted from the cohort extractor
##  - Standardises variables

## linda.nab@thedatalab.com - 2022024
## ###########################################################

# Load libraries & custom functions ---
library(here)
library(dplyr)
library(readr)
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/extract_data.R"))
source(paste0(utils_dir, "/process_data.R"))

# Load data ---
input_files <-
  Sys.glob(here("output", "joined", "input_wave*.csv.gz"))
data_extracted <-
  map(.x = input_files,
      .f = ~ extract_data(file_name = .x))
data_processed <- 
  map(.x = data_extracted,
      .f = ~ process_data(data_extracted = .x))
names(data_processed) <-
  c("wave1", "wave2", "wave3")
 
# Save output ---
output_dir <- here("output", "processed")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = data_processed,
     .f = ~ saveRDS(object = .x,
                    file = paste0(output_dir, "/input_", .y, ".rds"),
                    compress = TRUE))

