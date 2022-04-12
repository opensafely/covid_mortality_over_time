## ###########################################################

##  This script:
## - Contains functions used to plot KM curves of the age group
##   of each of the waves

## linda.nab@thedatalab.com - 20220412
## ###########################################################

# Load libraries & functions ---
library(purrr)
library(dplyr)
library(survival)
library(survminer)

# Kaplan-Meiers
# Function 'km_fit()' used to fit survival function for each agegroup, 
# seperately for Males and Females
# arguments:
# - data: data.frame with extracted data of one of the pandemic waves
# output:
# named list with survfit object 'Female': KM for each agegroup in data for 
# sex == 'Female' and object 'Male' = KM for each agegroup in data for
# sex == 'Male'
km_fit <- function(data){
  sfit_f <- survfit(Surv(fu, died_ons_covid_flag_any) ~ agegroup,
                    data = data %>% filter(sex == "Female"))
  sfit_m <- survfit(Surv(fu, died_ons_covid_flag_any) ~ agegroup,
                    data = data %>% filter(sex == "Male"))
  # names later used for plot title
  out <- list(Females = sfit_f, 
              Males = sfit_m)
  return(out)
}
# Function 'make_title()' used to add a title to a KM plot denoting the start
# and end date of the pandemic wave
# arguments:
# - wave: string, "wave1", "wave2" or "wave3"
# output:
# string "wave 'wave': start_date - end_date"
make_title <- function(wave){
  number_of_wave <- substr(wave, 5, 5)
  title <- 
    paste0("wave ",
           number_of_wave,
           ": ",
           config[[wave]]$start_date,
           " - ",
           config[[wave]]$end_date
    )
  title
}
# Function 'km_plot()' used to plot cum inc function of the output from 'km_fit' 
# arguments:
# - sfit_list: list with 2 fitted survfit objects, one called 'Female' and one 
#   called 'Male'
# - data: data.frame used in survfit to calculate cum inc
# - wave: string, "wave1", "wave2" or "wave3"
# output:
# list with two plots visualising the cum inc, one called 'Female' and one 
# 'Male'
km_plot <- function(sfit_list, data, wave){
  plot_list <-
    imap(
      .x = sfit_list[[wave]],
      .f = ~ ggsurvplot(
        .x,
        data = data[[wave]],
        fun = "event",# 1 - y
        conf.int = TRUE,
        ylab = "Cumulative Probability of COVID-19 Related Death",
        xlab = "Time (days)",
        title = paste0(.y, ", ", make_title(wave))
      ) 
    )
  plot_list
}
