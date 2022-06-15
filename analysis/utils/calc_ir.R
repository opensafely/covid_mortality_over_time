## ###########################################################

##  This script:
## - Function to calculate incidence rate per 1000 person-years
## - Function to calculate ir for one subgroup in wave
## - Function to calculate ir for all subgroups in wave

## linda.nab@thedatalab.com - 20220615
## ###########################################################

# Function 'calc_ir' calculation of incidence rate per 1000 py + 95% CIs
# Arguments:
# events: integer with number of events (e.g. number of deaths in wave)
# time: follow up in days
# Output:
# data.frame with columns rate, lower and upper 
calc_ir <- function(events, time){
  time_per_1000_py <- time / 365.25 / 1000
  htest <- poisson.test(events, time_per_1000_py)
  rate <- unname(htest$estimate)
  lower <- unname(htest$conf.int[1])
  upper <- unname(htest$conf.int[2])
  out <- data.frame(rate = rate, lower = lower, upper = upper)
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
    group_by_at(vars(!!subgroup)) %>%
    summarise(
      events = sum(died_ons_covid_flag_any),
      time = sum(as.numeric(fu)),
      calc_ir(events, time)
    ) %>%
    mutate(subgroup = !!subgroup)
  colnames(ir)[colnames(ir) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  ir <- 
    ir %>%
    mutate(level = as.factor(level))
  ir <- ir[, c(7, 1, 2, 3, 4, 5, 6)]
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