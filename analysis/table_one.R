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
library(jsonlite)
library(tibble)
library(stringr)
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
demographics <- config$demographics
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]
subgroups_vctr <- c("agegroup", "sex", demographics, comorbidities, "imp_vax")

## functions
# calculate number of people in a subgroup
summarise_subgroup <- function(data, subgroup){
  summary <- 
    data %>%
    group_by_at(subgroup) %>%
    summarise(n = n(),
              .groups = "keep") %>%
    add_column(subgroup = subgroup, .before = 1)
  colnames(summary)[colnames(summary) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  summary <- 
    summary %>%
    mutate(level = as.factor(level))
  summary
}
# calculate number of people in each population subgroup
summarise_subgroups <- function(data, subgroups_vctr, suffix){
  # subgroup "all" --> whole population
  summary_all <- 
    data %>%
    summarise(n = n()) %>%
    add_column(level = "-", .before = 1) %>%
    add_column(subgroup = "all", .before = 1)
  # data.frame with all population subgroups in 'subgroup_vctr'
  summary_subgroups <- 
    map(.x = subgroups_vctr,
        .f = ~ summarise_subgroup(data = data, subgroup = .x)) %>%
    bind_rows() %>%
    mutate(perc = ((n / summary_all$n) * 100) %>% round(1),
           n = n %>% plyr::round_any(5) %>% prettyNum(big.mark = ","),
           n = paste0(n, " (", perc, "%)")) %>%
    select(-perc)
  # bind info of whole pop + subgroup specific info
  out <-
    rbind(summary_all %>% mutate(n = n %>% 
                                 plyr::round_any(5) %>% 
                                 prettyNum(big.mark = ",")),
          summary_subgroups)
  colnames(out)[which(colnames(out) == c("n"))] <-
    paste0("n.", suffix)
  out
}

# Load data ---
# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
# vector with waves
waves_vctr <- str_extract(input_files_processed, "wave[:digit:]")
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
names(data_processed) <- waves_vctr
# Import incidence rates of waves  ---
input_file_irs_crude <- here("output", "tables", "ir_crude.csv")
# restrict to redacted figures
irs_crude <- read_csv(input_file_irs_crude,
                      col_types = 
                        cols_only(events_redacted = col_double(),
                                  time_redacted = col_double(),
                                  rate_redacted = col_double(),
                                  lower_redacted = col_double(),
                                  upper_redacted = col_double()))
input_files_irs_waves <- 
  Sys.glob(here("output", "tables", "wave*_ir.csv"))
irs_crude_subgroups <- 
  map(.x = input_files_irs_waves,
      .f = ~ rbind(read_csv(file = .x,
                             col_types = 
                             cols_only(subgroup = col_character(),
                                       level = col_character(),
                                       events_redacted = col_double(),
                                       time_redacted = col_double(),
                                       rate_redacted = col_double(),
                                       lower_redacted = col_double(),
                                       upper_redacted = col_double()))))
names(irs_crude_subgroups) <- waves_vctr

# Summarise data to create table 1 ---
# n_fu_summary is a list of waves, with number of people (n) for 
# 'all' and each population subgroup
n_fu_summary <- 
  imap(.x = data_processed,
       .f = ~ summarise_subgroups(data = .x, subgroups_vctr = subgroups_vctr,
                                  suffix = .y) %>%
        rename_subgroups())

# irs_crude is a list of waves, with events / time / rate and cis for the
# full population the following bit of code is needed to make a list of the 
# waves, before this action it is a data.frame with a column 'wave' to indicate
# the waves
irs_crude <- 
  irs_crude %>%
  add_column(level = "-", .before = 1) %>%
  add_column(subgroup = "all", .before = 1) %>%
  split(row(.)[,1])
names(irs_crude) <- waves_vctr

# irs_waves_list is a list of waves, combining irs_crude and irs_crude_subgroups
# and combining rate and ci into one column
irs_waves_list <-
  map2(.x = irs_crude_subgroups,
       .y = irs_crude,
       .f = ~ rbind(.y, .x))

irs_waves_list <- 
  imap(.x = irs_waves_list,
       .f = ~ {out <-
         .x %>%
         filter(!(subgroup %in% c("bp", "hypertension"))) %>%
         rename_subgroups() %>%
         mutate(events_redacted = events_redacted %>% 
                  prettyNum(big.mark = ","),
                time_redacted = round(time_redacted / 365250, 1) %>%
                  prettyNum(big.mark = ",")) %>%
         mutate(events_pys = paste0(events_redacted, " (", 
                                    time_redacted, ")"),
                rate_redacted = round(rate_redacted, 2),
                lower_redacted = round(lower_redacted, 2),
                upper_redacted = round(upper_redacted, 2)) %>%
         mutate(ir = 
                  paste0(rate_redacted,
                         " (", lower_redacted,
                         ";", upper_redacted,
                         ")")) %>%
         select(-c(events_redacted,
                   time_redacted,
                   rate_redacted,
                   lower_redacted,
                   upper_redacted))
         colnames(out)[which(colnames(out) == c("events_pys", "ir"))] <-
           paste0(c("events_pys.", "ir."), .y)
         out})

# join number of individuals and the incidence rates
table1 <- 
  map2(.x = irs_waves_list,
       .y = n_fu_summary,
       .f = ~ full_join(.y, .x, 
                        by = c("subgroup" = "subgroup", 
                               "level" = "level")))

# reformat to wide format
table1_wide <-
  plyr::join_all(table1, by = c("subgroup", "level"))

table1_wide <-
  table1_wide %>%
  filter(level != "FALSE")

# Save output --
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(table1_wide,
          path = paste0(output_dir,
                        "/table1.csv"))
