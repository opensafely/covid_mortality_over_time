## ###########################################################

##  This script:
## - Imports the IRs
## - Combines these results in one table (used for data viz)

## linda.nab@thedatalab.com - 20220618
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
subgroups_vctr <- c("sex", config$demographics, comorbidities)
subgroups_vctr <- subgroups_vctr[-which(subgroups_vctr == "region")]
# needed to add plot_groups
source(here("analysis", "utils", "subgroups_and_plot_groups.R"))
# needed to rename subgroups 
source(here("analysis", "utils", "rename_subgroups.R"))
# Function 'process_est_combined'
## Arguments
## est_combined_wave: a data.frame with IR estimates and CIs
## subgroups_and_plot_groups: a data.frame mapping subgroups in config.yaml
## to 'plot_group' (aggregating subgroups)
## see (/analysis/utils/subgroups_and_plot_groups.R)
## Output
## Processed est_combined_wave data.frame, with columns:
## subgroup, level, plot_category, plot_group, IR, LowerCI, UpperCI
process_est_combined <- function(est_combined_wave,
                                 subgroups_and_plot_groups,
                                 suffix){
  est_combined_wave <-
    est_combined_wave %>%
    left_join(subgroups_and_plot_groups,
              by = "subgroup")
  est_combined_wave <-
    est_combined_wave[
      match(est_combined_wave$subgroup, subgroups_vctr) %>% order(), ] 
  # relocate reference value agegroup 
  # references values is first, but for agegroup it should be third since
  # reference value for agegroup is 50-59
  est_combined_wave <- 
    est_combined_wave[c(2, 3, 1, 4:nrow(est_combined_wave)),]
  
  est_combined_wave <- 
    est_combined_wave %>% 
    # use Age Group io agegroup etc.
    rename_subgroups() %>%
    # add (ref) to indicate which of the levels wihtin a subgroup is the ref
    mutate(plot_category = level,
           IR = round(ir, 2),
           LowerCI = round(lower, 2),
           UpperCI = round(upper, 2)) %>%
    select(subgroup, level, plot_category, plot_group,
           IR, LowerCI, UpperCI)
  colnames(est_combined_wave)[which(colnames(est_combined_wave) %in%
                                c("IR", "LowerCI", "UpperCI"))] <-
    c(paste0(c("IR.", "LowerCI.", "UpperCI."), suffix))
  est_combined_wave
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
                                            upper = col_double())) %>%
                      filter(!(subgroup %in% c("hypertension",
                                               "bp"))))
input_files_irs_crude <- Sys.glob(here("output", "tables", "wave*_ir.csv"))
# names of ir_crude
waves_vctr_irs_crude <- str_extract(input_files_irs_crude, "wave[:digit:]")
# agegroup is not age or sex standardised, and added to the irs
# for agegroup, the redacted rate is taken, for consistency throughout the 
# manuscript
irs_crude <- 
  map(.x = input_files_irs_crude,
      .f = ~ read_csv(.x,
                      col_types = cols_only(subgroup = col_character(),
                                            level = col_character(),
                                            rate_redacted = col_double(),
                                            lower_redacted = col_double(),
                                            upper_redacted = col_double())) %>%
              filter(subgroup == "agegroup") %>%
              rename(ir = rate_redacted,
                     lower = lower_redacted,
                     upper = upper_redacted))
# combine agegroup from crude file and rest
estimates <-
  map2(.x = irs_crude,
       .y = irs_std,
       .f = ~ bind_rows(.x, .y))
names(estimates) <- waves_vctr_irs_crude

# Process the combined estimates ---
## uses function 'process_est_combined' defined above
est_processed <-
  imap(.x = estimates,
       .f = ~ process_est_combined(.x,
                                   subgroups_and_plot_groups,
                                   .y))
## Make one wide table from list of processed tables
table_est <-
  plyr::join_all(est_processed,
                 by = c("subgroup", "level", "plot_category", "plot_group"))
## select columns needed + calculate ratio of IR
table_est <- 
  table_est %>%
  rename(Characteristic = subgroup,
         Category = level,
         Plot_category = plot_category,
         Plot_group = plot_group) %>%
  mutate(IR_ratio.wave2 = IR.wave2 / IR.wave1,
         IR_ratio.wave3 = IR.wave3 / IR.wave1,
         IR_ratio.wave4 = IR.wave4 / IR.wave1,
         IR_ratio.wave5 = IR.wave5 / IR.wave1)

# Save output --
## saved as '/output/tables/wave*_vax_coverage.csv
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
write_csv(table_est,
          path = paste0(output_dir,
                        "/absrisks_for_viz_tidied.csv"))
