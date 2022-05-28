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
    rowwise() %>%
    mutate(egfr = calc_egfr(creatinine, 
                            creatinine_operator,
                            creatinine_age,
                            sex), 
           ckd_rrt = categorise_ckd_rrt(egfr,
                                        rrt_cat)) %>%
    ungroup()
}