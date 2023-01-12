## ###########################################################

##  This script:
## - Counts number of people in each dose

## linda.nab@thedatalab.com - 20220105
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(tibble)

vax_counts <- function(data){
  data %>%
    summarise(n = n(),
              start_0 = sum(doses_no_start == 0),
              start_1 = sum(doses_no_start == 1),
              start_2 = sum(doses_no_start == 2),
              start_3 = sum(doses_no_start == 3),
              start_4 = sum(doses_no_start == 4),
              start_5 = sum(doses_no_start == 5),
              end_0 = sum(doses_no_end == 0),
              end_1 = sum(doses_no_end == 1),
              end_2 = sum(doses_no_end == 2),
              end_3 = sum(doses_no_end == 3),
              end_4 = sum(doses_no_end == 4),
              end_5 = sum(doses_no_end == 5)) %>%
    mutate(across(where(is.integer),
                  ~ case_when(. <= 7 ~ "[REDACTED]",
                              TRUE ~ plyr::round_any(., 5) %>% as.character()))
    )
}

vax_counts_subgroup <- function(data, subgroup){
  data <-
    data %>%
    group_by(across(subgroup)) %>% 
    vax_counts() %>%
    add_column(subgroup = !!subgroup, .before = 1)
  colnames(data)[colnames(data) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  data <- data %>% mutate(level = as.factor(level))
  data
}

vax_counts_all_subgroups <- function(data, subgroups){
  map(.x = subgroups,
      .f = ~ vax_counts_subgroup(data, .x)) %>%
    bind_rows()
}
