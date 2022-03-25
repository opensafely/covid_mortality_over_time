## ###########################################################

##  This script:
## - Imports the crude rates
## - Makes plots over time

## linda.nab@thedatalab.com - 20220324
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(ggplot2)
## load function plot_rates.R from ./analysis/utils used to plot mortality
## rates over time
source(here("analysis", "utils", "plot_rates.R"))

# Import rates ---
crude_rates <- 
  read_csv(file = here("output", "rates", "crude_monthly_std.csv"),
           col_types = cols("D", "d"))
crude_rates_per_agegroup <-
  read_csv(file = here("output", "rates", "crude_per_agegroup_monthly_std.csv"),
           col_types = cols("D", "f", "f", "d"))

# Plot rates ---
## Plot crude rates
crude_plot <- 
  crude_rates %>%
  plot_rates(.,
             x = "date",
             y = "std_value")
## Plot crude rates per age group (separate plot per sex)
crude_agroup_plots <- 
  map(.x = c("F", "M"),
      .f = ~ crude_rates_per_agegroup %>% 
             filter(sex == .x) %>%
             plot_rates(.,
                        x = "date",
                        y = "std_value",
                        group = "agegroup",
                        col = "agegroup") +
             ggtitle(label = ifelse(.x == "M", "Male", "Female")))

# Save plots ---
## Plots are saved in ./output/figures/rates_crude
output_dir <- here("output", "figures", "rates_crude")
ifelse(!dir.exists(here("output", "figures")), 
       dir.create(here("output", "figures")), 
       FALSE) # create ./output/figures if not already there
ifelse(!dir.exists(output_dir), 
       dir.create(output_dir), 
       FALSE)
## Save sex plot
ggsave(filename = paste0(output_dir, "crude.png"),
       device = "png",
       plot = crude_plot)
## Save the remaining plots
file_names <- c(paste0(output_dir, "/crude_agegroup_F.png"),
                paste0(output_dir, "/crude_agegroup_M.png"))
names(crude_agroup_plots) <- file_names
iwalk(.x = crude_agroup_plots,
      .f = ~ ggsave(filename = .y,
                    device = "png",
                    plot = .x))
