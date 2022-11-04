## ###########################################################

##  This script:
## - Imports the adjusted IRs
## - Imports the crude IRs for "agegroup"
## - Combines and formates these to create table A1

## linda.nab@thedatalab.com - 20220718
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(fs)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Create vector containing the demographics and comorbidities
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]
subgroups_vctr <- c("sex", config$demographics, comorbidities)
subgroups_vctr <- subgroups_vctr[-which(subgroups_vctr == "region")]
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups 
source(here("analysis", "utils", "rename_subgroups.R"))
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3", "wave4", "wave5")

# Import data extracts of waves  ---
# standardised IRs
input_files_irs_std <- 
  Sys.glob(here("output", "tables", "wave*_ir_std.csv"))
irs_std <- 
  map(.x = input_files_irs_std,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            ir = col_double(),
                                            lower = col_double(),
                                            upper = col_double())) %>%
        filter(!(subgroup %in% c("hypertension",
                                 "bp"))) %>%
        rename_subgroups() %>%
        mutate(ir = round(ir, 2),
               lower = round(lower, 2), 
               upper = round(upper, 2)) %>%
        mutate(ir_ci = paste0(ir, " (", lower, ";", upper, ")")) %>%
        select(subgroup, level, ir_ci))
input_files_irs_crude <- Sys.glob(here("output", "tables", "wave*_ir.csv"))
# agegroup is not age or sex standardised, and added to the irs
# for agegroup, the redacted rate is taken, for consistency throughout the 
# manuscript
irs_crude <- 
  map(.x = input_files_irs_crude,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            rate_redacted = col_double(),
                                            lower_redacted = col_double(),
                                            upper_redacted = col_double())) %>%
        filter(subgroup == "agegroup") %>%
        rename_subgroups() %>%
        rename(ir = rate_redacted,
               lower = lower_redacted,
               upper = upper_redacted) %>%
        mutate(ir = round(ir, 2),
               lower = round(lower, 2), 
               upper = round(upper, 2)) %>%
        mutate(ir_ci = paste0(ir, " (", lower, ";", upper, ")")) %>%
        select(subgroup, level, ir_ci))
# combine agegroup from crude file and rest
estimates <-
  map2(.x = irs_crude,
       .y = irs_std,
       .f = ~ bind_rows(.x, .y))
names(estimates) <- waves_vctr
## Make one wide table from list of processed tables
table_est <-
  estimates$wave1 %>%
  left_join(estimates$wave2,
            by = c("subgroup", "level"),
            suffix = c(".1", ".2")) %>%
  left_join(estimates$wave3,
            by = c("subgroup", "level")) %>%
  left_join(estimates$wave4,
            by = c("subgroup", "level"),
            suffix = c(".3", ".4")) %>%
  left_join(estimates$wave5,
            by = c("subgroup", "level"))
## add suffix '.3' to indicate wave 3 results
colnames(table_est)[which(colnames(table_est) == "ir_ci")] <-
  paste0("ir_ci", ".5")
## change order of Age Group and All
table_est <-
  table_est %>%
  slice(7, 1:6, 8:nrow(table_est))

# Save output --
## saved as '/output/tables/table_A1.csv
output_dir <- here("output", "tables")
dir_create(output_dir)
write_csv(table_est,
          path = path(output_dir, "table_A1.csv"))
