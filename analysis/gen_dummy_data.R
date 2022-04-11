library('tidyverse')
library('plyr')
library('arrow')
library('here')
library('glue')

remotes::install_github("https://github.com/wjchulme/dd4d")
library('dd4d')


population_size <- 20000

# import globally defined repo variables from
config <- jsonlite::read_json(
  path=here("analysis", "config.json")
)

start_date_wave1 <- as.Date(config$wave1$start_date)
end_date_wave1 <- as.Date(config$wave1$end_date)
start_date_wave2 <- as.Date(config$wave2$start_date)
end_date_wave2 <- as.Date(config$wave2$end_date)
start_date_wave3 <- as.Date(config$wave3$start_date)
end_date_wave3 <- as.Date(config$wave3$end_date)

known_variables_wave1 <- c(
  "start_date_wave1",
  "end_date_wave1"
)
known_variables_wave2 <- c(
  "start_date_wave2",
  "end_date_wave2"
)
known_variables_wave3 <- c(
  "start_date_wave3",
  "end_date_wave3"
)

create_sim_list <- function(){
  sim_list = lst(
    age = bn_node(
      ~as.integer(rnorm(n = 1, mean = 60, sd = 15))
    ),
    
    sex = bn_node(
      ~rfactor(n = 1, 
               levels = c("F", "M"), 
               p = c(0.51, 0.49)),
    ),
    
    stp = bn_node(
      ~rfactor(n = 1, 
               levels = c("STP1",
                          "STP2",
                          "STP3",
                          "STP4",
                          "STP5",
                          "STP6",
                          "STP7",
                          "STP8",
                          "STP9",
                          "STP10"),
               p = c(0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1))
    ),
    
    bmi = bn_node(
      ~rfactor(n = 1, 
               levels = c("Not obese", 
                          "Obese I (30-34.9)", 
                          "Obese II (35-39.9)", 
                          "Obese III (40+)"), 
               p = c(0.5, 0.2, 0.2, 0.1)),
      missing_rate = ~0.2
    ),
    
    ethnicity = bn_node(
      ~rfactor(n = 1, 
               levels = c("White",
                          "Mixed",
                          "South Asian",
                          "Black",
                          "Other",
                          "Unknown"), 
               p = c(0.7, 0.01, 0.01, 0.01, 0.01, 0.25))
    ),
    
    smoking_status_comb = bn_node(
      ~rfactor(n = 1,
               levels = c("Never and unknown",
                          "Former",
                          "Current"),
               p = c(0.8, 0.1, 0.1))
    ),
    
    imd = bn_node(
      ~rfactor(n = 1,
               levels = c("1 (least)",
                          "2",
                          "3",
                          "4",
                          "5 (most)"),
               p = c(0.19, 0.19, 0.19, 0.19, 0.19)),
      missing_rate = ~0.05
    ),
    
    region = bn_node(
      ~rfactor(n = 1,
               levels = c("North East",
                          "North West",
                          "Yorkshire and the Humber",
                          "East Midlands",
                          "West Midlands",
                          "East of England",
                          "London",
                          "South East"),
               p = rep(0.125, 8)),
      missing_rate = ~0.02
    ), 
    
    # multilevel comorbidities
    asthma = bn_node(
      ~rfactor(n = 1,
               levels = c("No asthma",
                          "With no oral steroid use",
                          "With oral steroid use"),
               p = c(0.9, 0.05, 0.05))
    ),
    
    diabetes_controlled = bn_node(
      ~rfactor(n = 1,
               levels = c("No diabetes",
                          "Controlled",
                          "Not controlled",
                          "Without recent Hb1ac measure"),
               p = c(0.85, 0.05, 0.05, 0.05))
    ),
    
    dialysis_kidney_transplant = bn_node(
      ~rfactor(n = 1,
               levels = c("No dialysis",
                          "With previous kidney transplant",
                          "Without previous kidney transplant"),
               p = c(0.9, 0.05, 0.05))
    ),
    
    ckd = bn_node(
      ~rfactor(n = 1,
               levels = c("No CKD",
                          "Stage 0",
                          "Stage 3a",
                          "Stage 3b",
                          "Stage 4",
                          "Stage 5"),
               p = c(0.95, 0.01, 0.01, 0.01, 0.01, 0.01))
    ),
    
    organ_kidney_transplant = bn_node(
      ~rfactor(n = 1,
               levels = c("No transplant",
                          "Kidney transplant",
                          "Other organ transplant"),
               p = c(0.9, 0.05, 0.05))
    ),
    
    # binary comorbidities
    hypertension = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    chronic_respiratory_disease = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    chronic_cardiac_disease = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    cancer = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    haem_cancer = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    chronic_liver_disease = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    stroke = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    dementia = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    other_neuro = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    apslenia = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    ra_sle_psoriasis = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    immunosuppression = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    learning_disability = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    sev_mental_ill = bn_node(
      ~rbernoulli(n = 1,
                  p = 0.1)
    ),
    
    died_any_day = bn_node(
      ~as.integer(runif(n = 1, 
                        0, 
                        difftime(end_date_wave1, start_date_wave1))),
      missing_rate = ~0.95 #0.05 prob of dying
    ),
    
    died_ons_covid_flag_any_day = bn_node(
      ~died_any_date,
      missing_rate = ~0.3, #70% of deaths attibutable to covid 
      needs = "died_any_date"
    ),
  )
}
sim_list_wave1 <- create_sim_list()
bn <- bn_create(sim_list_wave1, 
                known_variables = known_variables_wave1)

bn_plot(bn)
bn_plot(bn, connected_only=TRUE)


dummydata <- bn_simulate(bn, 
                         pop_size = population_size, 
                         keep_all = FALSE, 
                         .id="patient_id")
 
dummydata_processed <- dummydata %>%
  mutate(
    
  ) %>%
  #convert logical to integer as study defs output 0/1 not TRUE/FALSE
  #mutate(across(where(is.logical), ~ as.integer(.))) %>%
  #convert integer days to dates since index date and rename vars
  mutate(across(ends_with("_day"), ~ as.Date(as.character(start_date_wave1 + .)))) %>%
  rename_with(~str_replace(., "_day", "_date"), ends_with("_day"))


fs::dir_create(here("lib", "dummydata"))
write_feather(dummydata_processed, sink = here("lib", "dummydata", "dummyinput.feather"))

### CREATE AGEGROUP and died_ons_covid_flag_any