## ###########################################################

##  This script:
## - Contains a function that is used to calculate egfr from creatinine levels
## - Contains a function that is used to categories patients to ckd/rrt

## linda.nab@thedatalab.com - 20220527
## ###########################################################

# Load libraries & functions ---
## function 'calc_min_creatinine'
## Arguments:
## SCR_adj: numeric, serum creatinine levels in mg/dl
## sex: factor ("F" or "M")
## Output:
## minimum of SCR_adj / k and 1 to the power of l (with k and l different for
## females and males, see function)
## note that equation for males is used if sex is missing, which is in this 
## study pop never the case (only people with non missing sex are included)
calc_min_creatinine <- function(SCR_adj, sex){
  if (sex == "M" | is.na(sex)){
    out <- min(SCR_adj / 0.9, 1) ^ -0.411
  } else if (sex == "F"){
    out <- min(SCR_adj / 0.7, 1) ^ -0.329
  }
  out
}
## function 'calc_max_creatinine'
## Arguments:
## SCR_adj: numeric, serum creatinine levels in mg/dl
## sex: factor ("F" or "M")
## Output:
## maximum of SCR_adj / k and 1 to the power of -1.209 (with k different for
## males and females)
## note that equation for males is used if sex is missing, which is in this 
## study pop never the case (only people with non missing sex are included)
calc_max_creatinine <- function(SCR_adj, sex){
  if (sex == "M" | is.na(sex)){
    out <- max(SCR_adj / 0.9, 1) ^ -1.209
  } else if (sex == "F"){
    out <- max(SCR_adj / 0.7, 1) ^ -1.209
  }
  out
}

# Function ---
## Function 'calc_egfr' calculates estimated Glomerular Filtration Rate
## based on the ckd-epi formula
## see https://docs.google.com/document/d/1hi_lMyuAa23u1xXLULLMdAiymiPopPZrAtQCDzYtjtE/edit
## for logic
## Arguments:
## creatinine: numeric with creatinine level
## creatinine_operator: character with operator (None, >, <, >=, <=, ~)
## sex: factor ("F" or "M")
## creatinine_age: numeric, age at measurement of creatinine
## Output:
## egfr based on creatinine level
calc_egfr <- function(creatinine, creatinine_operator, creatinine_age, sex){
  if (is.na(creatinine)) {
    out <- NA_integer_
  } else if (is.na(creatinine_age)) {
    out <- NA_integer_
  # set ambiguous creatinine levels to missing
  } else if (!is.na(creatinine_operator) && creatinine_operator != "="){
    out <- NA_integer_
  # set implausible creatinine values to missing
  } else if (creatinine < 20 | creatinine > 3000){
    out <- NA_integer_
  } else {
    SCR_adj <- creatinine / 88.4 # divide by 88.4 (to convert umol/l to mg/dl)
    min_creat <- calc_min_creatinine(SCR_adj, sex)
    max_creat <- calc_max_creatinine(SCR_adj, sex)
    egfr <- (min_creat * max_creat * 141) * (0.993 ^ creatinine_age)
    if (!is.na(sex) && sex == "F") egfr <- egfr * 1.018 # note that if is.na(sex), male eq is used
    out <- egfr
  }
  out
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
## - egfr: numeric containing estimated Glomerular Filtration Rate
## - rrt_cat: numeric ("0"; "1"; "2")
## Output:
## character of one of the above described categories
categorise_ckd_rrt <- function(egfr, rrt_cat){
  if (rrt_cat == "1"){
    out <- "RRT (dialysis)"
  } else if (rrt_cat == "2"){
    out <- "RRT (transplant)"
  } else if (is.na(egfr) & rrt_cat == "0"){
      out <- "No CKD or RRT"
  } else if (!is.na(egfr) & rrt_cat == "0"){ # it is assumed egfr >= 0
    if (egfr >= 0 & egfr < 15){
      out <- "Stage 5"
    } else if (egfr >= 15 & egfr < 30){
      out <- "Stage 4"
    } else if (egfr >= 30 & egfr < 45){
      out <- "Stage 3b"
    } else if (egfr >= 45 & egfr < 60){
      out <- "Stage 3a"
    } else if (egfr >= 60){
      out <- "No CKD or RRT"
    }
  }
  out
}