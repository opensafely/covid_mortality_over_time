## ###########################################################

##  This script:
## - Function to calculate incidence rate per 1000 person-years
## - Function to calculate ir for one subgroup in wave
## - Function to calculate ir for all subgroups in wave

## linda.nab@thedatalab.com - 20220615
## ###########################################################
library(dplyr)
library(tibble)

# Function 'calc_ir' calculation of incidence rate per 1000 py + 95% CIs
# Arguments:
# events: integer with number of events (e.g. number of deaths in wave)
# time: follow up in days
# Output:
# data.frame with columns rate, lower and upper 
calc_ir <- function(events, time, name = ""){
  time_per_1000_py <- time / 365250
  htest <- poisson.test(events, time_per_1000_py)
  rate <- unname(htest$estimate)
  lower <- unname(htest$conf.int[1])
  upper <- unname(htest$conf.int[2])
  out <- data.frame(rate = rate, 
                    lower = lower, 
                    upper = upper)
  colnames(out) <- paste0(colnames(out), name)
  out
}

# Function 'calc_ir_for_subgroup'
# Arguments:
# data: data.frame with subgroup in column, died_ons_covid_flag_any and fu
# (usually input_wave*.csv)
# subgroup: character of subgroup for which ir is to be calculated
# Output:
# data.frame with columns (for one subgroup):
# subgroup level events time rate lower upper
calc_ir_for_subgroup <- function(data, subgroup){
  ir <-
    data %>%
    group_by_at(all_of(subgroup)) %>%
    summarise(
      events = sum(died_ons_covid_flag_any),
      time = sum(as.numeric(fu)),
      calc_ir(events, time),
      events_redacted = case_when(events <= 5 ~ 0, 
                                  TRUE ~ plyr::round_any(events, 5)),
      time_redacted = plyr::round_any(time, 5),
      calc_ir(events_redacted, time_redacted, "_redacted")
    ) %>%
    add_column(subgroup = !!subgroup, .before=1)
  colnames(ir)[colnames(ir) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  ir <- 
    ir %>%
    mutate(level = as.factor(level))
  ir
}

# Function 'calc_ir_for_all_subgroups' applies function 'calc_ir_for_subgroup'
# on each subgroup in subgroups
# Arguments:
# # data: data.frame with subgroup in column, died_ons_covid_flag_any and fu
# (usually input_wave*.csv)
# subgroups: vector with characters for all subgroups c("sex", "ethnicity", ...)
# Output:
# data.frame with columns (for all subgroups)
# subgroup level events time rate lower upper
calc_ir_for_all_subgroups <- function(data, subgroups){
  map(.x = subgroups,
      .f = ~ calc_ir_for_subgroup(data, .x)) %>%
    bind_rows()
}