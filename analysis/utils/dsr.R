## ###########################################################

##  This script:
## - Contains functions to calculate dsr_i and var_dsr_i

## linda.nab@thedatalab.com - 20220330
## ###########################################################

## Functions used for the calculation of direct standardised rates and its 
## variance.
## The direct standardised rate (DSR) = sum_i dsr_i
## Details can be found in 
## https://docs.google.com/document/d/1Slo6FxC2Jv2qrqz5T4rnH_VXJhRajq7bKc_pcuveV5s/edit#

# Functions ---
## input:
## - C: constant, e.g. 100,000 for rates per 100000 population 
## - M_total: total number of people in the reference population
## - p: number of deaths in age stratum / study population
## - M: number of people in reference population in age stratum
## output:
## if the output of this function is summed over age, one obtains
## the direct standardised rate.
calc_dsr_i <- function(C, M_total, p, M){
  # for each age category, the expected number of 
  # deaths in the reference population is the age
  # specific rate (p) times the number of people in the reference population (M)
  # The direct standardised rate is the sum over age of the 
  # expected number of deaths divided by the total number of people in the 
  # reference population (M_total).
  # (In this case, M_total is inside summation, as a constant * sum (i) = 
  # sum (constant * i))
  # C is to calculate DSR per 100,000 pop or when standardising to a
  # month of 30 days.
  # --> summation of the dsr_i terms over age = DSR
  dsr_i <- (C / M_total) * p * M
  dsr_i
}
## input:
## - C: constant, e.g. 100,000 for rates per 100000 population 
## - M_total: total number of people in the reference population
## - p: number of deaths in age stratum / number of people in study population in age stratum
## - M: number of people in reference population in age stratum
## - N: number of people in study population in age stratum
## output:
## if the output of this function is summed over age, one obtains
## the variance of the direct standardised rate.
calc_var_dsr_i <- function(C, M_total, p, M, N){
  # C, M, N are assumed fixed 
  # and p = number of deaths / N is assumed to follow a binomial distribution
  # var(p) = N * p * (1 - p)
  # see for details the Google doc in header
  (C^2 / M_total^2) * (M^2 / N) * p * (1 - p)
}
