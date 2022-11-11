## ###########################################################

##  This script:
## - extracts and processed the 2022 data and counts number of deaths

## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(here)
library(lubridate)
library(readr)

# output dir
fs::dir_create(here("output", "data_properties"))

# count number
data_2022 <-
  read_csv(here("output", "input_2022.csv.gz"),
           col_types = cols_only(
             patient_id = col_integer(),
             died_ons_covid_any_date = col_date(),
             died_any_date = col_date()
           ))

data_2022 <-
  data_2022 %>%
  mutate(weeknr_covid_death = week(died_ons_covid_any_date),
         weeknr_any_death = week(died_any_date))

cat("\n#### Week nr x number of covid-related deaths ####\n")
data_2022 %>%
  group_by(weeknr_covid_death) %>%
  summarise(n = n()) %>%
  write_csv(here("output", "data_properties", "n_covid_deaths_2022.csv"))

cat("\n#### Week nr x number of deaths of any cause ####\n")
data_2022 %>%
  group_by(weeknr_any_death) %>%
  summarise(n = n()) %>%
  write_csv(here("output", "data_properties", "n_any_deaths_2022.csv"))