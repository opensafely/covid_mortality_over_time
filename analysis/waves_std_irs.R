## ###########################################################

##  This script:
## - Imports data of the three waves
## - Standardises the incidence rates
## - Saves these in ./output/tables/wave*_ir_std.csv

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
source(here("analysis", "utils", "dsr.R"))
# create vector containing subgroups
subgroups_vctr <- c("sex",
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
## European Standard population
esp <- 
  read_csv(file = here("input", "european_standard_pop.csv"),
           col_types = cols_only( # only read the columns defined here
             AgeGroup = col_factor(),
             Sex = col_factor(),
             EuropeanStandardPopulation = col_integer())) %>%
  filter(!(AgeGroup %in% c("0-4 years", "5-9 years", "10-14 years"))) %>% # remove
# age groups that are not part of the study population (< 18 year old)
  mutate(M_total = sum(EuropeanStandardPopulation)) # needed for standardisation

summarise_data_subgroup <- function(data, subgroup){
  data_summarised_subgroup <- 
    data %>%
    group_by_at(vars("agegroup_std", "sex", !!subgroup)) %>%
    summarise(events = sum(died_ons_covid_flag_any),
              time = sum(as.numeric(fu)),
              .groups = "keep")
  data_summarised_subgroup <-
    data_summarised_subgroup %>%
    group_by_at(vars(!!subgroup)) %>%
    # calculate number of events in each level of the subgruop
    # --> to redact when lower than 5
    mutate(total_events_in_level = sum(events)) %>%
    mutate(events_redacted = case_when(total_events_in_level <= 5 ~ 0L,
                              TRUE ~ events)) %>%
    select(-total_events_in_level)
  data_summarised_subgroup
}

subgroups_irs_wave <- function(data, esp, subgroups_vctr){
  # join data_summarised with esp 
  # data_summarised is created using function 'summarise_data_subgroup()'
  # and columns ir_i (incidence rate per agegroup_std, sex, subgroup) and
  # columns var_ir variance of ir (see functions in analysis/utils/dsr.R)
  # output is a list of data.frames, for each level in subgroups_vctr:
  # agegroup_std sex 'subgroup' EuropeanStandardPopulation M_total ir_i var_i
  subgroups_irs <- 
    map(.x = subgroups_vctr,
        .f = ~ summarise_data_subgroup(data, .x) %>%
          left_join(esp, by = c("agegroup_std" = "AgeGroup", "sex" = "Sex")) %>%
          mutate(ir_i = calc_dsr_i(
            C = 365250,
            M_total = M_total,
            p = events_redacted / time, # based on redacted no. of events
            M = EuropeanStandardPopulation)) %>%
          mutate(var_ir_i = calc_var_dsr_i(
            C = 365250,
            M_total = M_total,
            p = events_redacted / time, # based on redacted no. of events
            M = EuropeanStandardPopulation,
            N = time)))
  # add names to list
  names(subgroups_irs) <- subgroups_vctr
  
  # sum over all levels of age and sex to end up with one ir for each
  # level of each subgroup (= age and sex standardised)
  # output is a named list of data.frames for each subgroup in subgroup_vctr:
  # level ir var_ir lower upper subgroup
  subgroups_irs <-
    imap(.x = subgroups_irs,
         .f = ~ group_by_at(.x, vars(!!.y)) %>%
           summarise(ir = sum(ir_i, na.rm = TRUE),
                     var_ir = sum(var_ir_i, na.rm = TRUE),
                     .groups = "keep") %>%
           mutate(lower = ir - qnorm(0.975) * sqrt(var_ir),
                  upper = ir + qnorm(0.975) * sqrt(var_ir),
                  subgroup = !!.y) %>%
           rename(level = all_of(.y)) %>%
           mutate(level = as.factor(level)))
  
  # unlist the named list 
  subgroups_irs <- 
    subgroups_irs %>% bind_rows()
  
  # rearrange columns to:
  # subgroup level ir var_ir lower upper
  subgroups_irs <- 
    subgroups_irs[c(6, 1, 2, 3, 4, 5)] 
  subgroups_irs
}

subgroups_irs_all_waves <- 
  map(.x = data_processed,
      .f = ~ subgroups_irs_wave(.x, esp, subgroups_vctr))

# std irs overall population
overall_irs_i <-
  map(.x = data_processed,
      .f = ~ .x %>%
        group_by(agegroup_std, sex) %>%
        summarise(events = sum(died_ons_covid_flag_any),
                  time = sum(as.numeric(fu)),
                  .groups = "keep") %>%
        left_join(esp, by = c("agegroup_std" = "AgeGroup", "sex" = "Sex")) %>%
        mutate(ir_i = calc_dsr_i(
          C = 365250,
          M_total = M_total,
          p = events / time, # based on redacted no. of events
          M = EuropeanStandardPopulation)) %>%
        mutate(var_ir_i = calc_var_dsr_i(
          C = 365250,
          M_total = M_total,
          p = events / time, # based on redacted no. of events
          M = EuropeanStandardPopulation,
          N = time)))

overall_irs <- 
  map(.x = overall_irs_i,
      .f = ~ tibble(
        subgroup = "all",
        level = "-" %>% as.factor(),
        ir = sum(.x$ir_i),
        var_ir = sum(.x$var_ir_i)
      ) %>%
        mutate(lower = ir - qnorm(0.975) * sqrt(var_ir),
               upper = ir + qnorm(0.975) * sqrt(var_ir)))

# Combine overall and subgroup irs_std ---
irs_std <-
  map2(.x = overall_irs,
       .y = subgroups_irs_all_waves,
       .f = ~ rbind(.x, .y))

# Save output ---
## saved as '/output/tables/wave*_ir_std.csv
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
iwalk(.x = irs_std,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, "_ir_std.csv")))
