## ###########################################################

##  This script:
## - Calculates the first 3 quantiles of the vax end & start doses

## linda.nab@thedatalab.com - 20221214
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(tibble)

vax_q <- function(data){
  data %>%
    summarise(start_m = quantile(doses_no_start, probs = 0.5),
              start_q1 = quantile(doses_no_start, probs = 0.25),
              start_q3 = quantile(doses_no_start, probs = 0.75),
              end_m = quantile(doses_no_end, probs = 0.5),
              end_q1 = quantile(doses_no_end, probs = 0.25),
              end_q3 = quantile(doses_no_end, probs = 0.75))
}

vax_q_subgroup <- function(data, subgroup){
  data <-
    data %>%
    group_by(across(all_of(subgroup))) %>% 
    vax_q() %>%
    add_column(subgroup = !!subgroup, .before = 1)
  colnames(data)[colnames(data) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  data <- data %>% mutate(level = as.factor(level))
  data
}

vax_q_all_subgroups <- function(data, subgroups){
  map(.x = subgroups,
      .f = ~ vax_q_subgroup(data, .x)) %>%
    bind_rows()
}
