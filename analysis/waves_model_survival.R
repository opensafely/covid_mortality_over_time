## ###########################################################

##  This script:
## - Imports data of the three waves
## - Models Cox regressions

## linda.nab@thedatalab.com - 20220304
## ###########################################################

# Load libraries & functions ---
library(here)
library(readr)
library(purrr)
library(dplyr)
library(jsonlite)
library(survival)
library(rms)
## Load json file listing demographics, comorbidities and start dates waves
config <- fromJSON(here("analysis", "config.json"))

# Import data extracts of waves  ---
input_files_processed <-
  Sys.glob(here("output", "processed", "input_wave*.rds"))
data_processed <- 
  map(.x = input_files_processed,
      .f = ~ readRDS(.x))
## add variable fu
data_processed <-
  map2(.x = data_processed,
       .y = c(config$wave1$start_date, 
              config$wave2$start_date,
              config$wave3$start_date),
       .f = ~ mutate(.x, 
                     fu = difftime(died_ons_covid_flag_any_date, .y)))

# Kaplan-Meiers

# Survival modelling ---
coxmodel <- function(data, variable) {
  formula <- as.formula(paste0("Surv(fu, died_ons_covid_flag_any) ~", 
                        variable, 
                        "+ rcs(age, 4) + sex + strata(region)"))
  model <- coxph(formula, data)
  selection <-
    model$coefficients %>%
    names %>%
    startsWith(variable)
  coefs <- model$coefficients[selection, drop = FALSE] %>% exp()
  cis <- confint(model)[selection,]
  print(variable)
  out <- cbind(coefs, cis)
  return(out)
}

coxmodel_list <- function(data, variables) {
  map(.x = variables,
      .f = ~ coxmodel(data, .x))
}

output <- coxmodel_list(data_processed[[1]], 
              c(config$demographics, config$comorbidities))

# to do: 
# - account for competing risk death from other cause
# - check proportional hazard assumption

# Save output --
output_dir <- here("output", "tables")
ifelse(!dir.exists(output_dir), dir.create(output_dir), FALSE)
saveRDS(output, file = paste0(output_dir, "/HR.rds"))
