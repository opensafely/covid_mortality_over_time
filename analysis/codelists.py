######################################

# Some covariates used in the study are created from codelists of clinical conditions or 
# numerical values available on a patient's records.
# This script fetches all of the codelists identified in codelists.txt from OpenCodelists.

######################################

# --- IMPORT STATEMENTS ---
## Import code building blocks from cohort extractor package
from cohortextractor import (
    codelist,
    codelist_from_csv,
)

# --- CODELISTS ---
## DEMOGRAPHICS
### Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

### Smoking
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

## COMORBIDITIES
### Hypertension diagnosis
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv",
    system="ctv3",
    column="CTV3ID",
)

### Chronic respiratory disease diagnosis
chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

### Asthma diagnosis
asthma_codes = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Presence of a prescription for a course of prednisolone (likely to be related to poor asthma control)
pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)

### Chronic cardiac disease diagnosis
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Diabetes diagnosis
diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Measures of hba1c 
hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")

hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")

### Cancer diagnosis
haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", 
    system="ctv3",
    column="CTV3ID",
)

lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", 
    system="ctv3", 
    column="CTV3ID",
)

other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)

### Measure of creatinine
creatinine_codes = codelist(["XE2q5"], system="ctv3")

### Renal replacement therapy
renal_replacement_codes = codelist_from_csv(
    "codelists/opensafely-renal-replacement-therapy.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Dialysis
dialysis_codes = codelist_from_csv(
  "codelists/opensafely-dialysis.csv", 
  system = "ctv3", 
  column = "CTV3ID"
)

### Chronic liver disease diagnosis
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Stroke
stroke = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Dementia diagnosis
dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Other neurolgoical conditions
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

### Presence of organ transplant
organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)

### Asplenia or dysplenia (acquired or congenital) diagnosis
spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Sickle cell disease diagnosis
sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)
 ### Rheumatoid/Lupus/Psoriasis diagnosis
ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", 
    system="ctv3", 
    column="CTV3ID",
)

### Other immunosuppressive condition 
### (aplastic anaemia or permanent immunodeficiency ever diagnosed, or temporary immunodeficiency recorded within the last year)
aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", 
    system="ctv3", 
    column="CTV3ID",
)

permanent_immune_codes = codelist_from_csv(
    "codelists/opensafely-permanent-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)

temp_immune_codes = codelist_from_csv(
    "codelists/opensafely-temporary-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)

## OUTCOMES
### U071: COVID-19, virus identified
### U072: COVID-19, virus not identified
covid_codelist = codelist(["U071", "U072"], system="icd10")

covidconf_codelist = codelist(["U071"], system="icd10")