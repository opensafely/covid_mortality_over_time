## ###########################################################

##  This script:
## - Imports the mortality rates (outputted by the measures framework)
## - Redacts low numbers

## linda.nab@thedatalab.com - 20220524
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
## Function that redacts counts smaller than five and sets value equal to 0
redact_file <- function(file){
  file <- 
    file %>%
    mutate(
      died_ons_covid_flag_any = case_when(died_ons_covid_flag_any <= 5 ~ 0,
                                          TRUE ~ died_ons_covid_flag_any)
    ) %>%
    mutate(value = case_when(died_ons_covid_flag_any <= 5 ~ 0,
                             TRUE ~ value))
}

# Load rates ---
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c(config$demographics, config$comorbidities)
# Import the crude mortality rates:
# these are imported separately from the subgroups rates as the file 
# has one column less than the csv for age /sex
crude_rates <- 
  read_csv(file = here("output",
                       "joined",
                       "measure_crude_mortality_rate.csv"),
           col_types = cols("d", "d", "d", "D"))
# Import the mortality rates for age and sex:
# these are imported separately from the subgroups rates as the file 
# has one column less than the med cond
age_sex_rates <- 
  map(.x = c("age", "sex"),
      .f = ~ read_csv(file = here("output", 
                                  "joined",
                                  paste0("measure_", .x,"_mortality_rate.csv")),
                      col_types = cols("f", "f", "d", "d", "d", "D")))
names(age_sex_rates) <- c("age", "sex")
# Import the mortality rates of the subgroups:
subgroups_rates <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "joined",
                                  paste0("measure_", .x,"_mortality_rate.csv")),
                      col_types = cols("f", "f", "f", "d", "d", "d", "D")))
names(subgroups_rates) <- subgroups_vctr
# Make one big list
rates <- c(crude = list(crude_rates), age_sex_rates, subgroups_rates)

# Redact counts ---
rates <-
  map(.x = rates,
      .f = ~ redact_file(file = .x))

# Save output ---
ifelse(!dir.exists(here("output", "rates")), 
       dir.create(here("output", "rates")), FALSE)
output_dir <- here("output", "rates", "redacted")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = rates,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_redacted.csv")))
