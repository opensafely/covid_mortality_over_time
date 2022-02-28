## ###########################################################

##  This script:
## - Imports the crude mortality rates calculated by the Measures framework
## - Standardises the rates to 30 days per month and per 100.000 individuals

## linda.nab@thedatalab.com - 2022028
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(lubridate)
library(dplyr)
### Load the function (create_seq_dates()) that returns a vector with a 
### sequence of dates that is equal to the dates used in project.yaml to create 
### the monthly cohorts
source(here("analysis", "config.R"))

# Import rates ---
crude_rates <- 
  read_csv(here("output", "measure_crude_mortality_rate.csv"))

# Standardise rates ---
## STANDARDISE RATES TO 30 DAYS PM AND PER 100.000 INDIVIDUALS
### Make a vector with the sequence of starting dates of the monthly cohorts:
seq_dates <- create_seq_dates()
### Make a vector containing the number of days in each cohort month:
number_of_days_in_months <- days_in_month(seq_dates)
### Standardise rates
crude_rates <-
  crude_rates %>%
  mutate(std_value = (value / number_of_days_in_months * 30) * 100000)

# Save output ---
output_dir <- here("output", "rates")
ifelse(!dir.exists(output_dir), dir.create(output_dir))
write_csv(crude_rates, 
          path = paste0(output_dir, "/crude_monthly_std.csv"))