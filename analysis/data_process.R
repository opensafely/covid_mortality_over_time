## ###########################################################

##  This script:
##  - Imports data extracted from the cohort extractor
##  - Standardises variables

## linda.nab@thedatalab.com - 2022024
## ###########################################################

# Load libraries & custom functions ---
library(here)
library(dplyr)
## Custom functions
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}

# Load data ---
# input_files <- 
#   Sys.glob(here("output", "input_202*.csv.gz"))
# data_extracted <- 
#   map(.x = input_files,
#       .f = ~ read_csv(.x))
data_extracted <- 
  read_csv(file = here("output", "input_2020-04-01.csv.gz"),
           col_types = cols_only( # only read the columns defined here
             patient_id = col_integer(), 
             
             # demographics
             agegroup = col_character(),
             sex = col_character(),
             bmi = col_character(),
             smoking_status = col_character(),
             imd = col_character(),
             region = col_character(),
             
             # comorbidities
             hypertension = col_logical(),
             chronic_respiratory_disease = col_logical(),
             asthma = col_character(),
             chronic_cardiac_disease = col_logical(),
             diabetes_controlled = col_character(),
             cancer = col_logical(),
             haem_cancer = col_logical(),
             dialysis_kidney_transplant = col_character(),
             ckd = col_character(),
             chronic_liver_disease = col_logical(),
             stroke = col_logical(),
             dementia = col_logical(),
             other_neuro = col_logical(),
             organ_kidney_transplant = col_character(),
             dysplenia = col_logical(),
             sickle_cell = col_logical(),
             ra_sle_psoriasis = col_logical(),
             aplastic_anaemia = col_logical(),
             permanent_immunodeficiency = col_logical(),
             temporary_immunodeficiency = col_logical(),
             learning_disability = col_logical(),
             sev_mental_ill = col_logical(),
             
             # outcome
             died_ons_covid_flag_any = col_logical(),
             )
           )

data_processed <- 
  data_extracted %>%
  mutate(agegroup = fct_case_when(
          agegroup == "18-39" ~ "18-39",
          agegroup == "40-49" ~ "40-49",
          agegroup == "50-59" ~ "50-59",
          agegroup == "60-69" ~ "60-69",
          agegroup == "70-79" ~ "70-79",
          agegroup == "80plus" ~ "80plus",
          TRUE ~ NA_character_), # no missings should occur as individuals with
         # missing age are not included in the study
         
         sex = fct_case_when(
           sex == "Female" ~ "Female",
           sex == "Male" ~ "Male",
           TRUE ~ NA_character_), # no missings should occur as only of those 
         # individuals with a female/male sex, data is extracted
         
         bmi = fct_case_when(
           bmi == "Not obese" ~ "Not obese",
           bmi == "Obese I (30-34.9)" ~ "Obese I (30-34.9 kg/m2)",
           bmi == "Obese II (35-39.9)" ~ "Obese II (35-39.9 kg/m2)",
           bmi == "Obese III (40+)" ~ "Obese III (40+ kg/m2)",
           TRUE ~ NA_character_),
         
         smoking_status = fct_case_when(
           smoking_status %in% c("N", "M") ~ "Never and unknown",
           smoking_status == "E" ~ "Former",
           smoking_status == "S" ~ "Current",
           TRUE ~ NA_character_),
         
         imd = fct_case_when(
           imd == "1" ~ "1 (least)",
           imd == "2" ~ "2",
           imd == "3" ~ "3",
           imd == "4" ~ "4",
           imd == "5" ~ "5 (most)",
           imd == "0" ~ NA_character_),
         
         region = fct_case_when(
           region == "North East" ~ "North East",
           region == "North West" ~ "North West",
           region == "Yorkshire and the Humber" ~ "Yorkshire and the Humber",
           region == "East Midlands" ~ "East Midlands",
           region == "West Midlands" ~ "West Midlands",
           region == "East of England" ~ "East of England",
           region == "London" ~ "London",
           region == "South East" ~ "South East",
           TRUE ~ NA_character_),
         
         # comorbidities
         asthma = fct_case_when(
           asthma == "0.0" ~ "No asthma",
           asthma == "1.0" ~ "With no oral steroid use",
           asthma == "2.0" ~ "With oral steroid use"),
         
         diabetes_controlled = fct_case_when(
           diabetes_controlled == "0.0" ~ "No diabetes",
           diabetes_controlled == "1.0" ~ "Controlled",
           diabetes_controlled == "2.0" ~ "Not controlled",
           diabetes_controlled == "3.0" ~ "Without recent Hb1ac measure"),
         
         dialysis_kidney_transplant = fct_case_when(
           dialysis_kidney_transplant == "0.0" ~ "No dialysis",
           dialysis_kidney_transplant == "1.0" ~ "With previous kidney transplant",
           dialysis_kidney_transplant == "2.0" ~ "Without previous kidney transplant"),
         
         ckd = fct_case_when(
           ckd == "No CKD" ~ "No CKD",
           ckd == "0" ~ "Stage 0",
           ckd == "3a" ~ "Stage 3a",
           ckd == "3b" ~ "Stage 3b",
           ckd == "4" ~ "Stage 4",
           ckd == "5" ~ "Stage 5"),
         
         organ_kidney_transplant = fct_case_when(
           organ_kidney_transplant == "No transplant" ~ "No transplant",
           organ_kidney_transplant == "Kidney" ~ "Kidney transplant",
           organ_kidney_transplant == "Organ" ~ "Other organ transplant")
  )

# Save output ---
output_dir <- here("output", "data_processed")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
saveRDS(data_processed, 
        here("output", "data_processed", "data_processed_2020-04-01.rds"),
        compress = TRUE)
