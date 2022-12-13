## ###########################################################

##  This script:
## - Contains a function that is used to calculate egfr from creatinine levels
## - Contains a function that is used to categories patients to ckd/rrt

## linda.nab@thedatalab.com - 20220527
## ###########################################################

# Load libraries & functions ---
## function 'add_min_creatinine'
## Arguments:
## data: extracted data, with columns:
## SCR_adj: numeric, serum creatinine levels in mg/dl
## sex: factor ("F" or "M")
## Output:
## minimum of SCR_adj / k and 1 to the power of l (with k and l different for
## females and males, see function)
## note that equation for males is used if sex is missing, which is in this 
## study pop never the case (only people with non missing sex are included)
add_min_creatinine <- function(data){
  data <- 
    data %>%
    mutate(min_creat = if_else(sex == "M" | is.na(sex), 
                               pmin(SCR_adj / 0.9, 1) ^ -0.411,
                               pmin(SCR_adj / 0.7, 1) ^ -0.329))
}
## function 'add_max_creatinine'
## Arguments:
## data: extracted data, with columns:
## SCR_adj: numeric, serum creatinine levels in mg/dl
## sex: factor ("F" or "M")
## Output:
## maximum of SCR_adj / k and 1 to the power of -1.209 (with k different for
## males and females)
## note that equation for males is used if sex is missing, which is in this 
## study pop never the case (only people with non missing sex are included)
add_max_creatinine <- function(data){
  data <- 
    data %>%
    mutate(max_creat = if_else(sex == "M" | is.na(sex), 
                               pmax(SCR_adj / 0.9, 1) ^ -1.209,
                               pmax(SCR_adj / 0.7, 1) ^ -1.209))
}

# Function ---
## Function 'add_egfr' calculates estimated Glomerular Filtration Rate
## based on the ckd-epi formula
## see https://docs.google.com/document/d/1hi_lMyuAa23u1xXLULLMdAiymiPopPZrAtQCDzYtjtE/edit
## for logic
## Arguments:
## data: extracted_data, with columns:
## creatinine: numeric with creatinine level
## creatinine_operator: character with operator (None, >, <, >=, <=, ~)
## sex: factor ("F" or "M")
## creatinine_age: numeric, age at measurement of creatinine
## Output:
## egfr based on creatinine level
add_egfr <- function(data){
  data <-
    data %>%
    mutate(egfr = case_when(
      is.na(creatinine) ~ NA_real_,
      is.na(creatinine_age) ~ NA_real_,
      (!is.na(creatinine_operator) & creatinine_operator != "=") ~ NA_real_,
      creatinine < 20 | creatinine > 3000 ~ NA_real_,
      TRUE ~ (min_creat * max_creat * 141) * (0.993 ^ creatinine_age)),
      egfr = if_else(!is.na(sex) & sex == "F",
                     1.018 * egfr,
                     egfr))
}
## Function 'categorise_ckd_rrt' categorises an individual into one of the 
## following categories:
## No CKD or RRT; RRT (dialysis); RRT (transplant); CKD Stage 5; 
## CKD Stage 4; CKD Stage 3b; CKD Stage 3a
## first is checked if someone is on dialysis or has a kidney transplant (rrt),
## if not rrt, and egfr is missing --> No CKD or RRT
## if not rrt and egfr is not missing --> classify into stage 
## 5/4/3b/3a/No CKD or RRT
## Arguments:
## data: extracted_data, with columns:
## - egfr: numeric containing estimated Glomerular Filtration Rate
## - rrt_cat: numeric ("0"; "1"; "2")
## Output:
## character of one of the above described categories
categorise_ckd_rrt <- function(data){
  data <-
    data %>% 
    mutate(ckd_rrt = case_when(
      rrt_cat == "1" ~ "RRT (dialysis)",
      rrt_cat == "2" ~ "RRT (transplant)",
      (is.na(egfr) & rrt_cat == "0") ~ "No CKD or RRT",
      (egfr >= 0 & egfr < 15) ~ "Stage 5",
      (egfr >= 15 & egfr < 30) ~ "Stage 4",
      (egfr >= 30 & egfr < 45) ~ "Stage 3b",
      (egfr >= 45 & egfr < 60) ~ "Stage 3a",
      (egfr >= 60) ~ "No CKD or RRT")
    )
}