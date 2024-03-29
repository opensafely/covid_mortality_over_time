## ###########################################################

##  This script:
## - Imports data of the three waves
## - Calculates crude cum incidence
## - Saves sum inc + associated CIs in 
##   ./output/tables/wave*_effect_estimates

## linda.nab@thedatalab.com - 20220615
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
# source functions for calc of ir
source(here("analysis", "utils", "calc_ir.R"))
# create vector containing subgroups
subgroups_vctr <- c("agegroup", "sex",
                    config$demographics,
                    config$comorbidities,
                    "imp_vax")

# Import data extracts of waves ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
# vector with waves
waves_vctr <- str_extract(input_files_processed, "wave[:digit:]")
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
names(data_processed) <- waves_vctr

# Calculate crude ir per wave
# creates data.frame with ir and associated cis
# (1 crude ir per wave in one data.frame)
ir_crude <- 
  imap(.x = data_processed,
       .f = ~ .x %>%
        summarise(
          events = sum(died_ons_covid_flag_any),
          time = sum(as.numeric(fu)),
          calc_ir(events, time),
          events_redacted = case_when(events <= 5 ~ 0, 
                                      TRUE ~ plyr::round_any(events, 5)),
          time_redacted = plyr::round_any(time, 5),
          calc_ir(events_redacted, time_redacted, "_redacted")
        ) %>% 
        mutate(
          wave = .y
        )) %>%
    bind_rows()

# creates 3 data.frames (one for each wave)
# with ir for each level of each subgroup
ir_waves_subgroups <- 
  map(.x = data_processed,
      .f = ~ calc_ir_for_all_subgroups(data = .x, subgroups = subgroups_vctr))

# Save output --
## saved as '/output/tables/wave*ir.csv
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(ir_crude,
          path = paste0(output_dir, "/ir_crude.csv"))
iwalk(.x = ir_waves_subgroups,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_ir.csv")))
