## ###########################################################

##  This script:
## - Imports the HRs
## - Combines these results in one table (used for data viz)

## linda.nab@thedatalab.com - 20220608
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
subgroups_vctr <- c("agegroup", "sex", config$demographics, comorbidities)
# vector with waves
waves_vctr <- c("wave1", "wave2", "wave3", "wave4", "wave5")
# needed to add reference values
source(here("analysis", "utils", "reference_values.R"))
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))
# Function 'process_estimates'
## Arguments
## estimates_wave: a data.frame with HR estimates and CIs
## reference_values: a data.frame with the reference value for each subgroup
## see (/analysis/utils/reference_values.R)
## subgroups_and_plot_groups: a data.frame mapping subgroups in config.yaml
## to 'plot_group' (aggregating subgroups)
## see (/analysis/utils/subgroups_and_plot_groups.R)
## suffix: suffix added to colnames HR, LowerCI and UpperCI
## Output
## Processed estimates_wave data.frame, with columns:
## subgroup, level, plot_category, plot_group, HR, LowerCI, UpperCI
process_estimates <- function(estimates_wave, 
                              reference_values,
                              subgroups_and_plot_groups,
                              suffix){
  estimates_wave <-
    estimates_wave %>%
    left_join(subgroups_and_plot_groups,
              by = "subgroup")
  estimates_wave <-
    estimates_wave[
      match(estimates_wave$subgroup, subgroups_vctr) %>% order(), ] 
  # relocate reference value agegroup 
  # references values is first, but for agegroup it should be third since
  # reference value for agegroup is 50-59
  estimates_wave <- 
    estimates_wave[c(2, 3, 1, 4:nrow(estimates_wave)),]
  
  estimates_wave <- 
    estimates_wave %>% 
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
           HR, LowerCI, UpperCI)
  colnames(estimates_wave)[which(colnames(estimates_wave) %in%
                                      c("HR", "LowerCI", "UpperCI"))] <-
    c(paste0(c("HR.", "LowerCI.", "UpperCI."), suffix))
  estimates_wave
}

# Import data extracts of waves  ---
input_files_estimates <-
  Sys.glob(here("output", "tables", "wave*_effect_estimates.csv"))
# names of hrs
waves_vctr <- str_extract(input_files_estimates, "wave[:digit:]")
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

# Process the combined estimates and vax coverage ---
## uses function 'process_est_cov_combined' defined above
est_processed <-
  imap(.x = estimates,
       .f = ~ process_estimates(.x, 
                                reference_values, 
                                subgroups_and_plot_groups,
                                suffix = .y))
## Make one wide table from list of processed tables
table_est <-
  plyr::join_all(est_processed,
                 by = c("subgroup", "level", "plot_category", "plot_group"))

## select columns needed + calculate ratio of HR
table_est <- 
  table_est %>%
  rename(Characteristic = subgroup,
         Category = level,
         Plot_category = plot_category,
         Plot_group = plot_group) %>%
  mutate(HR_ratio.wave2 = HR.wave2 / HR.wave1,
         HR_ratio.wave3 = HR.wave3 / HR.wave1,
         HR_ratio.wave4 = HR.wave4 / HR.wave1,
         HR_ratio.wave5 = HR.wave5 / HR.wave1)

# Save output --
## saved as '/output/tables/wave*_vax_coverage.csv
output_dir <- here("output", "tables")
fs::dir_create(output_dir)
write_csv(table_est,
          path = paste0(output_dir,
                        "/relrisks_for_viz_tidied.csv"))
