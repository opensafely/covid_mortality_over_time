## ###########################################################

##  This script:
## - Imports vax analysis results
## - Calculates percentages

## linda.nab@thedatalab.com - 20221208
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(stringr)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Create vector containing the demographics and comorbidities
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]
subgroups_vctr <- c("sex", config$demographics, comorbidities, "imp_vax")
subgroups_vctr <- subgroups_vctr[-which(subgroups_vctr == "region")]
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups 
source(here("analysis", "utils", "rename_subgroups.R"))

# Import results vax analysis [COUNTS] ---
files_vax_counts <-
  Sys.glob(here("output", "tables", "vax", "wave*_vax_counts.csv"))
waves_vctr <- str_extract(files_vax_counts, "wave[:digit:]")
data_vax_counts <- 
  map(.x = files_vax_counts,
      .f = ~ read_csv(.x))
names(data_vax_counts) <- waves_vctr


calc_percentages <- function(data){
  data %>%
    mutate(across(starts_with("start_") | starts_with("end_"), 
                  ~ if_else(. == "[REDACTED]", NA_character_, as.character(.)))) %>%
    mutate(across(starts_with("start_") | starts_with("end_"), 
                  ~ ((as.double(.) / n) * 100) %>% round(1)))
}

data_vax_counts_perc <- 
  map(.x = data_vax_counts,
      .f = ~ calc_percentages(.x))


# Import results vax analysis [FOLLOW UP] ---
files_vax_fu <-
  Sys.glob(here("output", "tables", "vax", "wave*_vax_fu.csv"))
waves_vctr <- str_extract(files_vax_fu, "wave[:digit:]")
data_vax_fu <- 
  map(.x = files_vax_fu,
      .f = ~ read_csv(.x))
names(data_vax_fu) <- waves_vctr


calc_percentages_fu <- function(data){
  data %>%
    mutate(across(starts_with("fu_"), 
                  ~ if_else(. == "[REDACTED]", NA_character_, as.character(.)))) %>%
    mutate(perc = across(starts_with("fu_"), 
                    ~ ((as.double(.) / fu) * 100) %>% round(1)))
}

data_vax_fu_perc <- 
  map(.x = data_vax_fu,
      .f = ~ calc_percentages_fu(.x) %>% 
        filter(subgroup != "region"))

# some summary stats for text
data_vax_fu_perc$wave2 %>% View()
data_vax_fu_perc$wave2 %>% 
  mutate(fu_2_3 = fu_2 + fu_3) %>%
  arrange(-fu_2_3) %>% View()
data_vax_fu_perc$wave2 %>% 
  mutate(fu_2_3 = fu_2 + fu_3) %>%
  pull(fu_2_3) %>% quantile()

data_vax_fu_perc$wave3 %>% View()
data_vax_fu_perc$wave3 %>% 
  mutate(fu_2_3_4 = perc$fu_2 + perc$fu_3 + perc$fu_4) %>%
  arrange(-fu_2_3_4) %>% View()
data_vax_fu_perc$wave3 %>% 
  mutate(fu_2_3_4 = fu_2 + fu_3 + fu_4) %>%
  pull(fu_2_3_4) %>% quantile()

data_vax_fu_perc$wave4 %>% View()
data_vax_fu_perc$wave4 %>% 
  mutate(fu_2_3_4_5 = fu_2 + fu_3 + fu_4 + fu_5) %>%
  arrange(-fu_2_3_4_5) %>% View()
data_vax_fu_perc$wave4 %>% 
  mutate(fu_2_3_4_5 = fu_2 + fu_3 + fu_4 + fu_5) %>%
  pull(fu_2_3_4_5) %>% quantile()

data_vax_fu_perc$wave5 %>% View()
data_vax_fu_perc$wave5 %>% 
  mutate(fu_2_3_4_5 = fu_2 + fu_3 + fu_4 + fu_5) %>%
  arrange(-fu_2_3_4_5) %>% View()
data_vax_fu_perc$wave5 %>% 
  mutate(fu_2_3_4_5 = fu_2 + fu_3 + fu_4 + fu_5) %>%
  pull(fu_2_3_4_5) %>% quantile()

# Table S4
make_table_fu <- function(data){
  data %>%
    mutate(across(starts_with("fu_"), 
                  ~ if_else(. == "[REDACTED]", NA_character_, as.character(.)))) %>%
    mutate(across(starts_with("fu_"), 
                   ~ ((as.double(.) / fu) * 100) %>% round(0),
                  .names = "perc_{col}"),
           across(starts_with("fu"),
                  ~ (as.double(.) / 365250) %>% round(1))) %>%
    filter(!subgroup %in% c("region", "imp_vax", "hypertension", "bp"))
}

summarise_fu_wave2 <- function(data_wave2){
  data_wave2 %>%
    mutate(fu_2_or_more = fu_2 + fu_3 + fu_4 + fu_5,
           perc_2_or_more = perc_fu_2 + perc_fu_3 + perc_fu_4 + perc_fu_5) %>%
    mutate(fu_1_perc = paste0(fu_1, " (", perc_fu_1, "%)"),
           fu_2_or_more_perc = paste0(fu_2_or_more, " (", perc_2_or_more, "%)")) %>%
    select(subgroup, level, fu, fu_1_perc, fu_2_or_more_perc)
}

summarise_fu_wave345 <- function(data_wave345){
  data_wave345 %>%
    mutate(fu_3_or_more = fu_3 + fu_4 + fu_5,
           perc_3_or_more = perc_fu_3 + perc_fu_4 + perc_fu_5) %>%
    mutate(fu_1_perc = paste0(fu_1, " (", perc_fu_1, "%)"),
           fu_2_perc = paste0(fu_2, " (", perc_fu_2, "%)"),
           fu_3_or_more_perc = paste0(fu_3_or_more, " (", perc_3_or_more, "%)")) %>%
    select(subgroup, level, fu, fu_1_perc, fu_2_perc, fu_3_or_more_perc)
}

wave2_vax_fu_perc <- 
  data_vax_fu$wave2 %>%
  make_table_fu() %>%
  summarise_fu_wave2() %>%
  rename_with(~ paste0("wave2.", .), .cols = starts_with("fu"))

wave345_vax_fu_perc <- 
  imap(.x = data_vax_fu[c("wave3", "wave4", "wave5")],
       .f = ~ {  data <- 
         make_table_fu(.x) %>%
         summarise_fu_wave345()
         colnames(data)[which(colnames(data) %in% c("fu", "fu_1_perc", "fu_2_perc", "fu_3_or_more_perc"))] <-
           paste0(.y, ".", c("fu", "fu_1_perc", "fu_2_perc", "fu_3_or_more_perc"))
         data})

table_perc <- 
  plyr::join_all(c(list(wave2_vax_fu_perc), wave345_vax_fu_perc),
                 by = c("subgroup", "level"))
table_perc <-
  slice(table_perc, c(1, 3, 4, 2), 5:nrow(table_perc))

write_csv(table_perc,
         here::here("output", "tables", "vax", "table_S4.csv"))

        