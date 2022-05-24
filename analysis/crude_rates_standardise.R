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

# Import rates ---
crude_rates <- 
  read_csv(file = here("output", "rates", "redacted", "crude_redacted.csv"))
crude_rates_per_agegroup <-
  read_csv(file = here("output", "rates", "redacted", "age_redacted.csv"))

# Standardise rates ---
## Add column containing number of days in every month
crude_rates <-
  crude_rates %>%
  mutate(days_in_month = days_in_month(date))
crude_rates_per_agegroup <-
  crude_rates_per_agegroup %>%
  mutate(days_in_month = days_in_month(date))
## Standardise monthly rates to 30 days per month and per 100.000 individuals
crude_rates <-
  crude_rates %>%
  mutate(std_value = (value / days_in_month * 30) * 100000) %>%
  select(date, std_value)
crude_rates_per_agegroup <-
  crude_rates_per_agegroup %>%
  mutate(std_value = (value / days_in_month * 30) * 100000) %>%
  select(date, sex, agegroup, std_value)

# Save output ---
ifelse(!dir.exists(here("output", "rates")), dir.create(output_dir), FALSE)
output_dir <- here("output", "rates", "standardised")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(x = crude_rates, 
          path = paste0(output_dir, "/crude_std.csv"))
write_csv(x = crude_rates_per_agegroup, 
          path = paste0(output_dir, "/crude_per_agegroup_std.csv"))
