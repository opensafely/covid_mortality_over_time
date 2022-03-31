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
## Load functions calc_dsr_i() and calc_var_dsr_i()
source(here("analysis", "utils", "dsr.R"))

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
names(subgroups_rates) <- subgroups_vctr # used in imap and iwalk (.y)
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
## Add column with total number in ESP for date, sex and subgroup variable
## (added because needed in function calc_dsr_i and calc_var_dsr_i)
subgroups_rates <- 
  imap(.x = subgroups_rates,
       .f = ~ group_by_at(.x, vars("date", "sex", !!.y)) %>%
         mutate(M_total = sum(EuropeanStandardPopulation)))

## Add column 'dsr_i' to subgroups_rates using funcion calc_dsr_i
subgroups_rates <-
  map(.x = subgroups_rates,
      .f = ~ mutate(
        .x,
        dsr_i = calc_dsr_i(
          C = 100000 * 30 / days_in_month(date),
          M_total = M_total,
          p = value,
          M = EuropeanStandardPopulation
        )
      ))
## Add column 'var_dsr_i' to subgroups_rates using function calc_var_dsr_i
subgroups_rates <-
  map(.x = subgroups_rates,
      .f = ~ mutate(
        .x,
        var_dsr_i = calc_var_dsr_i(
          C = 100000 * 30 / days_in_month(date),
          M_total = M_total,
          p = value,
          M = EuropeanStandardPopulation,
          N = population
        )
      ))
## For each date, sex, and level of 'subgroup', 
## --> sum over age to get dsr and var_dsr
subgroups_rates <-
  imap(.x = subgroups_rates,
       .f = ~ group_by_at(.x, vars("date", "sex", !!.y)) %>%
         summarise(dsr = sum(dsr_i, na.rm = TRUE),
                   var_dsr = sum(var_dsr_i, na.rm = TRUE),
                   .groups = "drop"))

# Save output ---
output_dir <- here("output", "rates")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = subgroups_rates,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_monthly_std.csv")))
