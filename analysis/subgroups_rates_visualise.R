## ###########################################################

##  This script:
## - Imports the standardised rates
## - Makes plots over time

## linda.nab@thedatalab.com - 20220323
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(tidyr)
library(lubridate)
library(jsonlite)
library(ggplot2)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))

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
                          col_types = cols_only(date = col_date(),
                                                sex = col_factor(),
                                                value_std = col_double()))
# Import the rest of the mortality rates:
subgroups_vctr <- c(config$demographics, config$comorbidities)
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  paste0(.x,"_monthly_std.csv")),
                      col_types = cols_only(date = col_date(), 
                                            sex = col_factor(),
                                            !!.x := col_factor(), 
                                            value_std = col_double())))

# Plot rates ---
## Plot rates for sex:
sex_plot <- 
  sex_rates_std %>%
    ggplot(., aes(date, value_std, group = sex, col = sex)) + 
      geom_point() +
      geom_line() + 
      theme_minimal() +
      theme(panel.grid.minor.x = element_blank()) +
      scale_x_date(name = "Calendar Month",
                   breaks = c(my("03-2020"),
                              my("06-2020"),
                              my("09-2020"),
                              my("12-2020"),
                              my("03-2021"),
                              my("06-2021"),
                              my("09-2021"),
                              my("12-2021")),
                   date_labels = "%b-%y") +
      scale_y_continuous(name = "Standardised Risk per 100,000 Individuals") +
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
         .f = ~ subgroups_rates_std[[which(subgroups_vctr == .x)]] %>% filter(sex == .y) %>%
                  ggplot(., aes(date, value_std, group = get(.x), col = get(.x))) + 
                  geom_point() + 
                  geom_line() +
                  theme_minimal() +
                  theme(panel.grid.minor.x = element_blank()) +
                  scale_x_date(name = "Calendar Month",
                               breaks = c(my("03-2020"),
                                          my("06-2020"),
                                          my("09-2020"),
                                          my("12-2020"),
                                          my("03-2021"),
                                          my("06-2021"),
                                          my("09-2021"),
                                          my("12-2021")),
                               date_labels = "%b-%y") +
                  scale_y_continuous(name = "Standardised Risk per 100,000 Individuals"))

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
ggsave(filename = here(output_dir, "sex.png"),
       device = "png",
       plot = sex_plot)
## Save the remaining plots
file_names <- paste0(here(output_dir, 
                          paste0(subgroups_plots_grid$subgroups,
                                 "_", 
                                 subgroups_plots_grid$sex, 
                                 ".png")))
names(subgroups_plots) <- file_names
iwalk(.x = subgroups_plots,
      .f = ~ ggsave(filename = .y,
                    device = "png",
                    plot = .x))
