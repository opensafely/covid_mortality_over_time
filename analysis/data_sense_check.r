## ###########################################################

##  This script:
## - Imports data of the cohort in april (20200401)
## - Sense checks the data

## linda.nab@thedatalab.com - 20220321
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)

# Import data cohort in April  ---
data <- 
  readRDS(file = here("output", 
                      "input_2020-04-01.rds"))

