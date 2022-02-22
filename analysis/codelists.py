from cohortextractor import (
    codelist,
    codelist_from_csv,
)

# DEMOGRAPHICS
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

# COMORBIDITIES
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv",
    system="ctv3",
    column="CTV3ID",
)

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

asthma_codes = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis.csv", 
    system="ctv3", 
    column="CTV3ID",
)

pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)

ics_codes = codelist_from_csv(
    "codelists/opensafely-asthma-inhaler-steroid-medication.csv",
    system="snomed",
    column="id",
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID",
)

hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")

hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")

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

creatinine_codes = codelist(["XE2q5"], system="ctv3")

dialysis_codes = codelist_from_csv(
    "codelists/opensafely-chronic-kidney-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

stroke = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", 
    system="ctv3", 
    column="CTV3ID",
)

dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv", 
    system="ctv3", 
    column="CTV3ID",
)

other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)

spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", system="ctv3", column="CTV3ID"
)

sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", system="ctv3", column="CTV3ID"
)

ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", system="ctv3", column="CTV3ID"
)

aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", system="ctv3", column="CTV3ID"
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

hiv_codes = codelist_from_csv(
    "codelists/opensafely-hiv.csv", 
    system="ctv3", column="CTV3ID", 
    category_column="CTV3ID",
)

# OUTCOMES
covid_codelist = codelist(["U071", "U072"], system="icd10")

covidconf_codelist = codelist(["U071"], system="icd10")

