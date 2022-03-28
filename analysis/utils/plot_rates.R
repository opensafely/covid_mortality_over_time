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

## This function contains the common elements of a plot visualising standardised
## mortality rates over time, optionally for different levels of a variable
## Arguments:
## df: data.frame containing columns 'x' and 'y' (and optionally, 'group')
## x: string of the name of the column in df that contains dates 
## (column type in df: date)
## y: string of the name of the column if df that contains the standardised 
## mortality rates per 100.000 people (column type in df: double)
## group: optional argument, string of the name of the column in df reflecting 
## different levels of a demographic variable or comorbidity 
## (column type in df: factor)
plot_rates <- function(df, x, y, group = NULL){
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
    ggplot(df, aes_string(x, y, group = group, col = group)) +
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