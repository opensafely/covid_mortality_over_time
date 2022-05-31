## ###########################################################

##  This script:
## - Imports the subgroup specific standardised rates
## - Calculates the ratios of the standardised rates

## linda.nab@thedatalab.com - 20220329
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(lubridate)
library(jsonlite)
## Load json file listing demographics and comorbidities
config <- fromJSON(here("analysis", "config.json"))
## Load reference values for subgroups
source(here("analysis", "utils", "reference_values.R"))

# Import data ---
## Create vector containing the demographics and comorbidities
subgroups_vctr <- c(config$demographics, config$comorbidities)
## Import the standardised mortality rates:
## Import mortality rates for sex:
sex_rates_std <- read_csv(file = here("output", 
                                      "rates",
                                      "standardised",
                                      "sex_std.csv"),
                          col_types = cols("D", "f", "d", "d"))
## Import the rest of the mortality rates
subgroups_rates_std <- 
  map(.x = subgroups_vctr,
      .f = ~ read_csv(file = here("output", 
                                  "rates",
                                  "processed",
                                  paste0(.x,".csv")),
                      col_types = cols("D", "f", "f", "d", "d")))
names(subgroups_rates_std) <- subgroups_vctr

# Prepare data ---
## Add reference --> needed to calculate standardised rate ratios (srr) = 
## rate_a / rate_b where rate_b is rate of the reference.
## Add reference to 'sex_rates_std' using df reference_values sourced from 
## ./analysis/utils/reference_values.R
sex_rates_std <-
  sex_rates_std %>%
  mutate(reference = 
           reference_values %>% filter(subgroup == "sex") %>% pull(reference))
## Add reference to 'subgroups_rates_std' using df reference_values sourced from
## ./analysis/utils/reference_values.R
subgroups_rates_std <-
  imap(.x = subgroups_rates_std,
       .f = ~ 
         mutate(.x, 
                reference = 
                reference_values %>% filter(subgroup == .y) %>% pull(reference)
                )
       )

# Calculate ratios ---
## Sex
## srr = dsr_a / dsr_b where dsr_b is dsr of the reference (here sex == F)
## confidence interval of srr is calculated as follows:
## log(srr) = log(dsr_a) - log(dsr_b)
## var(log(srr)) = var(log(dsr_a)) + var(log(dsr_b))
## var(log(dsr_a)) = 1 / dsr_a ^2 * var(dsr_a) (idem for b) [using delta method]
## ci_srr = exp[log(srr) +/- 1.96 * sqrt(var(log(srr)))]
## see also: (restricted access to Bennett institute)
## https://docs.google.com/document/d/1Slo6FxC2Jv2qrqz5T4rnH_VXJhRajq7bKc_pcuveV5s/edit?usp=sharing
sex_ratios <- 
  sex_rates_std %>%
  group_by(date) %>%
  mutate(srr = dsr / dsr[sex == reference],
         log_dsr = log(dsr),
         var_log_dsr = 1 / dsr^2 * var_dsr) %>%
  mutate(log_srr = log(srr),
         var_log_srr = var_log_dsr + var_log_dsr[sex == reference]) %>%
  mutate(srr_ci_lo = exp(log_srr - qnorm(0.975) * sqrt(var_log_srr)),
         srr_ci_up = exp(log_srr + qnorm(0.975) * sqrt(var_log_srr))) %>%
  select(date, sex, 
         srr, srr_ci_lo, srr_ci_up)
## Rest (works as described above)
subgroups_ratios <- 
  imap(.x = subgroups_rates_std,
       .f = ~ group_by(.x, date, sex) %>%
         mutate(srr = dsr / dsr[get(.y) == reference],
                    log_dsr = log(dsr),
                    var_log_dsr = 1 / dsr^2 * var_dsr) %>%
         mutate(log_srr = log(srr),
                var_log_srr = var_log_dsr + var_log_dsr[get(.y) == reference]) %>%
         mutate(srr_ci_lo = exp(log_srr - qnorm(0.975) * sqrt(var_log_srr)),
                srr_ci_up = exp(log_srr + qnorm(0.975) * sqrt(var_log_srr))) %>%
         select(date, sex, !!.y,
                srr, srr_ci_lo, srr_ci_up)) 

# Save output ---
output_dir <- here("output", "ratios")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
## Sex
write_csv(x = sex_ratios,
          path = paste0(output_dir, "/", "sex", ".csv"))
## Rest
iwalk(.x = subgroups_ratios,
      .f = ~ write_csv(x = .x,
                       path = paste0(output_dir, "/", .y, ".csv")))
