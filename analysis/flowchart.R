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
data <- readRDS(here("output", "processed", "input_flowchart.rds"))

# Calc numbers
total_n <- nrow(data)

# no follow-up of three months
no_follow_up <- 
  data %>% 
  filter(has_follow_up == FALSE) %>% nrow()
# NA in has_follow_up?
cat("#### any NA's in has_follow_up? ####\n")
print(any(is.na(data$has_follow_up)))

# follow-up but not 18 <= age <= 110
no_age <- 
  data %>% 
  filter(has_follow_up == TRUE) %>%
  filter(age < 18 | age > 110) %>% nrow()
cat("\n#### any NA's in age? ####\n")
print(any(is.na(data$age)))

# follow-up & age but missing sex
no_sex <- 
  data %>%
  filter(has_follow_up == TRUE) %>%
  filter(age >= 18 & age <= 110) %>% 
  filter(!(sex %in% c("F", "M"))) %>% nrow()
cat("\n#### any NA's in sex? ####\n")
print(any(is.na(data$sex)))

# follow-up & age & sex but missing demographics (stp / imd)
no_demographics <- 
  data %>%
  filter(has_follow_up == TRUE) %>%
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>% 
  filter(stp == "" | index_of_multiple_deprivation == -1) %>% nrow()
cat("\n#### any NA's in stp? ####\n")
print(any(is.na(data$stp)))
cat("\n#### any NA's in imd? ####\n")
print(any(is.na(data$index_of_multiple_deprivation)))

# included
total_n_included <- 
  data %>% 
  filter(has_follow_up == TRUE) %>% 
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & index_of_multiple_deprivation != -1) %>% nrow()

# combine numbers
out <- rbind(total_n,
             no_follow_up,
             no_age,
             no_sex,
             no_demographics,
             total_n_included) %>% as.data.frame()

# Save output
output_dir0 <- here("output", "tables")
ifelse(!dir.exists(output_dir0), dir.create(output_dir0), FALSE)
output_dir <- here("output", "tables", "flowchart")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(x = out,
          path = paste0(output_dir, "/", "wave1_flowchart.csv"))