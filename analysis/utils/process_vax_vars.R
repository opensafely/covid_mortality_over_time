## ###########################################################

##  This script:
## - Imports data of the five waves
## - Processes data as needed for vax analysis

## linda.nab@thedatalab.com - 20221214
## ###########################################################

# Load libraries & functions ---
library(dplyr)

# Helper functions ---
# As protocolised:
# Wave 2: 0 doses (start) 0, 1, 2 or 3 doses (end)
# Wave 3 Delta: 0, 1, 2, 3, 4 doses (start + end)
# Wave 3 Omicron: 0, 1, 2, 3, 4 doses ("wave4) (start + end)
# Wave 4: 0, 1, 2, 3, 4, 5 doses ("wave5") (start + end)
# Max in data is 6 for each wave. If more then theoretical maximum, group in max
max_doses <- function(data, max_start, max_end){
  data <- 
    data %>%
    mutate(
      doses_no_start = doses_no_start %>% as.numeric(),
      doses_no_end = doses_no_end %>% as.numeric(),
      doses_no_start = if_else(doses_no_start > max_start,
                               max_start,
                               doses_no_start),
      doses_no_end = if_else(doses_no_end > max_end,
                             max_end,
                             doses_no_end)
    )
}

# Functions used to process data of a specific wave ---
process_vax_data_wave2 <- function(data){
  data <- 
    data %>%
    max_doses(0, 3) %>%
    mutate(ind_fu_vax_3 = if_else(ind_fu_vax_4 |
                                    ind_fu_vax_5 |
                                    ind_fu_vax_6, TRUE, ind_fu_vax_3),
           ind_fu_vax_4 = FALSE,
           ind_fu_vax_5 = FALSE,
           ind_fu_vax_6 = FALSE,
           fu_vax_3 = fu_vax_3 + fu_vax_4 + fu_vax_5 + fu_vax_6,
           fu_vax_4 = 0,
           fu_vax_5 = 0,
           fu_vax_6 = 0)
}

process_vax_data_wave3 <- function(data){
  data <- 
    data %>%
    max_doses(., 4, 4) %>%
    mutate(ind_fu_vax_4 = if_else(ind_fu_vax_5|
                                    ind_fu_vax_6, TRUE, ind_fu_vax_4),
           ind_fu_vax_5 = FALSE,
           ind_fu_vax_6 = FALSE,
           fu_vax_4 = fu_vax_4 + fu_vax_5 + fu_vax_6,
           fu_vax_5 = 0,
           fu_vax_6 = 0)
}

process_vax_data_wave4_5 <- function(data){
  data <- 
    data %>%
    max_doses(., 5, 5) %>%
    mutate(ind_fu_vax_5 = if_else(ind_fu_vax_6, TRUE, ind_fu_vax_5),
           ind_fu_vax_6 = FALSE,
           fu_vax_5 = fu_vax_5 + fu_vax_6,
           fu_vax_6 = 0)
}
