#############################################################
## JOIN ETHNICITY DATA AND THE OTHER VARIABLES
##
## 
## linda.nab@thedatalab.com - 2022024
#############################################################

##---------------------Load libraries---------------------##
library(here)
library(dplyr)

##-----------------------Load data------------------------##
data <- 
  read.csv(here("output", "data", "input.csv"))
data_ethnicity <- 
  read.csv(here("output", "data", "input_ethnicity.csv"))

##----------------------Work horse------------------------##
# Join data
data_joined <-
  data %>%
  left_join(data_ethnicity %>% select(patient_id, ethnicity),
            by = "patient_id") 

##----------------------Save data-------------------------##
saveRDS(data_joined, 
        here("output", "data", "data_joined.rds"),
        compress = TRUE)