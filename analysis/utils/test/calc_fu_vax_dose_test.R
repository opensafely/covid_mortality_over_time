library(here)
library(lubridate)
# Test for calc_fu_vax_dose
source(here("analysis", "utils", "calc_fu_vax_dose.R"))

start_date_wave <- ymd("20200901")
data <- 
  tibble(
    covid_vax_date_0 = ymd("20200901"),
    covid_vax_date_1 = covid_vax_date_0 + days(42),
    covid_vax_date_2 = covid_vax_date_1 + days(42),
    covid_vax_date_3 = covid_vax_date_2 + days(42),
    covid_vax_date_4 = covid_vax_date_3 + days(42),
    covid_vax_date_5 = covid_vax_date_4 + days(42),
    covid_vax_date_6 = covid_vax_date_5 + days(42),
    died_any_date = ymd("20200901") + days(30),
    fu = 30) %>%
  mutate(
    start_vax_dose_1 = covid_vax_date_1 + days(14),
    start_vax_dose_2 = covid_vax_date_2 + days(14),
    start_vax_dose_3 = covid_vax_date_3 + days(14),
    start_vax_dose_4 = covid_vax_date_4 + days(14),
    start_vax_dose_5 = covid_vax_date_5 + days(14),
    start_vax_dose_6 = covid_vax_date_6 + days(14),
    # follow-up of dose in this wave?
    ind_fu_vax_1 = between(start_vax_dose_1, start_date_wave, died_any_date),
    ind_fu_vax_2 = between(start_vax_dose_2, start_date_wave, died_any_date),
    ind_fu_vax_3 = between(start_vax_dose_3, start_date_wave, died_any_date),
    ind_fu_vax_4 = between(start_vax_dose_4, start_date_wave, died_any_date),
    ind_fu_vax_5 = between(start_vax_dose_5, start_date_wave, died_any_date),
    ind_fu_vax_6 = between(start_vax_dose_6, start_date_wave, died_any_date),
    # vax status start and end
    vax_status_start_1 = ifelse(start_vax_dose_1 <= start_date_wave, 1, 0),
    vax_status_start_2 = ifelse(start_vax_dose_2 <= start_date_wave, 1, 0),
    vax_status_start_3 = ifelse(start_vax_dose_3 <= start_date_wave, 1, 0),
    vax_status_start_4 = ifelse(start_vax_dose_4 <= start_date_wave, 1, 0),
    vax_status_start_5 = ifelse(start_vax_dose_5 <= start_date_wave, 1, 0),
    vax_status_start_6 = ifelse(start_vax_dose_6 <= start_date_wave, 1, 0),
    vax_status_end_1 = ifelse(start_vax_dose_1 <= died_any_date, 1, 0),
    vax_status_end_2 = ifelse(start_vax_dose_2 <= died_any_date, 1, 0),
    vax_status_end_3 = ifelse(start_vax_dose_3 <= died_any_date, 1, 0),
    vax_status_end_4 = ifelse(start_vax_dose_4 <= died_any_date, 1, 0),
    vax_status_end_5 = ifelse(start_vax_dose_5 <= died_any_date, 1, 0),
    vax_status_end_6 = ifelse(start_vax_dose_6 <= died_any_date, 1, 0)) %>%
  mutate(doses_no_start = rowSums(select(., starts_with("vax_status_start_"))),
         doses_no_end = rowSums(select(., starts_with("vax_status_end_"))))
data %>%
  calc_fu_vax_dose() 
data %>% View()
