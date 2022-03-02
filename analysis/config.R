## ###########################################################

##  This script:
## - creates a sequence of dates that is equal to the range of dates used by
##   the argument --index-date-range "2020-02-01 to 2021-12-01 by month"
##   in project.yaml

## linda.nab@thedatalab.com - 2022028
## ###########################################################

### Config start date and end date
create_seq_dates <- function(start_date = lubridate::ymd("20200201"), 
                             end_date = lubridate::ymd("20211201")){
  ### Calculate number of months between end date and start date:
  number_of_months <- 
    lubridate::interval(start_date, end_date) %/% months(1)
  ### Create a sequence of dates, starting with start_date:
  months <- seq(start_date, by = "month", length.out = number_of_months)
  ### Add end_date to sequence:
  months_including_end_date <- c(months, end_date)
  return(months_including_end_date)
}