## ###########################################################

##  This script:
##  - Tests the kidney_functions in ./analysis/utils/kidney_functions.R

## linda.nab@thedatalab.com - 20220528
## ###########################################################

# Load libraries & custom functions ---
library(dplyr)
library(here)
source(here("analysis", "utils", "kidney_functions.R"))

# Test function 'calc_egfr()' --
## data.frame with all possible combinations
test_data1 <- 
  expand.grid(creatinine = c(10, 4000, 20, 3000, 60, NA_integer_),
              creatinine_operator = c("=",
                                      "~",
                                      "<", 
                                      "<=",
                                      ">",
                                      ">=",
                                      NA_character_),
              creatinine_age = c(50, NA_integer_),
              sex = c("F", "M", NA_character_))
## use calc_egfr to add column 'egfr'
test_data1 <- 
  test_data1 %>%
  mutate(SCR_adj = creatinine / 88.4) %>% # divide by 88.4 (to convert umol/l to mg/dl))
  add_min_creatinine() %>%
  add_max_creatinine() %>%
  add_egfr()

## egfr should only be not NA if
## creatine in not NA, 20 <= creatinine <= 3000, creatine_operator is NA or "=",
## and creatine_age is not NA 
## if sex is missing --> CKD-epi formula for males is used
## see https://docs.google.com/document/d/1hi_lMyuAa23u1xXLULLMdAiymiPopPZrAtQCDzYtjtE/edit
## for logic (step 0)
(with(test_data1, which(!is.na(creatinine) & 
                         between_vectorised(creatinine, 20, 3000) & 
                         (is.na(creatinine_operator) | creatinine_operator == "=") &
                         !is.na(creatinine_age))) ==
with(test_data1, which(!is.na(egfr)))) %>% all()

# Test function 'categoris_ckd_rrt()' ---
## data.frame with all important corner cases
## see https://docs.google.com/document/d/1hi_lMyuAa23u1xXLULLMdAiymiPopPZrAtQCDzYtjtE/edit
## for logic (step 2)
## for rrt_cat, following mapping is used:
## 0: no rrt
## 1: rrt (dialysis)
## 2: rrt (kidney transplant)
test_data2 <- 
  cbind.data.frame(rrt_cat = c(rep(0, 11), # --> CKD?
                             rep(1, 2), # RRT (dialyis) regardless of egfr
                             rep(2, 2)), # RRT (transplant) regardless of egfr
                   egfr  = c(0, 7.5, 
                             15, 22.5, 
                             30, 37.5,
                             45, 52.5,
                             60, 65, NA_integer_,
                             10, NA_integer_,
                             0, NA_integer_),
                   ckd_rrt_ref = c(rep("Stage 5", 2),
                                   rep("Stage 4", 2),
                                   rep("Stage 3b", 2),
                                   rep("Stage 3a", 2),
                                   rep("No CKD or RRT", 3),
                                   rep("RRT (dialysis)", 2),
                                   rep("RRT (transplant)", 2))
                   )
## use 'categorise_ckd_rrt()' to add column ckd_rrt
test_data2 <- 
  test_data2 %>%
  categorise_ckd_rrt()

## check if categories created by 'categorise_ckd_rrt()' are as wanted
(test_data2$ckd_rrt_ref == test_data2$ckd_rrt) %>% all()       
