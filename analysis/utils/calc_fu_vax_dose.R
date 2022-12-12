# Load libraries & functions ---
library(dplyr)
library(here)
# Function fct_case_when needed inside process_data
source(here("analysis", "utils", "fct_case_when.R"))

# function that adds follow-up to data
# arguments:
# - data: extracted data
# output:
# - data.frame with variables fu_vax_* added
calc_fu_vax_dose <- function(data){
  data <-
    data %>%
    mutate(
      fu_vax_0 = case_when(!any(ind_fu_vax_1, ind_fu_vax_2, ind_fu_vax_3, ind_fu_vax_4, ind_fu_vax_5, ind_fu_vax_6) ~ fu,
                           ind_fu_vax_1 == TRUE ~ difftime(start_vax_dose_1, start_date_wave, "days") %>% as.numeric(),
                           TRUE ~ 0),
      fu_vax_1 = case_when(ind_fu_vax_1 == FALSE ~ 0,
                           ind_fu_vax_2 == FALSE ~ fu - fu_vax_0,
                           TRUE ~ difftime(start_vax_dose_2, start_vax_dose_1, "days") %>% as.numeric()),
      fu_vax_2 = case_when(ind_fu_vax_2 == FALSE ~ 0,
                           ind_fu_vax_3 == FALSE ~ fu - fu_vax_1 - fu_vax_0,
                           TRUE ~ difftime(start_vax_dose_3, start_vax_dose_2, "days") %>% as.numeric()),
      fu_vax_3 = case_when(ind_fu_vax_3 == FALSE ~ 0,
                           ind_fu_vax_4 == FALSE ~ fu - fu_vax_2 - fu_vax_1 - fu_vax_0,
                           TRUE ~ difftime(start_vax_dose_4, start_vax_dose_3, "days") %>% as.numeric()),
      fu_vax_4 = case_when(ind_fu_vax_4 == FALSE ~ 0,
                           ind_fu_vax_5 == FALSE ~ fu - fu_vax_3 - fu_vax_2 - fu_vax_1 - fu_vax_0,
                           TRUE ~ difftime(start_vax_dose_5, start_vax_dose_4, "days") %>% as.numeric()),
      fu_vax_5 = case_when(ind_fu_vax_5 == FALSE ~ 0,
                           ind_fu_vax_6 == FALSE ~ fu - fu_vax_4 - fu_vax_3 - fu_vax_2 - fu_vax_1 - fu_vax_0,
                           TRUE ~ difftime(start_vax_dose_6, start_vax_dose_5, "days") %>% as.numeric()),
      fu_vax_6 = case_when(ind_fu_vax_6 == FALSE ~ 0,
                           TRUE ~ difftime(died_any_date, start_vax_dose_6, "days") %>% as.numeric())
    )
}


