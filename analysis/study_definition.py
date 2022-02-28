######################################

# This script provides the formal specification of the study data that will be extracted from 
# the OpenSAFELY database.

######################################

# IMPORT STATEMENTS ----
## Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition, 
    patients,
    filter_codes_by_category,
    combine_codelists,
    Measure,
)

## Import codelists from codelist.py (which pulls them from the codelist folder)
from codelists import (
    clear_smoking_codes, # demographics
    hypertension_codes, # comorbidities
    chronic_respiratory_disease_codes,
    asthma_codes,
    pred_codes,
    chronic_cardiac_disease_codes,
    diabetes_codes,
    hba1c_new_codes,
    hba1c_old_codes,
    haem_cancer_codes,
    lung_cancer_codes,
    other_cancer_codes,
    creatinine_codes,
    renal_replacement_codes,
    dialysis_codes,
    chronic_liver_disease_codes,
    stroke,
    dementia,
    other_neuro,
    organ_transplant_codes,
    spleen_codes,
    sickle_cell_codes,
    ra_sle_psoriasis_codes,
    aplastic_codes,
    permanent_immune_codes,
    temp_immune_codes,
    learning_disability_codes,
    sev_mental_ill_codes,
    covid_codelist, # outcomes
    covidconf_codelist,
)

## Import study time variables
from config import start_date, end_date

# DEFINE STUDY POPULATION ----
## Define study population and variables
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.5,
    },
    # Set index date to start date
    index_date = start_date,
    # Define the study population
    ## IN AND EXCLUSION CRITERIA
    population=patients.satisfying(
        """
        (age >= 18) AND 
        has_follow_up
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 1 year", "index_date"
        ),
    ),
    ## DEMOGRAPHICS
    ### age 
    age = patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    ### sex 
    sex = patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    ### bmi
    bmi = patients.categorised_as(
        {
            "Not obese": "DEFAULT",
            "Obese I (30-34.9)": """ bmi_value >= 30 AND bmi_value < 35""",
            "Obese II (35-39.9)": """ bmi_value >= 35 AND bmi_value < 40""",
            "Obese III (40+)": """ bmi_value >= 40 AND bmi_value < 100""",
        # set maximum to avoid any impossibly extreme values being classified as obese
        },
        bmi_value = patients.most_recent_bmi(
        on_or_after = "index_date - 5 years",
        minimum_age_at_measurement = 16
        ),
        return_expectations = {
            "rate": "universal",
            "category": {
                "ratios": {
                "Not obese": 0.7,
                "Obese I (30-34.9)": 0.1,
                "Obese II (35-39.9)": 0.1,
                "Obese III (40+)": 0.1,
                }
            },
        },
    ),
    ### smoking status
    smoking_status = patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (
                       most_recent_smoking_code = 'N' AND ever_smoked
                    )
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations = {
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code = patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period = True,
            on_or_before = "index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before = "index_date",
        ),
    ),
    ### imd (index of multiple deprivation) quintile
    imd = patients.address_as_of(
        "index_date",
        returning = "index_of_multiple_deprivation",
        round_to_nearest = 100,
        return_expectations = {
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),   
    ### stp https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    stp = patients.registered_practice_as_of(
        "index_date",
        returning = "stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    ### region (one of NHS England 9 regions)
    region = patients.registered_practice_as_of(
        "index_date",
        returning = "nuts1_region_name",
        return_expectations = {
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),
    ## COMORBIDITIES
    ### Diagnosed hypertension
    hypertension = patients.with_these_clinical_events(
        hypertension_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Respiratory disease ex asthma
    chronic_respiratory_disease = patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Asthma
    asthma = patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND (
                  prednisolone_last_year = 0 OR 
                  prednisolone_last_year > 4
                )
            """,
            "2": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND
                prednisolone_last_year > 0 AND
                prednisolone_last_year < 5
                
            """,
        },
        return_expectations = {"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code = patients.with_these_clinical_events(
            asthma_codes, # imported from codelists.py
            between = ["index_date - 3 years", "index_date"],
        ),
        asthma_code_ever = patients.with_these_clinical_events(
            asthma_codes, # imported from codelists.py
        ),
        copd_code_ever = patients.with_these_clinical_events(
            chronic_respiratory_disease_codes # imported from codelists.py
        ),
        prednisolone_last_year = patients.with_these_medications(
            pred_codes, # imported from codelists.py
            between = ["index_date - 1 year", "index_date"],
            returning = "number_of_matches_in_period",
        ),
    ),
    ### Chronic heart disease
    chronic_cardiac_disease = patients.with_these_clinical_events(
        chronic_cardiac_disease_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Diabetes
    diabetes = patients.with_these_clinical_events(
        diabetes_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    hba1c_mmol_per_mol = patients.with_these_clinical_events(
        hba1c_new_codes, # imported from codelists.py
        returning = "numeric_value",
        between = ["index_date - 1 year", "index_date"],
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage = patients.with_these_clinical_events(
        hba1c_old_codes, # imported from codelists.py
        returning="numeric_value",
        between = ["index_date - 1 year", "index_date"],
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    ### Cancer
    cancer = patients.with_these_clinical_events(
        combine_codelists(
            lung_cancer_codes,
            other_cancer_codes
        ),
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM-DD",
    ),
    ### Haematological malignancy
    haem_cancer = patients.with_these_clinical_events(
        haem_cancer_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM-DD",
    ),
    ## Reduced kidney function
    creatinine = patients.with_these_clinical_events(
        creatinine_codes, # imported from codelists.py
        returning = "numeric_value",
        between = ["index_date - 1 year", "index_date"],
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),
    ### Renal replacement therapy
    rrt = patients.with_these_clinical_events(
        renal_replacement_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Dialysis
    dialysis = patients.with_these_clinical_events(
        dialysis_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Liver disease
    chronic_liver_disease = patients.with_these_clinical_events(
        chronic_liver_disease_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Stroke
    stroke = patients.with_these_clinical_events(
        stroke, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Dementia
    dementia = patients.with_these_clinical_events(
        dementia, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Other neurological disease
    other_neuro = patients.with_these_clinical_events(
        other_neuro, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Organ transplant
    organ_transplant = patients.with_these_clinical_events(
        organ_transplant_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Asplenia (splenectomy or a spleen dysfunction, including sickle cell disease)
    dysplenia = patients.with_these_clinical_events(
        spleen_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    sickle_cell = patients.with_these_clinical_events(
        sickle_cell_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ### Rheumatoid/Lupus/Psoriasis
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ## Other immunosuppressive condition (permanent immunodeficiency ever diagnosed, or aplastic anaemia or temporary immunodeficiency recorded within the last year)
    aplastic_anaemia = patients.with_these_clinical_events(
        aplastic_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),  
    permanent_immunodeficiency = patients.with_these_clinical_events(
        permanent_immune_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    temporary_immunodeficiency = patients.with_these_clinical_events(
        temp_immune_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ## Learning disabilities
    learning_disability = patients.with_these_clinical_events(
        learning_disability_codes,
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ## Severe mental illness
    sev_mental_ill = patients.with_these_clinical_events(
        sev_mental_ill_codes,
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    ## OUTCOMES
    ### Patients with ONS-registered death
    died_ons_covid_flag_any = patients.with_these_codes_on_death_certificate(
        covid_codelist, # imported from codelists.py
        returning = "binary_flag",
        between = ["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause = False, # boolean for indicating if filters results to only specified cause of death
        return_expectations = {
            "rate" : "exponential_increase"
        },
    ),
    died_ons_covid_flag_underlying = patients.with_these_codes_on_death_certificate(
        covid_codelist, # imported from codelists.py
        returning = "binary_flag",
        between = ["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause = True,
        return_expectations = {
            "rate" : "exponential_increase"
        },
    ),
    ### Patients with ONS-registered death **covidconf**
    died_ons_covidconf_flag_any = patients.with_these_codes_on_death_certificate(
        covidconf_codelist, # imported from codelists.py
        returning = "binary_flag",
        between = ["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause = False,
        return_expectations = {
            "rate" : "exponential_increase"
        },
    ),
    died_ons_covidconf_flag_underlying = patients.with_these_codes_on_death_certificate(
        covidconf_codelist, # imported from codelists.py
        returning = "binary_flag",
        between = ["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause = True,
        return_expectations = {
            "rate" : "exponential_increase"
        },
    ),
)

# calculate crude mortality rate
measures = [
    Measure(
        id="crude_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by="population",
    ),
]