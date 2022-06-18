## ###########################################################

##  This script:
## - Imports the IRs
## - Imports vaccination covarage data
## - Combines these results in one table (used for data viz)

## linda.nab@thedatalab.com - 20220618
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
subgroups_vctr <- c("sex", config$demographics, config$comorbidities)
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))
# Function 'process_est_cov_combined'
## Arguments
## est_cov_combined_wave: a data.frame with IR estimates and CIs and vax 
## coverage combined for a specific wave (e.g., est_cov_combined$wave1)
## subgroups_and_plot_groups: a data.frame mapping subgroups in config.yaml
## to 'plot_group' (aggregating subgroups)
## see (/analysis/utils/subgroups_and_plot_groups.R)
## Output
## Processed est_cov_combined_wave data.frame, with columns:
## subgroup, level, plot_category, plot_group, IR, LowerCI, UpperCI, cov_2
process_est_cov_combined <- function(est_cov_combined_wave,
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
    # use Age Group io agegroup etc.
    rename_subgroups() %>%
    # add (ref) to indicate which of the levels wihtin a subgroup is the ref
    mutate(plot_category = level,
           IR = round(ir, 2),
           LowerCI = round(lower, 2),
           UpperCI = round(upper, 2)) %>%
    select(subgroup, level, plot_category, plot_group,
           IR, LowerCI, UpperCI, cov_2)
  est_cov_combined_wave
}

# Import data extracts of waves  ---
# standardised IRs
input_files_irs_std <- 
  Sys.glob(here("output", "tables", "wave*_ir_std.csv"))
irs_std <- 
  map(.x = input_files_irs_std,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            ir = col_double(),
                                            lower = col_double(),
                                            upper = col_double())))
input_files_irs_crude <- Sys.glob(here("output", "tables", "wave*_ir.csv"))
# agegroup is not age or sex standardised, and added to the irs
irs_crude <- 
  map(.x = input_files_irs_crude,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            rate = col_double(),
                                            lower = col_double(),
                                            upper = col_double())) %>%
              filter(subgroup == "agegroup") %>%
              rename(ir = rate))
# combine agegroup from crude file and rest
estimates <-
  map2(.x = irs_crude,
       .y = irs_std,
       .f = ~ bind_rows(.x, .y))
names(estimates) <- c("wave1", "wave2", "wave3")
# vax coverage data
input_files_coverage <-
  Sys.glob(here("output", "tables", "wave*_vax_coverage.csv"))
coverage <- 
  map(.x = input_files_coverage,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            cov_2 = col_double())) %>%
        filter(subgroup != "region"))
names(coverage) <- c("wave1", "wave2", "wave3")

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
                                      subgroups_and_plot_groups))
## Make one wide table from list of processed tables
table_est_cov <-
  est_cov_processed$wave1 %>%
  left_join(est_cov_processed$wave2,
            by = c("subgroup", "level", "plot_category", "plot_group"),
            suffix = c(".1", ".2")) %>%
  left_join(est_cov_processed$wave3,
            by = c("subgroup", "level", "plot_category", "plot_group"))
## add suffix '.3' to indicate wave 3 results
colnames(table_est_cov)[c(13, 14, 15, 16)] <- 
  paste0(colnames(table_est_cov)[c(13, 14, 15, 16)], ".3")
## select columns needed + calculate ratio of IR
table_est_cov <- 
  table_est_cov %>%
  select(-c(cov_2.1, cov_2.2)) %>%
  rename(Characteristic = subgroup,
         Category = level,
         Plot_category = plot_category,
         Plot_group = plot_group,
         Coverage = cov_2.3) %>%
  mutate(IR_ratio.2 = IR.2 / IR.1,
         IR_ratio.3 = IR.3 / IR.1)

# Save output --
## saved as '/output/tables/wave*_vax_coverage.csv
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(table_est_cov,
          path = paste0(output_dir,
                        "/absrisks_for_viz_tidied.csv"))
