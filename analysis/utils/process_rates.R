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
## Load function fct_case_when() to be used to change level of factors
source(here("analysis", "utils", "fct_case_when.R")) 
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

# Load rates ---
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

# Change levels of factors (demographics + comorbidities) ---
subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] <-
  subgroups_rates_std[[which(names(subgroups_rates_std) == "bmi")]] %>%
  mutate(bmi = fct_case_when(
    bmi == "Not obese" ~ "Not"
  ))

# Create data.frame mapping reference levels of vars ---
reference_values <- 
  cbind(subgroup = subgroups_vctr, reference = NA) %>%
  as.data.frame()

reference_values <-
  reference_values %>%
  mutate(reference = case_when(
    subgroup == "bmi" ~ "Not obese",
    subgroup == "ethnicity" ~ ""
    TRUE ~ ""
  ))

