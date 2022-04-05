## ###########################################################

##  This script:
## - Imports the standardised rate ratios
## - Create and saves plots for sex + each demographic and comorbidity 
## (see config.json) (plots saved in ./output/figures/ratios_subgroups)

## linda.nab@thedatalab.com - 20220331
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
source(here("analysis", "utils", "plot_ratios.R"))
source(here("analysis", "utils", "reference_values.R"))

# Import rates ---
## For sex, we need one graph, with one line, this is different from the other
## demographic / comorbidity variables and therefore imported + plotted 
## separately in this script.
## For each demographic, we need two graphs: one for females;
## one for males. Each graph has several lines equal to the number of levels of
## the demographic / comorbidity variable minus 1 (the reference is not plotted)
## For the comorbidities, there are binary comorbidities and comorbidities with
## multiple levels. For the binary comorbidities, we need one graph with two 
## lines (females + males). For the multilevel comorbidities, we need two graphs
## with multiple lines (seperate  graph for female + males) (similar to demogr.)
## Import rate ratios for sex:
sex_ratios <- read_csv(file = here("output", 
                                   "ratios",
                                   "sex.csv"),
                        col_types = cols("D", "f", 
                                         "d", "d", "d"))
# Import multilevel rate ratios:
comorbidities_multilevel_vctr <- c("asthma",
                                   "diabetes_controlled",
                                   "dialysis_kidney_transplant",
                                   "ckd",
                                   "organ_kidney_transplant")
multilevel_vctr <- c(config$demographics, comorbidities_multilevel_vctr)
multilevel_ratios <- 
  map(.x = multilevel_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "ratios",
                                  paste0(.x,".csv")),
                      col_types = cols("D", "f", "f", 
                                       "d", "d", "d")))
names(multilevel_ratios) = multilevel_vctr # used in imap/iwalk
## Add reference to 'multilevel_ratios using df reference_values sourced from
## ./analysis/utils/reference_values.R
## reference is needed to identify the reference (not plotted)
multilevel_ratios <-
  imap(.x = multilevel_ratios,
       .f = ~ 
         mutate(.x, 
                reference = 
                  reference_values %>% filter(subgroup == .y) %>% pull(reference)
         )
  )
# Import binary rate ratios
comorbidities_binary_vctr <-
  config$comorbidities[!config$comorbidities %in% comorbidities_multilevel_vctr]
binary_ratios <- 
  map(.x = comorbidities_binary_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "ratios",
                                  paste0(.x,".csv")),
                      col_types = cols("D", "f", "f", "d", "d", "d")))
names(binary_ratios) = comorbidities_binary_vctr

# Plot rates ---
## Plot rates for sex:
sex_plot <- 
  sex_ratios %>%
  plot_ratios(., 
             x = "date", 
             y = "srr",
             ci_lo = "srr_ci_lo",
             ci_up = "srr_ci_up",
             subgroup = "sex",
             reference = "F") +
  scale_colour_discrete(name  ="Sex",
                        labels = c("Male"))
## Multilevel variables
## Make a grid with multilevel variables combined with "F" and
## "M", needed since for every demographic/comorb variable we need a plot for 
## sex equal to "F" and "M".
multilevel_plots_grid <- 
  expand_grid(subgroups = multilevel_vctr,
              sex = c("F", "M"))
multilevel_plots <- 
  map2(.x = multilevel_plots_grid$subgroups,
       .y = multilevel_plots_grid$sex,
       .f = ~ multilevel_ratios[[which(multilevel_vctr == .x)]] %>% 
         filter(sex == .y) %>%
         plot_ratios(
           x = "date",
           y = "srr",
           ci_lo = "srr_ci_lo",
           ci_up = "srr_ci_up",
           group = .x,
           subgroup = .x,
           reference = .$reference[1]
         ) +
         scale_colour_discrete(name = .x) +
         ggtitle(label = ifelse(.y == "M", "Male", "Female")))
# Name list
multilevel_plots_names <- 
  paste0(multilevel_plots_grid$subgroups, 
         "_",
         multilevel_plots_grid$sex)
names(multilevel_plots) <- multilevel_plots_names # used in iwalk as .y
## Binary variables
binary_plots <- 
  imap(.x = binary_ratios,
       .f = ~ plot_ratios(.,
                          x = "date",
                          y = "srr",
                          ci_lo = "srr_ci_lo",
                          ci_up = "srr_ci_up",
                          group = "sex",
                          subgroup = .y,
                          reference = "0") +
             scale_colour_discrete(name = "Sex") +
             ggtitle(label = .y))

# Save plots ---
## Plots are saved in ./output/figures/rates_subgroups
output_dir <- here("output", "figures", "ratios_subgroups")
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
iwalk(.x = c(multilevel_plots,
             binary_plots),
      .f = ~ ggsave(filename = paste0(output_dir, "/", .y, ".png"),
                    device = "png",
                    plot = .x))
