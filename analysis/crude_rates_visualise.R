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
library(tidyr)
library(lubridate)
library(jsonlite)

# Import rates ---
crude_rates <- 
  read_csv(file = here("output", "rates", "crude_monthly_std.csv"),
           col_types = cols_only(date = col_date(),
                                 std_value = col_double()))
crude_rates_per_agegroup <-
  read_csv(file = here("output", "rates", "crude_per_agegroup_monthly_std.csv"),
           col_types = cols_only(date = col_date(),
                                 sex = col_factor(),
                                 agegroup = col_factor(),
                                 std_value = col_double()))

# Plot rates ---
## Plot crude rates
crude_plot <- 
  crude_rates %>%
  ggplot(., aes(date, std_value)) + 
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
  scale_y_continuous(name = "Standardised Risk per 100,000 Individuals")
## Plot crude rates per age group (seperate plot per sex)
crude_agroup_plots <- 
  map(.x = c("F", "M"),
      .f = ~ crude_rates_per_agegroup %>% 
               filter(sex == .x) %>%
               ggplot(., aes(date, std_value, group = agegroup, col = agegroup)) + 
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
## Plots are saved in ./output/figures/rates_crude
output_dir <- here("output", "figures", "rates_crude")
ifelse(!dir.exists(here("output", "figures")), 
       dir.create(here("output", "figures")), 
       FALSE) # create ./output/figures if not already there
ifelse(!dir.exists(output_dir), 
       dir.create(output_dir), 
       FALSE)
## Save sex plot
ggsave(filename = here(output_dir, "crude.png"),
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
