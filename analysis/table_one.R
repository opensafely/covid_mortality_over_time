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
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
demographics <- config$demographics
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]
subgroups_vctr <- c("agegroup", "sex", demographics, comorbidities)
## functions
# calculate number of people in a subgroup, median fu and iqr
summarise_subgroup <- function(data, subgroup){
  summary <- 
    data %>%
    group_by_at(subgroup) %>%
    summarise(n = n(),
              fu_median = median(fu) %>% as.numeric(),
              fu_q1 = quantile(fu, 0.25) %>% as.numeric(),
              fu_q3 = quantile(fu, 0.75) %>% as.numeric()) %>%
    mutate(fu = paste0(fu_median, " [", fu_q1, "-", fu_q3, "]")) %>%
    add_column(subgroup = subgroup, .before = 1) %>%
    select(-c(fu_median, fu_q1, fu_q3))
  colnames(summary)[colnames(summary) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  summary <- 
    summary %>%
    mutate(level = as.factor(level))
  summary
}
# calculate number of people in each population subgroup, median fu and iqr
summarise_subgroups <- function(data, subgroups_vctr){
  # subgroup "all" --> whole population
  summary_all <- 
    data %>%
    summarise(n = n(),
              fu_median = median(fu) %>% as.numeric(),
              fu_q1 = quantile(fu, 0.25) %>% as.numeric(),
              fu_q3 = quantile(fu, 0.75) %>% as.numeric()) %>%
    mutate(fu = paste0(fu_median, " [", fu_q1, "-", fu_q3, "]")) %>%
    add_column(level = "-", .before = 1) %>%
    add_column(subgroup = "all", .before = 1) %>%
    select(-c(fu_median, fu_q1, fu_q3))
  # data.frame with all population subgroups in 'subgroup_vctr'
  summary_subgroups <- 
    map(.x = subgroups_vctr,
        .f = ~ summarise_subgroup(data = data, subgroup = .x)) %>%
    bind_rows()
  # bind info of whole pop + subgroup specific info
  rbind(summary_all,
        summary_subgroups)
}

# Load data ---
# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
names(data_processed) <- c("wave1", "wave2", "wave3")
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

# Summarise data to create table 1 ---
# n_fu_summary is a list of waves, with number of people (n) and fu [IQR] for 
# 'all' and each population subgroup
n_fu_summary <- 
  map(.x = data_processed,
      .f = ~ summarise_subgroups(data = .x, subgroups_vctr = subgroups_vctr) %>%
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
names(irs_crude) <- c("wave1", "wave2", "wave3")

# irs_waves_list is a list of waves, combining irs_crude and irs_crude_subgroups
# and combining rate and ci into one column
irs_waves_list <- 
  map2(.x = irs_crude_subgroups,
       .y = irs_crude,
       .f = ~ rbind(.y,
                    .x)%>%
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

# join number of individuals + summary of fu time and the incidence rates
table1 <- 
  map2(.x = irs_waves_list,
       .y = n_fu_summary,
       .f = ~ full_join(.y, .x, 
                        by = c("subgroup" = "subgroup", 
                               "level" = "level")))

# reformat to wide format
table1_wide <-
  table1$wave1 %>%
  left_join(table1$wave2,
            by = c("subgroup", "level"),
            suffix = c(".1", ".2")) %>%
  left_join(table1$wave3,
            by = c("subgroup", "level"))
## add suffix '.3' to indicate wave 3 results
colnames(table1_wide)[c(13, 14, 15, 16, 17)] <- 
  paste0(colnames(table1_wide)[c(13, 14, 15, 16, 17)], ".3")

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(table1_wide,
          path = paste0(output_dir,
                        "/table1.csv"))
