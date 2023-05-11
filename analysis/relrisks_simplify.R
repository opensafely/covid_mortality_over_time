## ###########################################################

##  This script:
## - Imports the HRs
## - Adds refs and simplifies

## linda.nab@thedatalab.com - 20230511
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(stringr)
library(arrow)

# read data
relrisks <- read_csv(here("output/tables/relrisks_for_viz_tidied.csv"))
relrisks <-
  relrisks %>%
  filter(Characteristic != "Impaired vaccine response") %>%
  select(-Category)

relrisks <- 
  relrisks %>%
  add_row("Characteristic" = "Age Group",
          "Plot_category" = "50-59 (ref)",
          "Plot_group" = "Age", 
          .before = 4) %>%
  add_row("Characteristic" = "Sex",
          "Plot_category" = "Female (ref)",
          "Plot_group" = "Sex", 
          .before = 7) %>%
  add_row("Characteristic" = "Ethnicity",
          "Plot_category" = "White (ref)",
          "Plot_group" = "Ethnicity", 
          .before = 9) %>%
  add_row("Characteristic" = "IMD quintile",
          "Plot_category" = "5 (least deprived) (ref)",
          "Plot_group" = "IMD", 
          .before = 15) %>%
  add_row("Characteristic" = "Body Mass Index",
          "Plot_category" = "Not obese (ref)",
          "Plot_group" = "BMI", 
          .before = 20) %>%
  add_row("Characteristic" = "Smoking status",
          "Plot_category" = "Never and unknown (ref)",
          "Plot_group" = "SMK", 
          .before = 24) %>%
  add_row("Characteristic" = "Asthma",
          "Plot_category" = "No asthma (ref)",
          "Plot_group" = "Asthma", 
          .before = 27) %>%
  add_row("Characteristic" = "Diabetes",
          "Plot_category" = "No diabetes (ref)",
          "Plot_group" = "Diabetes", 
          .before = 30) %>%
  add_row("Characteristic" = "Chronic kidney disease or renal replacement therapy",
          "Plot_category" = "No CKD or RRT (ref)",
          "Plot_group" = "CKD/RRT", 
          .before = 34) %>%
  add_row("Characteristic" = "Organ transplant",
          "Plot_category" = "No transplant (ref)",
          "Plot_group" = "Tx", 
          .before = 41) %>%
  replace(is.na(.), 1) %>%
  slice(3, 1, 4, 2, 5:57) %>%
  mutate(Plot_category = if_else(Plot_category == "80plus", "80+", Plot_category))

## Simplify names
relrisks$Plot_category[relrisks$Plot_category=="Without recent Hb1ac measure"] = "No recent Hb1ac measure"
relrisks$Characteristic[relrisks$Characteristic=="High blood pressure or diagnosed hypertension"] = "Hypertension"
relrisks$Plot_category[relrisks$Plot_category=="High blood pressure or diagnosed hypertension"] = "Hypertension"
relrisks$Characteristic[relrisks$Characteristic=="Rheumatoid arthritis/ lupus/ psoriasis"] = "RA/lupus/psoriasis"
relrisks$Plot_category[relrisks$Plot_category=="Rheumatoid arthritis/ lupus/ psoriasis"] = "RA/lupus/psoriasis"
relrisks$Characteristic[relrisks$Characteristic=="Immunosuppressive condition"] = "Immunodeficiency"
relrisks$Plot_category[relrisks$Plot_category=="Immunosuppressive condition"] = "Immunodeficiency"
relrisks$Characteristic[relrisks$Characteristic=="Other neurological disease"] = "Neurological disease"
relrisks$Plot_category[relrisks$Plot_category=="Other neurological disease"] = "Neurological disease"

## Set factor levels
relrisks$ref = relrisks$HR.wave3==1
relrisks$Plot_category = factor(relrisks$Plot_category, levels = rev(unique(relrisks$Plot_category)))
relrisks$Plot_group = factor(relrisks$Plot_group, levels = unique(relrisks$Plot_group))

# save data
write_feather(relrisks,
              here("output", "tables", "relrisks_for_viz_tidied_simplified.feather"),
              compression = "zstd")
