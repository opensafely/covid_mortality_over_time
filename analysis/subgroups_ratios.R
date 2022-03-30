## ###########################################################

##  This script:
## - Imports the subgroup specific standardised rates
## - Calculates the ratios of the standardised rates

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
## Load reference values for subgroups
source(here("analysis", "utils", "reference_values.R"))

# Import data ---
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c(config$demographics, config$comorbidities)
## Import the standardised mortality rates:
## Import mortality rates for sex:
sex_rates_std <- read_csv(file = here("output", 
                                      "rates",
                                      "sex_monthly_std.csv"),
                          col_types = cols("D", "f", "d"))
## Import the rest of the mortality rates
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  "processed",
                                  paste0(.x,"_monthly_std.csv")),
                      col_types = cols("D", "f", "f", "d")))
names(subgroups_rates_std) <- subgroups_vctr

# Calculate ratios ---
## Sex
sex_ratios <- 
  sex_rates_std %>%
  group_by(date) %>%
  mutate(ratio = value_std / 
           value_std[sex == reference_values %>%
                       filter(subgroup == "sex") %>%
                       pull(reference)]) %>%
  select(-value_std)
## Rest
subgroups_ratios <- 
  imap(.x = subgroups_rates_std,
       .f = ~ .x %>% 
         group_by(date, sex) %>%
         mutate(ratio = value_std / 
                  value_std[.y %>% get() == reference_values %>%
                              filter(subgroup == .y) %>%
                              pull(reference)]) %>%
         select(-value_std))

# Save output ---
output_dir <- here("output", "ratios")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
## Sex
write_csv(x = sex_ratios,
          path = paste0(output_dir, "/", "sex", ".csv"))
## Rest
iwalk(.x = subgroups_ratios,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, ".csv")))
