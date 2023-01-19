library(here)
library(lubridate)
# Test for calc_fu_vax_dose
source(here("analysis", "utils", "calc_fu_vax_dose.R"))
source(here("analysis", "utils", "between_vectorised.R"))

data <- 
  tibble(
    start_date_wave = c(ymd("20200901"),
                        ymd("20210601"),
                        ymd("20210101"),
                        ymd("20200401")),
    covid_vax_date_1 = c(start_date_wave[1] + days(42), 
                         start_date_wave[2] - days(200),
                         start_date_wave[3] - days(50),
                         NA_Date_),
    covid_vax_date_2 = c(covid_vax_date_1[1] + days(42),
                         start_date_wave[2] - days(150),
                         start_date_wave[3] - days(20),
                         NA_Date_),
    covid_vax_date_3 = c(covid_vax_date_2[1] + days(42),
                         start_date_wave[2] - days(100),
                         NA_Date_, 
                         NA_Date_),
    covid_vax_date_4 = c(covid_vax_date_3[1] + days(42),
                         start_date_wave[2] - days(50),
                         NA_Date_,
                         NA_Date_),
    covid_vax_date_5 = c(covid_vax_date_4[1] + days(42),
                         start_date_wave[2] - days(30),
                         NA_Date_,
                         NA_Date_),
    covid_vax_date_6 = c(covid_vax_date_5[1] + days(42),
                         start_date_wave[2] - days(10),
                         NA_Date_,
                         NA_Date_),
    died_any_date = c(ymd("20200901") + days(200),
                      ymd("20210601") + days(100),
                      ymd("20210101") + days(100),
                      ymd("20200901")),
    fu = (died_any_date - start_date_wave) %>% as.numeric()) 

data <- 
  data %>%
  mutate(
    not_any_vax = !ind_fu_vax_1 & !ind_fu_vax_2 & !ind_fu_vax_3 & !ind_fu_vax_4 & !ind_fu_vax_5 & !ind_fu_vax_6, 
    # add time lag
    start_vax_dose_1 = covid_vax_date_1 + days(14),
    start_vax_dose_2 = covid_vax_date_2 + days(14),
    start_vax_dose_3 = covid_vax_date_3 + days(14),
    start_vax_dose_4 = covid_vax_date_4 + days(14),
    start_vax_dose_5 = covid_vax_date_5 + days(14),
    start_vax_dose_6 = covid_vax_date_6 + days(14),
    # follow-up of dose in this wave?
    ind_fu_vax_1 = case_when(
      # second dose not given before end of wave, then indicator is TRUE if the
      # start date of the first dose is before the end of follow up
      !is.na(start_vax_dose_1) & is.na(start_vax_dose_2) ~ 
        start_vax_dose_1 <= (start_date_wave + days(fu)),
      # second dose given before end of wave, then indicator is TRUE if start 
      # second dose is after start of wave 
      # AND start of first dose is before the end of follow up
      !is.na(start_vax_dose_1) & !is.na(start_vax_dose_2) ~
        (start_vax_dose_2 > start_date_wave) &
        (start_vax_dose_1 <= (start_date_wave + days(fu))),
      TRUE ~ FALSE),
    ind_fu_vax_2 =  case_when(
      # third dose not given before end of wave, then indicator is TRUE if the
      # start date of the second dose is before the end of follow up
      !is.na(start_vax_dose_2) & is.na(start_vax_dose_3) ~ 
        start_vax_dose_2 <= (start_date_wave + days(fu)),
      # third dose given before end of wave, then indicator is TRUE if start 
      # third dose is after start of wave
      # AND start of second dose is before the end of follow up
      !is.na(start_vax_dose_2) & !is.na(start_vax_dose_3) ~
        (start_vax_dose_3 > start_date_wave) &
        (start_vax_dose_2 <= (start_date_wave + days(fu))),
      TRUE ~ FALSE),
    ind_fu_vax_3 =  case_when(
      # fourth dose not given before end of wave, then indicator is TRUE if the
      # start date of the third dose is before the end of follow up
      !is.na(start_vax_dose_3) & is.na(start_vax_dose_4) ~ 
        start_vax_dose_3 <= (start_date_wave + days(fu)),
      # fourth dose given before end of wave, then indicator is TRUE if start 
      # fourth dose is after start of wave
      # AND start of third dose is before the end of follow up
      !is.na(start_vax_dose_3) & !is.na(start_vax_dose_4) ~
        (start_vax_dose_4 > start_date_wave) &
        (start_vax_dose_3 <= (start_date_wave + days(fu))),
      TRUE ~ FALSE),
    ind_fu_vax_4 =  case_when(
      # fifth dose not given before end of wave, then indicator is TRUE if the
      # start date of the fourth dose is before the end of follow up
      !is.na(start_vax_dose_4) & is.na(start_vax_dose_5) ~ 
        start_vax_dose_4 <= (start_date_wave + days(fu)),
      # fifth dose given before end of wave, then indicator is TRUE if start 
      # fifth dose is after start of wave
      # AND start of fourth dose is before the end of follow up
      !is.na(start_vax_dose_4) & !is.na(start_vax_dose_5) ~
        start_vax_dose_5 > start_date_wave &
        (start_vax_dose_4 <= (start_date_wave + days(fu))),
      TRUE ~ FALSE),
    ind_fu_vax_5 =  case_when(
      # sixth dose not given before end of wave, then indicator is TRUE if the
      # start date of the fifth dose is before the end of follow up
      !is.na(start_vax_dose_5) & is.na(start_vax_dose_6) ~ 
        start_vax_dose_5 <= (start_date_wave + days(fu)),
      # sixth dose given before end of wave, then indicator is TRUE if start 
      # sixth dose is after start of wave
      # AND start of fifth dose is before the end of follow up
      !is.na(start_vax_dose_5) & !is.na(start_vax_dose_6) ~
        start_vax_dose_6 > start_date_wave &
        (start_vax_dose_5 <= (start_date_wave + days(fu))),
      TRUE ~ FALSE),
    ind_fu_vax_6 =  case_when(
      !is.na(start_vax_dose_6) ~
        start_vax_dose_6 <= (start_date_wave + days(fu)),
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
