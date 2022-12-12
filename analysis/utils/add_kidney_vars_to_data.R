## ###########################################################

##  This script:
## - Contains a function that adds vars 'egfr' and 'ckd_rrt' to the extracted
## data.frame

## linda.nab@thedatalab.com - 20220527
## ###########################################################

# Load libraries & functions ---
library(dplyr)
source(here("analysis", "utils", "kidney_functions.R"))

# Function --
## Arguments:
## data_extracted: data.frame with columns creatinine, creatinine_operator,
## sex and creatinine_age
## Output:
## data_extracted with 2 extra columns: 'egfr' and 'ckd_rrt'
add_kidney_vars_to_data <- function(data_extracted){
  data_extracted <- 
    data_extracted %>%
    mutate(SCR_adj = creatinine / 88.4) %>% # divide by 88.4 (to convert umol/l to mg/dl))
    add_min_creatinine() %>%
    add_max_creatinine() %>%
    add_egfr() %>%
    categorise_ckd_rrt()
}