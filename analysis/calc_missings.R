## ###########################################################

##  This script:
## - Calculates numbers of missings

## linda.nab@thedatalab.com - 20220707
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)
library(tibble)
library(fs)
library(purrr)
library(stringr)

# Load data ---
## Search input files by globbing
input_files <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
input_files <- input_files[str_detect(input_files, "input_wave[^_]+\\.rds")]
waves_vctr <- str_extract(input_files, "wave[:digit:]")
## Extract data from the input_files and formats columns to correct type 
## (e.g., integer, logical etc)
data_processed <-
  map(.x = input_files,
      .f = ~ readRDS(.x))
names(data_processed) <- waves_vctr

# Calculate missings ---
n_missing_smoking <- 
  map_dfr(.x = data_processed,
          .f = ~ .x %>% filter(smoking_status == "Missing") %>% nrow() %>%
            plyr::round_any(5)) %>%
  add_column(variable = "smoking_status", .before = 1)

n_missing_ethnicity <- 
  map_dfr(.x = data_processed,
          .f = ~ .x %>% filter(ethnicity == "Unknown") %>% nrow() %>%
            plyr::round_any(5)) %>%
  add_column(variable = "ethnicity", .before = 1)

n_missing_bmi <-
  map_dfr(.x = data_processed,
          .f = ~ .x %>% filter(bmi_value == 0) %>% nrow() %>%
            plyr::round_any(5)) %>%
  add_column(variable = "bmi", .before = 1)

# add column with total number of indivivduals per wave
total <-
  map_dfr(.x = data_processed,
          .f = ~ .x %>% nrow() %>%
            plyr::round_any(5)) %>%
  add_column(variable = "total", .before = 1)

missings <- 
  rbind(n_missing_smoking,
        n_missing_ethnicity,
        n_missing_bmi, 
        total) %>%
  # calc percentage of missings
  mutate(wave1_perc = (wave1 / wave1[variable == "total"]) %>% round(2),
         wave2_perc = (wave2 / wave2[variable == "total"]) %>% round(2),
         wave3_perc = (wave3 / wave3[variable == "total"]) %>% round(2),
         wave4_perc = (wave4 / wave4[variable == "total"]) %>% round(2),
         wave5_perc = (wave5 / wave5[variable == "total"]) %>% round(2))

# Save output ---
output_dir0 <- here("output", "tables")
dir_create(output_dir0)
output_dir <- here("output", "tables", "missings")
dir_create(output_dir)
write_csv(x = missings,
          path = path(output_dir, "waves_missings.csv"))
