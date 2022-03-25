## ###########################################################

##  This script:
## - Contains a general function that is used for visualising the 
##   mortality rates

## linda.nab@thedatalab.com - 20220325
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(ggplot2)
library(lubridate)

## This function contains the common elements of a plot
plot_rates <- function(df, x, y, group = NULL, col = NULL){
  ## make sequence of dates for the y-axis
  dates <- 
    c("01-03-2020",
      "01-06-2020",
      "01-09-2020",
      "01-12-2020",
      "01-03-2021",
      "01-06-2021",
      "01-09-2021",
      "01-12-2021") %>%
    as_date(., format = "%d-%m-%Y")
  plot <- 
    ggplot(df, aes_string(x, y, group = group, col = col)) +
    geom_point() + 
    geom_line() +
    theme_minimal() +
    theme(panel.grid.minor.x = element_blank()) +
    scale_x_date(name = "Calendar Month",
                 breaks = dates,
                 date_labels = "%b-%y") +
    scale_y_continuous(name = "Standardised Risk per 100,000 Individuals")
  plot
}