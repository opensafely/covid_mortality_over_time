## ###########################################################

##  This script:
## - Tidies irs for release (exclusive the redacted rates)
## - IRs and 95% CIs are rounded and combined in one column

## linda.nab@thedatalab.com - 20220628
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(here)
library(readr)
library(purrr)
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))

# Import data extracts of waves  ---
input_file_irs_crude <- here("output", "tables", "ir_crude.csv")
input_files_irs_waves <- 
  Sys.glob(here("output", "tables", "wave*_ir.csv"))

# restrict to redacted figures
irs_crude <- read_csv(input_file_irs_crude,
                     col_types = 
                       cols_only(events_redacted = col_double(),
                                 time_redacted = col_double(),
                                 rate_redacted = col_double(),
                                 lower_redacted = col_double(),
                                 upper_redacted = col_double(),
                                 wave = col_character()))
# restrict to redacted figures
irs_waves_list <- 
  map(.x = input_files_irs_waves,
      .f = ~ read_csv(file = .x,
                      col_types = 
                        cols_only(subgroup = col_character(),
                                  level = col_character(),
                                  events_redacted = col_double(),
                                  time_redacted = col_double(),
                                  rate_redacted = col_double(),
                                  lower_redacted = col_double(),
                                  upper_redacted = col_double())) %>%
        filter(!(subgroup %in% c("bp", "hypertension"))) %>%
        rename_subgroups() %>%
        mutate(rate_redacted = round(rate_redacted, 2),
               lower_redacted = round(lower_redacted, 2),
               upper_redacted = round(upper_redacted, 2)) %>%
        mutate(ir = 
                 paste0(rate_redacted,
                        " (", lower_redacted,
                        ";", upper_redacted,
                        ")")) %>%
        select(-c(rate_redacted,
                  lower_redacted,
                  upper_redacted)))
names(irs_waves_list) <- c("wave1", "wave2", "wave3")

# make in long format
irs_waves <-
  irs_waves_list$wave1 %>%
  left_join(irs_waves_list$wave2,
            by = c("subgroup", "level"),
            suffix = c(".1", ".2")) %>%
  left_join(irs_waves_list$wave3,
            by = c("subgroup", "level"))
## add suffix '.3' to indicate wave 3 results
colnames(irs_waves)[c(9, 10, 11)] <- 
  paste0(colnames(irs_waves)[c(9, 10, 11)], ".3")

# Save output --
output_dir0 <- here("output", "tables")
ifelse(!dir.exists(output_dir0), dir.create(output_dir0), FALSE)
output_dir <- here("output", "tables", "irs_redacted")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(irs_crude,
          path = paste0(output_dir,
                        "/waves_ir_crude_redacted.csv"))
write_csv(irs_waves,
          path = paste0(output_dir,
                        "/subgroups_ir_crude_redacted.csv"))
