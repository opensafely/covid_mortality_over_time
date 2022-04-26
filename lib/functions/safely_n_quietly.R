# code by: https://github.com/tidyverse/purrr/issues/426

library(purrr)

safely_n_quietly <- function(.f, otherwise = NULL) {
  retfun <- quietly(safely(.f, otherwise = otherwise, quiet = FALSE))
  function(...) {
    ret <- retfun(...)
    list(result = ret$result$result,
         output = ret$output,
         messages = ret$messages,
         warnings = ret$warnings,
         error = ret$result$error)
  }
}