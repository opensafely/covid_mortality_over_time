## ###########################################################

##  This script:
## - Contains a general function that is used for visualising the 
##   rate ratios

## linda.nab@thedatalab.com - 20220325
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(ggplot2)
library(lubridate)

## This function contains the common elements of a plot visualising standardised
## mortality rates over time, optionally for different levels of a variable
## Arguments:
## - df: data.frame containing columns 'x' and 'y' (and optionally, 'group')
## - x: string of the name of the column in df that contains dates 
## (column type in df: date)
## - y: string of the name of the column in df that contains the standardised 
## mortality rates per 100.000 people (column type in df: double)
## - ci_lo: string of the name of the column in df that contains the lower ci's
## - ci_up: string of the name of the column in df that contains the upper ci's
## - group: optional argument, string of the name of the column in df reflecting 
## different levels of a demographic variable or comorbidity 
## (column type in df: factor)
plot_ratios <-
  function(df,
           x,
           y,
           ci_lo = NULL,
           ci_up = NULL,
           group = NULL,
           subgroup = NA,
           reference = NA) {
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
  df <-
    df %>% filter(get(y) != 0 & get(ci_lo) != 0 & get(ci_up) != 0)
  if (!is.na(subgroup) & !is.na(reference)) {
    df <- 
      df %>% filter(get(!!subgroup) != reference)
  }
  plot <- 
    ggplot(df, aes_string(x, y, group = group, col = group)) +
    geom_point() + 
    geom_line() +
    theme_minimal() +
    theme(panel.grid.minor.x = element_blank()) +
    scale_x_date(name = "Calendar Month",
                 breaks = dates,
                 date_labels = "%b-%y") +
    scale_y_continuous(name = "Ratio of Standardised Risk per 100,000 Individuals (log-scale)",
                       trans = "log10")
  if (!is.null(ci_lo) & !is.null(ci_up)){ # add CIs if boundaries provided
    plot <- 
      plot +
      geom_ribbon(data = df, 
                  mapping = aes_string(ymin = ci_lo, ymax = ci_up),
                  alpha = 0.1,
                  linetype = 0)
  }
  plot
}
