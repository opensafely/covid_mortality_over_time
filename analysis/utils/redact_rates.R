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
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Function that redacts counts smaller than five and sets value (mort rate) 
## equal to 0
## This function is used to redact the crude rates (number of deaths stratified
## by date; number of deaths stratified by sex and age and date)
redact_crude_rates <- function(crude_rates){
  crude_rates <- 
    crude_rates %>%
    mutate(
      died_ons_covid_flag_any = case_when(died_ons_covid_flag_any <= 5 ~ 0,
                                          TRUE ~ died_ons_covid_flag_any)
    ) %>%
    mutate(value = case_when(died_ons_covid_flag_any <= 5 ~ 0,
                             TRUE ~ value))
}
## Function that redacts counts smaller than five if number of deaths in 
## stratum of (date, sex, subgroup (e.g.: bmi)) summed over all age groups 
## is smaller than five.
redact_subgroup_rates <- function(subgroup_rates, subgroup){
  subgroup_rates %>%
    group_by_at(vars("sex", "date", !!subgroup)) %>%
    mutate(n_died_summed_over_age = sum(died_ons_covid_flag_any)) %>%
    mutate(died_ons_covid_flag_any = case_when(n_died_summed_over_age <= 5 ~ 0,
                                               TRUE ~ died_ons_covid_flag_any)) %>%
    mutate(value = case_when(n_died_summed_over_age <= 5 ~ 0,
                             TRUE ~ value)) %>%
    select(-n_died_summed_over_age)
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
# has one column less than the med cond file
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
# Make two lists
# the first list needs crude redaction (these rates will not be age standardised)
# the second list will be age standardised, so only when mortality in stratum 
# (date, sex, subgroup) [summed over age] is <= 5, all values in that stratum
# are redacted
rates_crude_redaction <- list(crude = crude_rates, age = age_sex_rates$age)
rates_subgroup_redaction <- c(sex = list(age_sex_rates$sex), subgroups_rates)

# Redact counts ---
rates_crude_redaction <-
  map(.x = rates_crude_redaction,
      .f = ~ redact_crude_rates(crude_rates = .x))
rates_subgroup_redaction <-
  imap(.x = rates_subgroup_redaction,
       .f = ~ redact_subgroup_rates(subgroup_rates = .x,
                                   subgroup = .y))

# Save output ---
ifelse(!dir.exists(here("output", "rates")), 
       dir.create(here("output", "rates")), FALSE)
output_dir <- here("output", "rates", "redacted")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = c(rates_crude_redaction, rates_subgroup_redaction),
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_redacted.csv")))
