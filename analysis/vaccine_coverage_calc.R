## ###########################################################

##  This script:
## - Imports data of the three waves
## - Calculates vaccine coverage for each subgroup

## linda.nab@thedatalab.com - 20220608
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c("agegroup", "sex", config$demographics, config$comorbidities)

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
names(data_processed) <- c("wave1", "wave2", "wave3")

# Functions ---
## 'calc_n_vax' creates a summary table for a specific subgroup with columns:
## ssubgroup level n_vax_1 n_vax_2 n_vax_3 n cov_1 cov_2 cov_3
## arguments:
## data: extract of data (usually data_processed$wave1)
## subgroup: character of subgroup (e.g., "bmi")
## output:
## summary table with columns
## subgroup level n_vax_1 n_vax_2 n_vax_3 n cov_1 cov_2 cov_3
## for subgroup 'subgroup'
calc_n_vax <- function(data, subgroup){
  # calculate number of people vaccinated (1 dose/ 2 doses/ 3 doses)
  summary <- 
    data %>%
      group_by_at(vars(!!subgroup)) %>%
      summarise(n_vax_1 = sum(!is.na(covid_vax_date_1)),
                n_vax_2 = sum(!is.na(covid_vax_date_2)),
                n_vax_3 = sum(!is.na(covid_vax_date_3)),
                n = n()) %>% # redact rates
      mutate(n_vax_1 = case_when(n_vax_1 <= 5 ~ as.integer(0),
                                 TRUE ~ n_vax_1),
             n_vax_2 = case_when(n_vax_2 <= 5 ~ as.integer(0),
                                 TRUE ~ n_vax_2),
             n_vax_3 = case_when(n_vax_3 <= 5 ~ as.integer(0),
                                 TRUE ~ n_vax_3)) %>%
      mutate(subgroup = !!subgroup, # add column subgroup
             cov_1 = (n_vax_1 / n) * 100, # calculate coverage
             cov_2 = (n_vax_2 / n) * 100,
             cov_3 = (n_vax_3 / n) * 100)
  # rename column (in order to create identical summaries with the same
  # column names for each subgroup)
  # which will look like this:
  # subgroup level n_vax_1 n_vax_2 n_vax_3 n cov_1 cov_2 cov_3
  # - - - - -
  colnames(summary)[colnames(summary) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  summary <- 
    summary %>%
    mutate(level = as.factor(level))
  # change order of columns (reorder as described above)
  summary <- summary[, c(6, 1, 2, 3, 4, 5, 7, 8, 9)]
  summary
}
## 'create_overview_n_vax_for_all_subgroups' creates a table using calc_n_vax 
## combining them 
## for each subgroup in subgroup_vctr
## arguments:
## data: data extract (here usually data_processed$wave1)
## output:
## summary table with columns
## subgroup level n_vax_1 n_vax_2 n_vax_3 n cov_1 cov_2 cov_3
## for all subgroups
create_overview_n_vax_for_all_subgroups <- function(data){
  map(.x = subgroups_vctr,
      .f = ~ calc_n_vax(data, .x)) %>%
  bind_rows()
}

# Create list with vaccine coverage --
## first dose, second dose and third dose for each wave, for each subgroup
vax_coverage_waves <- 
  map(.x = data_processed,
      .f = ~ create_overview_n_vax_for_all_subgroups(.x))

# Save output --
## saved as '/output/tables/wave*_vax_coverage.csv
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
iwalk(.x = vax_coverage_waves,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_vax_coverage.csv")))
