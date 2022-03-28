## ###########################################################

##  This script:
## - Contains a general function that is used to extract data

## linda.nab@thedatalab.com - 20220328
## ###########################################################

# Load libraries & functions ---
library(dplyr)
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}

# function ---
process_data <- function(data_extracted) {
  data_processed <-
    data_extracted %>%
    mutate(
      agegroup = fct_case_when(
        agegroup == "18-39" ~ "18-39",
        agegroup == "40-49" ~ "40-49",
        agegroup == "50-59" ~ "50-59",
        agegroup == "60-69" ~ "60-69",
        agegroup == "70-79" ~ "70-79",
        agegroup == "80plus" ~ "80plus",
        TRUE ~ NA_character_
      ),
      # no missings should occur as individuals with
      # missing age are not included in the study
      
      sex = fct_case_when(sex == "F" ~ "Female",
                          sex == "M" ~ "Male",
                          TRUE ~ NA_character_),
      # no missings should occur as only of those
      # individuals with a female/male sex, data is extracted
      
      bmi = fct_case_when(
        bmi == "Not obese" ~ "Not obese",
        bmi == "Obese I (30-34.9)" ~ "Obese I (30-34.9 kg/m2)",
        bmi == "Obese II (35-39.9)" ~ "Obese II (35-39.9 kg/m2)",
        bmi == "Obese III (40+)" ~ "Obese III (40+ kg/m2)",
        TRUE ~ NA_character_
      ),
      
      smoking_status = fct_case_when(
        smoking_status %in% c("N", "M") ~ "Never and unknown",
        smoking_status == "E" ~ "Former",
        smoking_status == "S" ~ "Current",
        TRUE ~ NA_character_
      ),
      
      imd = fct_case_when(
        imd == "1" ~ "1 (least)",
        imd == "2" ~ "2",
        imd == "3" ~ "3",
        imd == "4" ~ "4",
        imd == "5" ~ "5 (most)",
        imd == "0" ~ NA_character_
      ),
      
      region = fct_case_when(
        region == "North East" ~ "North East",
        region == "North West" ~ "North West",
        region == "Yorkshire and the Humber" ~ "Yorkshire and the Humber",
        region == "East Midlands" ~ "East Midlands",
        region == "West Midlands" ~ "West Midlands",
        region == "East of England" ~ "East of England",
        region == "London" ~ "London",
        region == "South East" ~ "South East",
        TRUE ~ NA_character_
      ),
      
      # comorbidities
      asthma = fct_case_when(
        asthma == "0.0" ~ "No asthma",
        asthma == "1.0" ~ "With no oral steroid use",
        asthma == "2.0" ~ "With oral steroid use"
      ),
      
      diabetes_controlled = fct_case_when(
        diabetes_controlled == "0.0" ~ "No diabetes",
        diabetes_controlled == "1.0" ~ "Controlled",
        diabetes_controlled == "2.0" ~ "Not controlled",
        diabetes_controlled == "3.0" ~ "Without recent Hb1ac measure"
      ),
      
      dialysis_kidney_transplant = fct_case_when(
        dialysis_kidney_transplant == "0.0" ~ "No dialysis",
        dialysis_kidney_transplant == "1.0" ~ "With previous kidney transplant",
        dialysis_kidney_transplant == "2.0" ~ "Without previous kidney transplant"
      ),
      
      ckd = fct_case_when(
        ckd == "No CKD" ~ "No CKD",
        ckd == "0" ~ "Stage 0",
        ckd == "3a" ~ "Stage 3a",
        ckd == "3b" ~ "Stage 3b",
        ckd == "4" ~ "Stage 4",
        ckd == "5" ~ "Stage 5"
      ),
      
      organ_kidney_transplant = fct_case_when(
        organ_kidney_transplant == "No transplant" ~ "No transplant",
        organ_kidney_transplant == "Kidney" ~ "Kidney transplant",
        organ_kidney_transplant == "Organ" ~ "Other organ transplant"
      )
    )
  data_processed
}