## ###########################################################

##  This script makes a table for the appendix describing the 
##  codelists used in this project

## copied from: https://github.com/opensafely/comparative-booster/blob/main/codelists/codelists_to_html.R
## ###########################################################

# Load libraries & functions ---
library('tidyverse')
library('here')
library('gt')

# import codelists from json ---
codelists <- jsonlite::read_json(
  path=here("codelists", "codelists.json")
)

# reformat ---
codelists_formatted <- enframe(codelists[[1]]) %>% unnest_wider(value) %>%
  mutate(
    file = name,
    name= str_extract(id, "(?<=/)(.+)(?=/)"),
    downloaded_at = as.Date(downloaded_at, "%Y-%m-%d")
  )

# output to html ---
codelists_formatted %>%
  select(name, url, downloaded_at) %>%
  gt() %>%
  cols_label(
    name = "Name",
    url = "URL",
    downloaded_at = "Accessed on"
  ) %>%
  gtsave(here("codelists", "codelists.html"))
