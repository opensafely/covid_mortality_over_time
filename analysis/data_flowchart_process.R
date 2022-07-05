## ###########################################################

##  This script:
## - Processed the flowchart data and saves in output/processed/input_flowchart.rds

## linda.nab@thedatalab.com - 20220705
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)
data <- read_csv(here("output", "input_flowchart.csv.gz"),
                 col_types = cols_only(
                   patient_id = col_integer(),
                   has_follow_up = col_logical(),
                   age = col_integer(),
                   sex = col_character(),
                   stp = col_character(),
                   index_of_multiple_deprivation = col_integer()
                 ))

# Save output ---
output_dir <- here("output", "processed")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
saveRDS(object = data,
        file = paste0(output_dir, "/input_flowchart.rds"),
        compress = TRUE)
