## ###########################################################

##  This script:
## - Imports data of the three waves
## - Makes 'table 1' (description of demographics / comorbidities)

## linda.nab@thedatalab.com - 20220304
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(gtsummary)
library(gt)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
demographics <- config$demographics
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
# labels in table
labels <- list(
  agegroup ~ "Age Group",
  sex ~ "Sex",
  bmi ~ "Body Mass Index",
  ethnicity ~ "Ethnicity",
  smoking_status_comb ~ "Smoking status",
  imd ~ "IMD quintile",
  region ~ "Region",
  chronic_respiratory_disease ~ "Chronic respiratory disease",
  asthma ~ "Asthma",
  bp_ht ~ "High blood pressure or diagnosed hypertension",
  chronic_cardiac_disease ~ "Chronic cardiac disease",
  diabetes_controlled ~ "Diabetes",
  cancer ~ "Cancer (non haematological)",
  haem_cancer ~ "Haematological malignancy",
  ckd_rrt ~ "Chronic kidney disease or renal replacement therapy",
  chronic_liver_disease ~ "Chronic liver disease",
  stroke ~ "Stroke",
  dementia ~ "Dementia",
  other_neuro ~ "Other neurological disease",
  organ_kidney_transplant ~ "Organ transplant",
  asplenia ~ "Asplenia",
  ra_sle_psoriasis ~ "Rheumatoid arthritis/ lupus/ psoriasis",
  immunosuppression ~ "Immunosuppressive condition",
  learning_disability ~ "Learning disability",
  sev_mental_ill ~ "Severe mental illness"
)
# make in long format 
data_waves <- 
  data_processed %>%
  bind_rows(.id = "wave") %>%
  mutate(wave = wave %>% as.factor())
# select data needed in table
data_waves_list <- 
  map(
    .x = c("1", "2", "3"),
    .f = ~ data_waves %>%
      select(
        wave,
        agegroup,
        sex,
        all_of(demographics),
        all_of(comorbidities),
        died_ons_covid_flag_any
      ) %>%
      filter(wave == .x) %>%
      select(-wave)
  )
# table has a column 'number of covid-19 related deaths (stratum %)
# make a list of tables stratified by death --> results in a 
# FALSE and TRUE column with row percentages (percent = "row")
table_deaths_list <-
  map(
    .x = data_waves_list,
    .f = ~ tbl_summary(
      .x,
      by = died_ons_covid_flag_any,
      label = labels,
      percent = "row", 
      digits = list(everything() ~ c(0, 3))
    )
  )
# table has a column 'number of individuals (column %) with the overall
# number of individuals in each wave --> needs column percent so therefore
# this is not added to the former tabel with add_overall() as add_overall 
# would then take row percentages and we'd like column percentages here
table_overall_list <-
  map(
    .x = data_waves_list,
    .f = ~ tbl_summary(
      .x,
      label = labels,
      percent = "column", 
      include = c(-"died_ons_covid_flag_any"),
      digits = list(everything() ~ c(0, 1))
    )
  )
# merge two list of tables --> output is a list with 3 tables with a overall 
# column and TRUE FALSE for death column
table1_list <- 
  map2(.x = table_deaths_list,
       .y = table_overall_list,
       .f = ~ tbl_merge(list(.y, .x)) %>%
         modify_spanning_header(everything() ~ NA))
# merge all 3 tables (now 1 table with for each wave 3 colmns)
table1 <-
  tbl_merge(table1_list,
            tab_spanner = c(
              paste0("**Wave 1**, N = ", table_overall_list[[1]]$N),
              paste0("**Wave 2**, N = ", table_overall_list[[2]]$N),
              paste0("**Wave 3**, N = ", table_overall_list[[3]]$N)
            ))
# number of deaths in waves --> used in table header for overall column
n_deaths <- map(.x = data_processed,
                .f = ~ .x %>% 
                  filter(died_ons_covid_flag_any == TRUE) %>%
                  nrow())
## Reference in multicategorical variables are omitted
## + 'FALSE' column of deaths is hidden
table1 <- 
  table1 %>% 
  modify_table_body(
    filter,
    !(variable == "asthma" &
        label == "No asthma") &
      !(variable == "diabetes_controlled" &
          label == "No diabetes") &
      !(variable == "ckd_rrt" &
          label == "No CKD or RRT") &
      !(variable == "organ_kidney_transplant" &
          label == "No transplant")) %>%
  modify_column_hide(column = c(stat_1_2_1, stat_1_2_2, stat_1_2_3)) %>%
  modify_header(stat_2_2_1 = paste0("**Number of COVID-19 related deaths (stratum %)**, N = ", n_deaths[[1]]),
                stat_2_2_2 = paste0("**Number of COVID-19 related deaths (stratum %)**, N = ", n_deaths[[2]]),
                stat_2_2_3 = paste0("**Number of COVID-19 related deaths (stratum %)**, N = ", n_deaths[[3]]),
                stat_0_1_1 = paste0("**Number of individuals (column %)**"),
                stat_0_1_2 = paste0("**Number of individuals (column %)**"),
                stat_0_1_3 = paste0("**Number of individuals (column %)**")) %>%
  modify_footnote(everything() ~ NA)

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(table1$table_body %>%
            select(c(var_label,
                     label,
                     stat_0_1_1,
                     stat_2_2_1,
                     stat_0_1_2,
                     stat_2_2_2,
                     stat_0_1_3,
                     stat_2_2_3)), paste0(output_dir, "/table1.csv"))
gtsave(table1 %>% as_gt(), paste0(output_dir, "/table1.html"))
