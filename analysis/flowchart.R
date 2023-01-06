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
library(fs)
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  wave <- "wave1"
  rds_file <- here("output", "processed", "input_flowchart_wave1.rds")
  output_dir <- here("output", "tables", "flowchart")
} else {
  wave <- args[[1]]
  rds_file <- here("output", "processed",
                   paste0("input_flowchart_", wave, ".rds"))
  output_dir <- args[[2]]
}
data <- readRDS(rds_file)

# Calc numbers
total_n <- nrow(data) %>% plyr::round_any(5)

# not 18 <= age <= 110
no_age <- 
  data %>%
  filter(age < 18 | age > 110) %>% 
  nrow() %>% plyr::round_any(5)
cat("\n#### any NA's in age? ####\n")
print(any(is.na(data$age)))

# age but missing sex
no_sex <- 
  data %>%
  filter(age >= 18 & age <= 110) %>% 
  filter(!(sex %in% c("F", "M"))) %>% 
  nrow() %>% plyr::round_any(5)
cat("\n#### any NA's in sex? ####\n")
print(any(is.na(data$sex)))

# age & sex but missing stp
no_stp <- 
  data %>%
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>% 
  filter(is.na(stp)) %>% 
  nrow() %>% plyr::round_any(5)
cat("\n#### any NA's in stp? ####\n")
print(any(is.na(data$stp)))

# age & sex & stp but missing imd
no_imd <- 
  data %>%
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>% 
  filter(!is.na(stp)) %>% 
  filter(index_of_multiple_deprivation == -1) %>%
  nrow() %>% plyr::round_any(5)
cat("\n#### any NA's in index_of_multiple_deprivation? ####\n")
print(any(is.na(data$index_of_multiple_deprivation)))

# age & sex & stp & imd but missing follow up
no_follow_up <- 
  data %>% 
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>% 
  filter(!is.na(stp)) %>% 
  filter(index_of_multiple_deprivation != -1) %>%
  filter(has_follow_up == FALSE) %>% 
  nrow() %>% plyr::round_any(5)
# NA in has_follow_up?
cat("#### any NA's in has_follow_up? ####\n")
print(any(is.na(data$has_follow_up)))

# included
total_n_included <- 
  data %>% 
  filter(age >= 18 & age <= 110) %>% 
  filter(sex %in% c("F", "M")) %>%
  filter(!is.na(stp)) %>%
  filter(index_of_multiple_deprivation != -1) %>%
  filter(has_follow_up == TRUE) %>%
  nrow() %>% plyr::round_any(5)

# combine numbers
out <-
  tibble(total_n,
         no_age,
         no_sex,
         no_stp,
         no_imd,
         no_follow_up,
         total_n_included) 

# Save output
output_dir0 <- here("output", "tables")
dir_create(output_dir0)
dir_create(output_dir)
write_csv(x = out,
          path = path(output_dir, paste0(wave, "_flowchart.csv")))
