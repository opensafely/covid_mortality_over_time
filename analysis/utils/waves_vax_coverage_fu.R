## ###########################################################

##  This script:
## - Counts and follow up time to estimate vaccination fu

## linda.nab@thedatalab.com - 20220105
## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(tibble)

vax_fu <- function(data){
  data %>%
    summarise(fu = sum(fu),
              fu_0 = sum(fu_vax_0),
              fu_1 = sum(fu_vax_1),
              fu_2 = sum(fu_vax_2),
              fu_3 = sum(fu_vax_3),
              fu_4 = sum(fu_vax_4),
              fu_5 = sum(fu_vax_5)) %>%
    mutate(across(where(is.double),
                  ~ case_when(. > 0 & . <= 7 ~ "[REDACTED]",
                              TRUE ~ plyr::round_any(., 5) %>% as.character()))
    )
}

vax_fu_subgroup <- function(data, subgroup){
  data <-
    data %>%
    group_by(across(subgroup)) %>% 
    vax_fu() %>%
    add_column(subgroup = !!subgroup, .before = 1)
  colnames(data)[colnames(data) == subgroup] <- "level"
  # make col type of column 'level' factor (needed to bind_rows later)
  data <- data %>% mutate(level = as.factor(level))
  data
}

vax_fu_all_subgroups <- function(data, subgroups){
  map(.x = subgroups,
      .f = ~ vax_fu_subgroup(data, .x)) %>%
    bind_rows()
}
