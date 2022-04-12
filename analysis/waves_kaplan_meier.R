## ###########################################################

##  This script:
## - Imports data of the three waves
## - Plots Kaplan Meiers
## - Saves Kaplan Meiers to ./output/figures

## linda.nab@thedatalab.com - 20220412
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(survival)
library(survminer)
library(stringr)
## Load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))
# create vector containing subgroups
subgroups_vctr <- c(config$demographics, config$comorbidities)
# source functions 'km_fit' and 'km_plot' 
source(here("analysis", "utils", "plot_kaplan_meier.R"))
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3")

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
## add variable fu
data_processed <-
  map2(.x = data_processed,
       .y = c(config$wave1$start_date, 
              config$wave2$start_date,
              config$wave3$start_date),
       .f = ~ mutate(.x, 
                     fu = difftime(died_ons_covid_flag_any_date, .y)))
names(data_processed) <- waves_vctr

# Kaplan-Meier plotting ---
# Create list containing 2 survfit objects ('Female' and 'Male') for each wave.
# This is a list of a list, first level = waves, second level is 
# 'Females' and 'Males' and for each level a survfit object is saved
sfit_list_waves_list <- 
  map(.x = data_processed,
      .f = ~ km_fit(.x))

# Create list containing the plots of the survfit objects in 
# 'sfit_list_waves_list'. It is a list of a list, first level = waves, second
# level is 'Females' and 'Males' and for each level a plot of the survfit 
# objects is saved
plots_waves_list <- 
  map(.x = waves_vctr,
      .f = ~ km_plot(sfit_list_waves_list,
                     data_processed,
                     .x))
# Name list before unlisting --> 'wave1', 'wave2', 'wave3'
names(plots_waves_list) <- waves_vctr
# Unlist (only first level), plot_waves_list is now a list with one level, with 
# names 'wave1.Female', 'wave1.Male', etc... 
plots_waves_list <- unlist(plots_waves_list, recursive = FALSE)

# Save output --
output_dir <- here("output", "figures", "kaplan_meier")
ifelse(!dir.exists(here("output", "figures")), 
       dir.create(here("output", "figures")), 
       FALSE) # create ./output/figures if not already there
ifelse(!dir.exists(output_dir), 
       dir.create(output_dir), 
       FALSE)
# change names of list of plots to the ones that will be used to save the file 
# --> i.e., filename = 'wave1.Female' = 'wave1_F'
names(plots_waves_list) <- 
  names(plots_waves_list) %>%
  str_replace("[.]", "_") %>%
  substr(1, 7)
# save plots
walk(.x = names(plots_waves_list),
     .f = ~ ggsave(plot = plots_waves_list[[.x]]$plot, 
                   # need $plot as per
                   # https://github.com/kassambara/survminer/issues/152
                   filename = paste0(output_dir, 
                                     "/", 
                                     .x, 
                                     ".png"),
                   device = "png"))
