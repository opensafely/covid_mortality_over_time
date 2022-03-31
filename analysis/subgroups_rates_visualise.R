## ###########################################################

##  This script:
## - Imports the standardised rates
## - Create and saves plots for each demographic and comorbidity (see config.json)

## linda.nab@thedatalab.com - 20220323
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(tidyr) # expand_grid
library(jsonlite)
library(ggplot2)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## load function plot_rates.R from ./analysis/utils used to plot mortality
## rates over time
source(here("analysis", "utils", "plot_rates.R"))

# Import rates ---
## For each demographic / comorbidity, we need two graphs: one for females;
## one for males. Each graph has several lines equal to the number of levels of
## the demographic / comorbidity variable.
## For sex, we need one graph, with two lines, this is different from the other
## demographic / comorbidity variables and therefore imported + plotted 
## separately in this script.
## Import mortality rates for sex:
sex_rates_std <- read_csv(file = here("output", 
                                      "rates",
                                      "sex_monthly_std.csv"),
                          col_types = cols("D", "f", "d"))
# Import the rest of the mortality rates:
subgroups_vctr <- c(config$demographics, config$comorbidities)
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  "processed",
                                  paste0(.x,"_monthly_std.csv")),
                      col_types = cols("D", "f", "f", "d", "d")))
# calculate ci's
sex_rates_std <- 
  sex_rates_std %>%
  mutate(ci_lo = dsr - qnorm(0.975) * sqrt(var_dsr),
         ci_up = dsr + qnorm(0.975) * sqrt(var_dsr))
subgroups_rates_std <-
  map(.x = subgroups_rates_std,
      .f = ~ mutate(.x, 
                    ci_lo = dsr - qnorm(0.975) * sqrt(var_dsr),
                    ci_up = dsr + qnorm(0.975) * sqrt(var_dsr)))

# Plot rates ---
## Plot rates for sex:
sex_plot <- 
  sex_rates_std %>%
  plot_rates(., 
             x = "date", 
             y = "dsr",
             ci_lo = "ci_lo",
             ci_up = "ci_up",
             group = "sex") +
  scale_colour_discrete(name  ="Sex",
                        labels = c("Female", "Male"))
## The remaining variables
## Make a grid with every demographic/comorb variable combined with "F" and
## "M", needed since for every demographic/comorb variable we need a plot for 
## sex equal to "F" and "M".
subgroups_plots_grid <- 
  expand_grid(subgroups = subgroups_vctr,
              sex = c("F", "M"))
## Make plots and save in list
subgroups_plots <- 
    map2(.x = subgroups_plots_grid$subgroups,
         .y = subgroups_plots_grid$sex,
         .f = ~ subgroups_rates_std[[which(subgroups_vctr == .x)]] %>% 
                filter(sex == .y) %>%
                plot_rates(.,
                           x = "date",
                           y = "dsr",
                           ci_lo = "ci_lo",
                           ci_up = "ci_up",
                           group = .x) +
                  scale_colour_discrete(name = .x) +
                  ggtitle(label = ifelse(.y == "M", "Male", "Female"))) # add male/female

# Save plots ---
## Plots are saved in ./output/figures/rates_subgroups
output_dir <- here("output", "figures", "rates_subgroups")
ifelse(!dir.exists(here("output", "figures")), 
       dir.create(here("output", "figures")), 
       FALSE) # create ./output/figures if not already there
ifelse(!dir.exists(output_dir), 
       dir.create(output_dir), 
       FALSE)
## Save sex plot
ggsave(filename = paste0(output_dir, "/sex.png"),
       device = "png",
       plot = sex_plot)
## Save the remaining plots
file_names <- paste0(output_dir, 
                     "/",
                      paste0(subgroups_plots_grid$subgroups,
                             "_", 
                             subgroups_plots_grid$sex, 
                             ".png"))
names(subgroups_plots) <- file_names # used in iwalk as .y
iwalk(.x = subgroups_plots,
      .f = ~ ggsave(filename = .y,
                    device = "png",
                    plot = .x))
