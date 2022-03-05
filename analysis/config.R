## ###########################################################

##  This script:
## - Creates vectors of the demographics and comorbities

## linda.nab@thedatalab.com - 2022028
## ###########################################################

## Create vectors ---
### Demographics
demographics_vctr = c(
  "bmi",
  "ethnicity",
  "smoking_status",
  "imd",
  "region")

### Comorbidities
comorbidities_vctr = c(
  "hypertension",
  "chronic_respiratory_disease",
  "asthma",
  "chronic_cardiac_disease",
  "diabetes_controlled",
  "cancer",
  "haem_cancer",
  "dialysis_kidney_transplant",
  "ckd",
  "chronic_liver_disease",
  "stroke",
  "dementia",
  "other_neuro",
  "organ_kidney_transplant",
  "dysplenia",
  "sickle_cell",
  "ra_sle_psoriasis",
  "aplastic_anaemia",
  "permanent_immunodeficiency",
  "temporary_immunodeficiency",
  "learning_disability",
  "sev_mental_ill")