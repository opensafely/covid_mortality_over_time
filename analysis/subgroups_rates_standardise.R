## ###########################################################

##  This script:
## - Imports the subgroup specific mortality rates calculated by the Measures framework
## - Standardises the rates to the European Standard Population
## - Standardises the rates to 30 days per month and per 100.000 individuals

## linda.nab@thedatalab.com - 20220303
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
## demographic sex is added here, as it's a bit 'special' since all rates are
## grouped by sex *and* another subgroup variable, and sex is sex and the other
## subgroup variable in one. But, code works fine even if the imported data
## is grouped by sex twice (line 71, as for sex, eval(.y) = sex). Hence, 
## sex is added to the subgroups_vctr
subgroups_vctr <- c("sex", config$demographics, config$comorbidities)
subgroups_rates <- 
  map(.x = here("output", 
                "joined",
                paste0("measure_", subgroups_vctr,"_mortality_rate.csv")),
      .f = ~ read_csv(file = .x))
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
## The expected deaths is equal to crude rate (value) * EuropeanStandardPopulation, 
## to calculate the Direct Standardised Mortality Rate, you sum over all age 
## categories per sex (+ second var e.g. bmi) and divide by the total number 
## in the ESP (= 84000). In the above, value_weighted is the expected number 
## of deaths in a specific (sex, agegroup) strata of the pop, already divided by
## total number in the ESP --> summing over the age groups will then result in 
## the Direct Standardised Mortality Rate as x1/y + ... + xk/y=(x1 + .. + xk)/y.
## Here -->
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