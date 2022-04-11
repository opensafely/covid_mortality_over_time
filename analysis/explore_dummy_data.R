#############################################################
## EXPLORE DATA
##
## This script is to understand the dummy date
## linda.nab@thedatalab.com - 20220223
#############################################################

##---------------------Load libraries---------------------##
library(here)
library(readr)

## Import data
data <- read_csv(here("output", "input_2020-02-01.csv.gz"))


data_ethnicity <- read.csv(here("output", "input_ethnicity.csv"))
