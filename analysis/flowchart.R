## ###########################################################

##  This script:
## - Calculates numbers for flowchart and saves those in 
##   /output/tables/wave1_flowchart.csv

## linda.nab@thedatalab.com - 20220627
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(dplyr)
data <- read_csv(here("output", "input_flowchart.csv.gz"),
                 col_types = cols_only(
                   patient_id = col_integer(),
                   has_follow_up = col_logical(),
                   age = col_integer(),
                   sex = col_character(),
                   stp = col_character(),
                   index_of_multiple_deprivation = col_integer()
                 ))

# Calc numbers
total_n <- nrow(data)

# no follow-up of three months
no_follow_up <- 
  data %>% 
  filter(has_follow_up == FALSE) %>% nrow()

# follow-up but not 18 <= age <= 110
no_age <- 
  data %>% 
  filter(has_follow_up == TRUE) %>%
  filter(age < 18 | age > 110) %>% nrow()

# follow-up and 18 <= age <= 110 but missing demographics (stp / imd)
no_stp <- 
  data %>% 
  filter(has_follow_up == TRUE) %>% 
  filter(age >= 18 & age <= 110) %>%
  filter(is.na(stp) | index_of_multiple_deprivation < 0) %>% nrow()

# included
total_n_included <- 
  data %>% 
  filter(has_follow_up == TRUE) %>% 
  filter(age >= 18 & age <= 110) %>%
  filter(!is.na(stp) & index_of_multiple_deprivation >= 0) %>% nrow()

# combine numbers
out <- rbind(total_n,
             no_follow_up,
             no_age,
             no_stp,
             total_n_included) %>% as.data.frame()

# Save output
output_dir0 <- here("output", "tables")
ifelse(!dir.exists(output_dir0), dir.create(output_dir0), FALSE)
output_dir <- here("output", "tables", "flowchart")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(x = out,
          path = paste0(output_dir, "/", "wave1_flowchart.csv"))