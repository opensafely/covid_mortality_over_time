## ###########################################################

##  This script:
## - Import the data
## - Makes table infection x deaths for supplement

## linda.nab@thedatalab.com - 20221208
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(stringr)
# load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))

# Import data extracts of waves ---
input_files_waves <-
  Sys.glob(here("output", "joined", "input_wave*.csv.gz"))
waves_vctr <- str_extract(input_files_waves, "wave[:digit:]")
waves_list <- 
  map(.x = input_files_waves,
      .f = ~ read_csv(.x))
names(waves_list) <- waves_vctr

# Make table ---
pos_test_in_covid_deaths <- function(data_wave, wave){
  data_wave %>%
    mutate(pos_test = !is.na(covid_test_positive_date),
           covid_death = !is.na(died_ons_covid_any_date)) %>%
    filter(covid_death == TRUE) %>%
    group_by(pos_test, .drop = FALSE) %>%
    tally() %>%
    mutate(n = case_when(n <= 5 ~ NA_real_,
                         TRUE ~ plyr::round_any(n, 5)),
           wave = wave)
}
pos_tests <- 
  imap(.x = waves_list,
       .f = ~ pos_test_in_covid_deaths(.x, .y)) %>% bind_rows()
pos_test %>% print()

# Save output --
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(pos_tests, paste0(output_dir, "/pos_test_in_covid_deaths.csv"))