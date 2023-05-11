## ###########################################################

##  This script:
## - Imports the IRRs
## - Simplifies

## linda.nab@thedatalab.com - 20230511
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(stringr)

# read data
absrisks <- read_csv(here("output/tables/absrisks_for_viz_tidied.csv"))

## Relabel groups for binary variables
absrisks <- absrisks %>%
  filter(Characteristic != "Impaired vaccine response") %>%
  select(-Category) %>%
  filter(Characteristic != "Region") %>%
  mutate(
    Plot_group = ifelse(Plot_group=="Clinical risk group (other)", Characteristic, Plot_group),
    Plot_category = ifelse(Plot_category=="TRUE", "+", Plot_category),
    Plot_category = ifelse(Plot_category=="FALSE", paste0(Plot_group, " -"), Plot_category),
    Plot_category = ifelse(Plot_category=="80plus", "80+", Plot_category)
  )

## Simplify names
absrisks$Plot_category[absrisks$Plot_category=="Without recent Hb1ac measure"] = "No recent Hb1ac measure"

absrisks$Characteristic[absrisks$Characteristic=="High blood pressure or diagnosed hypertension"] = "Hypertension"
absrisks$Plot_group[absrisks$Plot_group=="High blood pressure or diagnosed hypertension"] = "Hypertension"
absrisks$Plot_category[absrisks$Plot_category=="High blood pressure or diagnosed hypertension -"] = "Hypertension -"

absrisks$Characteristic[absrisks$Characteristic=="Rheumatoid arthritis/ lupus/ psoriasis"] = "RA/lupus/psoriasis"
absrisks$Plot_group[absrisks$Plot_group=="Rheumatoid arthritis/ lupus/ psoriasis"] = "RA/lupus/psoriasis"
absrisks$Plot_category[absrisks$Plot_category=="Rheumatoid arthritis/ lupus/ psoriasis -"] = "RA/lupus/psoriasis -"

absrisks$Characteristic[absrisks$Characteristic=="Immunosuppressive condition"] = "Immunodeficiency"
absrisks$Plot_group[absrisks$Plot_group=="Immunosuppressive condition"] = "Immunodeficiency"
absrisks$Plot_category[absrisks$Plot_category=="Immunosuppressive condition -"] = "Immunodeficiency -"

absrisks$Characteristic[absrisks$Characteristic=="Other neurological disease"] = "Neurological disease"
absrisks$Plot_group[absrisks$Plot_group=="Other neurological disease"] = "Neurological disease"
absrisks$Plot_category[absrisks$Plot_category=="Other neurological disease -"] = "Neurological disease -"

## Set factor levels
absrisks$Plot_category = factor(absrisks$Plot_category, levels = rev(unique(absrisks$Plot_category)))
absrisks$Plot_group = factor(absrisks$Plot_group, levels = unique(absrisks$Plot_group))

# save data
write_feather(absrisks,
              here("output", "tables", "absrisks_for_viz_tidied_simplified.feather"),
              compression = "zstd")
