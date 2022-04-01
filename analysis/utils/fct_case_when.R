## ###########################################################

##  This script:
## - Contains the function fct_case_when() used to change levels of a factor
##   and get them ordered

## linda.nab@thedatalab.com - 20220330
## ###########################################################

fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}
