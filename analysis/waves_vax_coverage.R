## ###########################################################

##  This script:
## - Imports data of the five waves
## - Calculates % of people on each vax dose at start of the wave and at the end
##   of the wave

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
# load function
# process_vax_data2/3/4_5
source(here("analysis", "utils", "process_vax_vars.R"))
source(here("analysis", "utils", "waves_vax_coverage_q.R"))
source(here("analysis", "utils", "waves_vax_coverage_counts.R"))
source(here("analysis", "utils", "waves_vax_coverage_fu.R"))

# create vector containing subgroups
subgroups_vctr <- c("agegroup",
                    "sex",
                    config$demographics,
                    config$comorbidities,
                    "imp_vax")

# Import data extracts of waves ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
input_files_processed <- 
  input_files_processed[!str_detect(input_files_processed, "wave1")]

data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
# vector with waves
waves_vctr <- str_extract(input_files_processed, "wave[:digit:]")
names(data_processed) <- waves_vctr

data_processed$wave2 <- 
  process_vax_data_wave2(data_processed$wave2)
data_processed$wave3 <-
  process_vax_data_wave3(data_processed$wave3)
data_processed$wave4 <-
  process_vax_data_wave4_5(data_processed$wave4)
data_processed$wave5 <-
  process_vax_data_wave4_5(data_processed$wave5)

# creates data.frames (one for each wave)
# with q2, q1 and q3 of start and end dose for each level of each subgroup
waves_vax_q_all <-
  map(.x = data_processed,
      .f = ~ vax_q(data = .x) %>%
        add_column(subgroup = "all", .before = 1) %>%
        add_column(level = {"-" %>% as.factor()}, .after = 1))
waves_vax_q_subgroups <- 
  map(.x = data_processed,
      .f = ~ vax_q_all_subgroups(data = .x, subgroups = subgroups_vctr))
# combined
waves_vax_q <-
  map2(.x = waves_vax_q_all,
       .y = waves_vax_q_subgroups,
       .f = ~ bind_rows(.x, .y))

# creates data.frames (one for each wave)
# with tables of counts of individuals per dose at start and end of wave
# of each subgroup
waves_vax_counts_all <-
  map(.x = data_processed,
      .f = ~ vax_counts(data = .x) %>%
        add_column(subgroup = "all", .before = 1) %>%
        add_column(level = {"-" %>% as.factor()}, .after = 1))
waves_vax_counts_subgroups <- 
  map(.x = data_processed,
      .f = ~ vax_counts_all_subgroups(data = .x, subgroups = subgroups_vctr))
# combined
waves_vax_counts <-
  map2(.x = waves_vax_counts_all,
       .y = waves_vax_counts_subgroups,
       .f = ~ bind_rows(.x, .y))

# creates data.frames (one for each wave)
# with tables of fu with total follow up time & per dose for each subgroup
waves_vax_fu_all <-
  map(.x = data_processed,
      .f = ~ vax_fu(data = .x) %>%
        add_column(subgroup = "all", .before = 1) %>%
        add_column(level = {"-" %>% as.factor()}, .after = 1))
waves_vax_fu_subgroups <- 
  map(.x = data_processed,
      .f = ~ vax_fu_all_subgroups(data = .x, subgroups = subgroups_vctr))
# combined
waves_vax_fu <-
  map2(.x = waves_vax_fu_all,
       .y = waves_vax_fu_subgroups,
       .f = ~ bind_rows(.x, .y))


# Save output --
## saved as '/output/tables/wave*ir.csv
output_dir <- here("output", "tables", "vax")
fs::dir_create(here("output", "tables"))
fs::dir_create(output_dir)
iwalk(.x = waves_vax_q,
      .f = ~ write_csv(.x,
                       fs::path(output_dir,
                                paste0(.y, "_vax_q.csv"))))
iwalk(.x = waves_vax_counts,
      .f = ~ write_csv(.x,
                       fs::path(output_dir,
                                paste0(.y, "_vax_counts.csv"))))
iwalk(.x = waves_vax_fu,
      .f = ~ write_csv(.x,
                       fs::path(output_dir,
                                paste0(.y, "_vax_fu.csv"))))
