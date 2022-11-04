## ###########################################################

##  This script:
## - Imports the HRs
## - Imports vaccination covarage data
## - Combines these results in one table (used for data viz)

## linda.nab@thedatalab.com - 20220608
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Create vector containing the demographics and comorbidities
comorbidities <- 
  config$comorbidities[-which(config$comorbidities %in% c("hypertension", "bp"))]
subgroups_vctr <- c("agegroup", "sex", config$demographics, comorbidities)
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3", "wave4", "wave5")
# needed to add reference values
source(here("analysis", "utils", "reference_values.R"))
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))
# Function 'process_est_cov_combined'
## Arguments
## est_cov_combined_wave: a data.frame with HR estimates and CIs and vax 
## coverage combined for a specific wave (e.g., est_cov_combined$wave1)
## reference_values: a data.frame with the reference value for each subgroup
## see (/analysis/utils/reference_values.R)
## subgroups_and_plot_groups: a data.frame mapping subgroups in config.yaml
## to 'plot_group' (aggregating subgroups)
## see (/analysis/utils/subgroups_and_plot_groups.R)
## Output
## Processed est_cov_combined_wave data.frame, with columns:
## subgroup, level, plot_category, plot_group, HR, LowerCI, UpperCI, cov_2
process_est_cov_combined <- function(est_cov_combined_wave, 
                                     reference_values,
                                     subgroups_and_plot_groups){
  est_cov_combined_wave <-
    est_cov_combined_wave %>%
    left_join(subgroups_and_plot_groups,
              by = "subgroup")
  est_cov_combined_wave <-
    est_cov_combined_wave[
      match(est_cov_combined_wave$subgroup, subgroups_vctr) %>% order(), ] 
  # relocate reference value agegroup 
  # references values is first, but for agegroup it should be third since
  # reference value for agegroup is 50-59
  est_cov_combined_wave <- 
    est_cov_combined_wave[c(2, 3, 1, 4:nrow(est_cov_combined_wave)),]
  
  est_cov_combined_wave <- 
    est_cov_combined_wave %>% 
    left_join(reference_values, by = c("subgroup")) %>%
    # in this table Female is reference, not F
    mutate(reference = case_when(reference == "F" ~ "Female",
                                 TRUE ~ reference)) %>%
    # filter only TRUE row of a binary subgroup (e.g. cancer TRUE)
    # binary categories have reference 0
    filter(!(reference == "0" & level == FALSE)) %>%
    # use Age Group io agegroup etc.
    rename_subgroups() %>%
    # add (ref) to indicate which of the levels wihtin a subgroup is the ref
    mutate(plot_category = case_when(level == reference ~ paste0(level, " (ref)"),
                                     level == TRUE ~ subgroup,
                                     TRUE ~ level),
           HR = case_when(level == reference ~ 1,
                          TRUE ~ round(HR, 2)),
           LowerCI = case_when(level == reference ~ 1,
                               TRUE ~ round(LowerCI, 2)),
           UpperCI = case_when(level == reference ~ 1,
                               TRUE ~ round(UpperCI, 2))
    ) %>%
    select(subgroup, level, plot_category, plot_group,
           HR, LowerCI, UpperCI, cov_2)
  est_cov_combined_wave
}

# Import data extracts of waves  ---
input_files_estimates <-
  Sys.glob(here("output", "tables", "wave*_effect_estimates.csv"))
estimates <- 
  map(.x = input_files_estimates,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            HR = col_double(),
                                            LowerCI = col_double(),
                                            UpperCI = col_double())) %>%
        filter(!(subgroup %in% c("region",
                                 "hypertension",
                                 "bp"))))
names(estimates) <- waves_vctr
input_files_coverage <-
  Sys.glob(here("output", "tables", "wave*_vax_coverage.csv"))
coverage <- 
  map(.x = input_files_coverage,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            cov_2 = col_double())) %>%
        filter(!(subgroup %in% c("region",
                                 "hypertension",
                                 "bp"))))
names(coverage) <- waves_vctr

# Combine the estimates and vax coverage ---
est_cov_combined <- 
  map2(.x = estimates,
       .y = coverage,
       .f = ~ .y %>% 
         full_join(.x, by = c("subgroup", "level")))

# Process the combined estimates and vax coverage ---
## uses function 'process_est_cov_combined' defined above
est_cov_processed <-
  map(.x = est_cov_combined,
      .f = ~ process_est_cov_combined(.x, 
                                      reference_values, 
                                      subgroups_and_plot_groups))
## Make one wide table from list of processed tables
table_est_cov <-
  est_cov_processed$wave1 %>%
  left_join(est_cov_processed$wave2,
            by = c("subgroup", "level", "plot_category", "plot_group"),
            suffix = c(".1", ".2")) %>%
  left_join(est_cov_processed$wave3,
            by = c("subgroup", "level", "plot_category", "plot_group")) %>%
  left_join(est_cov_processed$wave4,
            by = c("subgroup", "level", "plot_category", "plot_group"),
            suffix = c(".3", ".4")) %>%
  left_join(est_cov_processed$wave5,
            by = c("subgroup", "level", "plot_category", "plot_group"))
## add suffix '.5' to indicate wave 5 results
col_ids <- {colnames(table_est_cov) %>% length() - 3}:{colnames(table_est_cov) %>% length()}
colnames(table_est_cov)[col_ids] <- 
  paste0(colnames(table_est_cov)[col_ids], ".5")
## select columns needed + calculate ratio of HR
table_est_cov <- 
  table_est_cov %>%
  select(-c(cov_2.1, cov_2.2)) %>%
  rename(Characteristic = subgroup,
         Category = level,
         Plot_category = plot_category,
         Plot_group = plot_group,
         Coverage_wave3 = cov_2.3,
         Coverage_wave4 = cov_2.4,
         Coverage_wave5 = cov_2.5) %>%
  mutate(HR_ratio.2 = HR.2 / HR.1,
         HR_ratio.3 = HR.3 / HR.1,
         HR_ratio.4 = HR.4 / HR.1,
         HR_ratio.5 = HR.5 / HR.1)

# Save output --
## saved as '/output/tables/wave*_vax_coverage.csv
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(table_est_cov,
          path = paste0(output_dir,
                        "/relrisks_for_viz_tidied.csv"))
