# Load libraries & custom functions ---
library(here)
library(dplyr)
library(readr)
library(purrr)
library(stringr)
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/extract_data.R")) # function extract_data()
source(paste0(utils_dir, "/add_kidney_vars_to_data.R")) # function add_kidney_vars_to_data()
source(paste0(utils_dir, "/process_data.R")) # function process_data()
# Load json config for dates of waves
config <- fromJSON(here("analysis", "config.json"))

# Import data extracts of waves ---
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  wave <- "wave1"
} else {
  wave <- args[[1]]
}

# Load data ---
## Search input files by globbing
input_files <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
# vector with waves
input_file_wave <- input_files[str_detect(input_files, wave)]

# select people with negative fu
data <- 
  read_rds(input_file_wave)

data <-
  data %>%
  filter(fu_vax_0 < 0 |
           fu_vax_1 < 0 |
           fu_vax_2 < 0 |
           fu_vax_3 < 0 |
           fu_vax_4 < 0 |
           fu_vax_6 < 0) %>%
  select(starts_with("fu_vax"),
         starts_with("start_vax_dose"),
         start_date_wave,
         fu)
data %>% nrow() %>% print()

fs::dir_create(here("output", "data_properties", "detect_issues"))
data <- 
  data[sample(1:nrow(data), size = ifelse(nrow(data) > 5, 5, 0)), ] %>%
  write_csv(here("output", "data_properties", "detect_issues", "fu_neg.csv"))

