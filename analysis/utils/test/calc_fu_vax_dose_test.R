library(here)
library(lubridate)
# Test for calc_fu_vax_dose
source(here("analysis", "utils", "calc_fu_vax_dose.R"))

data <- 
  tibble(
    start_date_wave = ymd("20200901"),
    covid_vax_date_1 = start_date_wave + days(42),
    covid_vax_date_2 = covid_vax_date_1 + days(42),
    covid_vax_date_3 = covid_vax_date_2 + days(42),
    covid_vax_date_4 = covid_vax_date_3 + days(42),
    covid_vax_date_5 = covid_vax_date_4 + days(42),
    covid_vax_date_6 = covid_vax_date_5 + days(42),
    died_any_date = ymd("20200901") + days(200),
    fu = 200) %>%
  mutate(
    # add time lag
    start_vax_dose_1 = covid_vax_date_1 + days(14),
    start_vax_dose_2 = covid_vax_date_2 + days(14),
    start_vax_dose_3 = covid_vax_date_3 + days(14),
    start_vax_dose_4 = covid_vax_date_4 + days(14),
    start_vax_dose_5 = covid_vax_date_5 + days(14),
    start_vax_dose_6 = covid_vax_date_6 + days(14),
    # follow-up of dose in this wave?
    ind_fu_vax_1 = case_when(
      !is.na(start_vax_dose_1) ~
        between_vectorised(start_vax_dose_1, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    ind_fu_vax_2 = case_when(
      !is.na(start_vax_dose_2) ~
        between_vectorised(start_vax_dose_2, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    ind_fu_vax_3 = case_when(
      !is.na(start_vax_dose_3) ~
        between_vectorised(start_vax_dose_3, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    ind_fu_vax_4 = case_when(
      !is.na(start_vax_dose_4) ~
        between_vectorised(start_vax_dose_4, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    ind_fu_vax_5 = case_when(
      !is.na(start_vax_dose_5) ~
        between_vectorised(start_vax_dose_5, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    ind_fu_vax_6 = case_when(
      !is.na(start_vax_dose_6) ~
        between_vectorised(start_vax_dose_6, start_date_wave, start_date_wave + days(fu)),
      TRUE ~ FALSE),
    # vax status start and end
    vax_status_start_1 = if_else(!is.na(start_vax_dose_1) & start_vax_dose_1 <= start_date_wave, 1, 0),
    vax_status_start_2 = if_else(!is.na(start_vax_dose_2) & start_vax_dose_2 <= start_date_wave, 1, 0),
    vax_status_start_3 = if_else(!is.na(start_vax_dose_3) & start_vax_dose_3 <= start_date_wave, 1, 0),
    vax_status_start_4 = if_else(!is.na(start_vax_dose_4) & start_vax_dose_4 <= start_date_wave, 1, 0),
    vax_status_start_5 = if_else(!is.na(start_vax_dose_5) & start_vax_dose_5 <= start_date_wave, 1, 0),
    vax_status_start_6 = if_else(!is.na(start_vax_dose_6) & start_vax_dose_6 <= start_date_wave, 1, 0),
    vax_status_end_1 = if_else(!is.na(start_vax_dose_1) & start_vax_dose_1 <= start_date_wave + fu, 1, 0),
    vax_status_end_2 = if_else(!is.na(start_vax_dose_2) & start_vax_dose_2 <= start_date_wave + fu, 1, 0),
    vax_status_end_3 = if_else(!is.na(start_vax_dose_3) & start_vax_dose_3 <= start_date_wave + fu, 1, 0),
    vax_status_end_4 = if_else(!is.na(start_vax_dose_4) & start_vax_dose_4 <= start_date_wave + fu, 1, 0),
    vax_status_end_5 = if_else(!is.na(start_vax_dose_5) & start_vax_dose_5 <= start_date_wave + fu, 1, 0),
    vax_status_end_6 = if_else(!is.na(start_vax_dose_6) & start_vax_dose_6 <= start_date_wave + fu, 1, 0)) %>%
  mutate(doses_no_start = rowSums(select(., starts_with("vax_status_start_"))),
         doses_no_end = rowSums(select(., starts_with("vax_status_end_"))))
data <- 
  data %>%
  calc_fu_vax_dose() 
data %>% View()
