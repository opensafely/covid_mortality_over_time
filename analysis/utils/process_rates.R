## ###########################################################

##  This script:
## - Imports the subgroup specific standardised rates
## - Changes levels of factor

## linda.nab@thedatalab.com - 20220329
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(lubridate)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

## Create vector containing the demographics and comorbidities
subgroups_vctr <- c(config$demographics, config$comorbidities)
# Import the standardised mortality rates:
subgroups_vctr <- c(config$demographics, config$comorbidities)
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  paste0(.x,"_monthly_std.csv")),
                      col_types = cols("D", "f", "f", "d")))
names(subgroups_rates_std) <- subgroups_vctr

subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] %>%
  
