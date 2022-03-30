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

# Import data ---
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

comorbs_rates_std <- 
  subgroups_rates_std[names(subgroups_rates_std) %in% 
                      config$comorbidities]
comorbs_rates_std[names(comorbs_rates_std) == "organ_kidney_transplant"]$organ_kidney_transplant <-
  comorbs_rates_std[names(comorbs_rates_std) == "organ_kidney_transplant"]$organ_kidney_transplant %>%
  mutate(
    organ_kidney_transplant =
      case_when(
        organ_kidney_transplant == "No transplant" ~ 0,
        TRUE ~ organ_kidney_transplant
      )
  )
## I think i may have to change all factors to correct levels and have a vector
## with the reference for every demographic/comorbidity, which is then used
## to determine the denominator 

comorbs_ratios <- 
  imap(.x = comorbs_rates_std,
       .f = ~ .x %>% 
              spread(!!.y, value_std, sep = "") %>% 
              mutate(across(starts_with(!!.y), 
                ~ . / get(!!paste0(.y,0)))) ) %>% 
              select(date, sex, !(ends_with("0") | ends_with("NA")))


comorbs_rates_std[[5]] %>%
  spread(names(comorbs_rates_std)[5], value_std, sep = "") %>% 
  mutate(across(starts_with(names(comorbs_rates_std)[5]), 
                ~ . / get(!!paste0(names(comorbs_rates_std)[5],0)))) %>% 
  select(date, sex, !(ends_with("0") | ends_with("NA")))

comorbs_rates_std[[5]] %>%
  select(starts_with("diabetes"))

## European Standard population
esp <- 
  read_csv(file = here("input", "european_standard_pop.csv"),
           col_types = cols_only( # only read the columns defined here
             AgeGroup = col_factor(),
             Sex = col_factor(),
             EuropeanStandardPopulation = col_integer())) %>%
  filter(!(AgeGroup %in% c("0-4 years", "5-9 years", "10-14 years"))) # remove
# age groups that are not part of the study population (< 18 year old)
## Change levels of Sex to "M"/"F" io Male Female 
esp <- 
  esp %>%
  mutate(Sex = recode_factor(Sex, `Male` = "M", `Female` = "F"))
## Join mortality rates and European Standard Population
subgroups_rates <- 
  map(.x = subgroups_rates,
      .f= ~ left_join(.x, 
                      esp, 
                      by = c("agegroup_std" = "AgeGroup", "sex" = "Sex")))

# Workhorse ---
## Standard European Population used here does not contain 100000 people, as 
## 'young' age categories (first 3) are not included. 
## We therefore need to calculate number of people in the ESP for our use case:
n_esp_18_years_or_over <- 
  esp %>%
  group_by(Sex) %>%
  summarise(n = sum(EuropeanStandardPopulation), 
            .groups = "keep") %>%
  filter(Sex == "F") %>% 
  pull() # note that female and male population are equal, therefore, filter on 
# female (could have been male)
## Calculate for each age group, sex and category of the subgroups (as listed
## in subgroups_vctr) the weighted mortality rate by multiplying the mortality
## rate by the percentage of that age category in the European Standard 
## Population 
subgroups_rates <- 
  map(.x = subgroups_rates,
      .f = ~ mutate(.x, value_weighted = value * (EuropeanStandardPopulation / 
                                                    n_esp_18_years_or_over)))
## Sum over all age categories for a specific date, sex and subgroup, to get
## the age standardised mortality rate
## multiply by 100000 to calculate mortality rate per 100000 people
## divide by days in that month and multiply by 30 to month standardise rate
subgroups_rates_std <-
  map2(.x = subgroups_rates, 
       .y = subgroups_vctr,
       .f = ~ group_by(.x, across(.cols = c(date, sex, eval(.y)))) %>%
         summarise(.,
                   value_sum = sum(value_weighted, na.rm = TRUE) * 100000, 
                   .groups = "keep") %>%
         mutate(., days_in_month = days_in_month(date)) %>%
         mutate(., value_std = ((value_sum) / days_in_month) * 30) %>%
         select(date, sex, !!.y, value_std))

# Save output ---
output_dir <- here("output", "rates")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
walk2(.x = subgroups_rates_std,
      .y = subgroups_vctr,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_monthly_std.csv")))