## ###########################################################

##  This script:
## - Checks when sum of fu on dose x is not total of fu

## linda.nab@thedatalab.com - 20220111
## ###########################################################
library(tibble)
library(readr)
library(purrr)
library(stringr)

source(here::here("analysis", "utils", "process_vax_vars.R"))
source(here::here("analysis", "utils", "waves_vax_coverage_fu.R"))

# Import data extracts of waves ---
input_files_processed <-
  Sys.glob(here::here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
# vector with waves
waves_vctr <- str_extract(input_files_processed, "wave[:digit:]")
names(data_processed) <- waves_vctr
# process wave 2 data
data_processed$wave2 <- 
  process_vax_data_wave2(data_processed$wave2)

# filter data to select cases were sum of individual parts is not total fup
data_filter <- 
  data_processed$wave2 %>%
  mutate(fu_dose_sum = 
           fu_vax_0 + fu_vax_1 + fu_vax_2 + fu_vax_3 + fu_vax_4 + fu_vax_5 + fu_vax_6,
         end_fu = start_date_wave + fu) %>%
  filter(fu != fu_dose_sum) %>%
  select(start_date_wave, 
         end_fu,
         died_any_date,
         died_ons_covid_any_date, 
         starts_with("start_vax_dose_"),
         starts_with("ind_fu_vax"),
         fu,
         starts_with("fu_vax_"))
print(nrow(data_filter))
# select 100 cases in data
ids <- 
  sample(1:nrow(data_filter), 100, TRUE)
data_selection <- 
  data_filter[ids, ]

# save output
fs::dir_create(here::here("output", "data_properties"))
write_csv(data_selection,
          here::here("output", "data_properties", "vax_fup_issue.csv"))
