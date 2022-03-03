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
    dialysis_codes,
    kidney_transplant_codes,
    egfr_codes,
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
    ### age group (used for descriptives)
    agegroup = patients.categorised_as(
        {
            "18-39": "age >= 18 AND age < 40",
            "40-49": "age >= 40 AND age < 50",
            "50-59": "age >= 50 AND age < 60",
            "60-69": "age >= 60 AND age < 70",
            "70-79": "age >= 70 AND age < 80",
            "80plus": "age >= 80",
            "missing": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "18-39": 0.17,
                    "40-49": 0.17,
                    "50-59": 0.17,
                    "60-69": 0.17,
                    "70-79": 0.17,
                    "80plus": 0.13,
                    "missing": 0.02,
                }
            },
        },
    ),   
    ### age group (used for age standardisation)
    agegroup_std = patients.categorised_as(
        {
            "15-19": "age >= 15 AND age < 20",
            "20-24": "age >= 20 AND age < 25",
            "25-29": "age >= 25 AND age < 30",
            "30-34": "age >= 30 AND age < 35",
            "35-39": "age >= 35 AND age < 40",
            "40-44": "age >= 40 AND age < 45",
            "45-49": "age >= 45 AND age < 50",
            "50-54": "age >= 50 AND age < 55",
            "55-59": "age >= 55 AND age < 60",
            "60-64": "age >= 60 AND age < 65",
            "65-69": "age >= 65 AND age < 70",
            "70-74": "age >= 70 AND age < 75",
            "75-79": "age >= 75 AND age < 80",
            "80-84": "age >= 80 AND age < 85",
            "85-89": "age >= 85 AND age < 90",
            "90plus": "age >= 90",
            "missing": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "15-19": 0.05,
                    "20-24": 0.05,
                    "25-29": 0.05,
                    "30-34": 0.05,
                    "35-39": 0.05,
                    "40-44": 0.1,
                    "45-49": 0.1,
                    "50-54": 0.1,
                    "55-59": 0.1,
                    "60-64": 0.05,
                    "65-69": 0.05,
                    "70-74": 0.05,
                    "75-79": 0.05,
                    "80-84": 0.05,
                    "85-89": 0.05,
                    "90plus": 0.03,
                    "missing": 0.02,
                }
            },
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
    imd = patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation < 32844""",
        },
        index_of_multiple_deprivation=patients.address_as_of(
            "index_date",
            returning = "index_of_multiple_deprivation",
            round_to_nearest = 100,
        ),
        return_expectations = {
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                }
            },
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
            chronic_respiratory_disease_codes, # imported from codelists.py
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
    #### variable indicating whether patient has had a recent test yes/no
    hba1c_flag = patients.with_these_clinical_events(
        combine_codelists(
            hba1c_new_codes,
            hba1c_old_codes
        ),
        returning = "binary_flag",
        between = ["index_date - 15 months", "index_date"],
        find_last_match_in_period = True,
        return_expectations = {
            "incidence": 0.95,
        },
    ),
    #### hba1c value in mmol/mol of recent test
    hba1c_mmol_per_mol = patients.with_these_clinical_events(
        hba1c_new_codes, # imported from codelists.py
        returning = "numeric_value",
        between = ["index_date - 15 months", "index_date"],
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    #### hba1c value in % of recent test
    hba1c_percentage = patients.with_these_clinical_events(
        hba1c_old_codes, # imported from codelists.py
        returning = "numeric_value",
        between = ["index_date - 15 months", "index_date"],
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    #### Subcategorise recent hba1c measures in no recent measure (0); measure indicating controlled diabetes (1);
    #### measure indicating uncontrolled diabetes (2)
    hba1c_category = patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                hba1c_flag AND (hba1c_mmol_per_mol < 58 OR 
                hba1c_percentage < 7.5)
            """,
            "2": """
                hba1c_flag AND (hba1c_mmol_per_mol >= 58 OR 
                hba1c_percentage >= 7.5)
            """,
        },
        return_expectations = {"category": {"ratios": {"0": 0.2, "1": 0.4, "2": 0.4}},},
    ),
    #### Subcategorise diabetes in no diabetes (0); controlled diabetes (1); uncontrolled diabetes (2); 
    #### diabetes with missing recent hba1c measure (3)
    diabetes_controlled = patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """ 
                diabetes AND hba1c_category = "1"
            """,
            "2": """
                diabetes AND hba1c_category = "2"
            """,
            "3": """
                diabetes AND hba1c_category = "3"
            """
        },
        return_expectations = {"category": {"ratios": {"0": 0.8, "1": 0.09, "2": 0.09, "3": 0.02}},},
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
    ### Dialysis
    dialysis = patients.with_these_clinical_events(
        dialysis_codes, # imported from codelists.py
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,
    ),
    #### Date of dialysis
    dialysis_date = patients.with_these_clinical_events(
        dialysis_codes, # imported from codelists.py
        returning = "date",
        on_or_before = "index_date",
        find_last_match_in_period = True,
        date_format = "YYYY-MM-DD",
    ),
    ### Kidney transplant 
    kidney_transplant = patients.with_these_clinical_events(
        kidney_transplant_codes,
        returning = "binary_flag",
        on_or_before = "index_date",
        find_last_match_in_period = True,        
    ),
    #### Date of kidney transplant
    kidney_transplant_date = patients.with_these_clinical_events(
        kidney_transplant_codes,
        returning = "date",
        on_or_before = "index_date",
        find_last_match_in_period = True, 
        date_format = "YYYY-MM-DD",       
    ),
    #### Categorise dialysis in dialysis with previous kidney transplant; dialysis without previous transplant
    dialysis_kidney_transplant = patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (dialysis AND kidney_transplant) AND kidney_transplant_date <= dialysis_date
            """,
            "2": """
                (dialysis AND NOT kidney_transplant) OR ((dialysis AND kidney_transplant) AND kidney_transplant_date > dialysis_date)
            """,
        },
        return_expectations = {"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
    ),
    ### eGFR 
    #### egfr_flag is needed because missing egfr values will be coded as 0, and we need to make a 
    #### distinction between missing and not missing in variable 'ckd' below
    egfr_flag = patients.with_these_clinical_events(
        egfr_codes, # imported from codelists.py
        returning = "binary_flag",
        find_last_match_in_period = True,
        return_expectations = {
            "incidence": 0.95,
        },
    ),
    egfr = patients.with_these_clinical_events(
        egfr_codes, # imported from codelists.py
        returning = "numeric_value",
        find_last_match_in_period = True,
        include_date_of_match = True,
        date_format = "YYYY-MM",
        return_expectations = {
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 45.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    ### CKD
    ckd = patients.categorised_as(
        {
            "No CKD": "DEFAULT",
            "0": """
                (NOT dialysis AND NOT kidney_transplant) AND (egfr_flag AND egfr >= 60)
            """,
            "3a": """
                (NOT dialysis AND NOT kidney_transplant) AND (egfr_flag AND (egfr >= 45 AND egfr < 60))
            """,
            "3b": """
                (NOT dialysis AND NOT kidney_transplant) AND (egfr_flag AND (egfr >= 30 AND egfr < 45))
            """,
            "4": """
                (NOT dialysis AND NOT kidney_transplant) AND (egfr_flag AND (egfr >= 15 AND egfr < 30))
            """,
            "5": """
                (NOT dialysis AND NOT kidney_transplant) AND (egfr_flag AND egfr < 15)
            """,
        },
        return_expectations = {"category": {"ratios": {"No CKD": 0.8, "0": 0.1, "3a": 0.025, "3b": 0.025, "4": 0.025, "5": 0.025}},},
    ),
    #### Exclude patients on dialysis / with a kidney transplant
    #### Based on eGFR, stage 0/ 3a/ 3b/ 4 or 5
    ### Renal replacement therapy
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
    ### Organ or kidney transplant
    organ_kidney_transplant = patients.categorised_as(
        {
            "No transplant": "DEFAULT",
            "Kidney": """
                kidney_transplant
            """,
            "Organ": """
                organ_transplant
            """,
        },
        return_expectations = {"category": {"ratios": {"No transplant": 0.95, "Kidney": 0.025, "Organ": 0.025}},},
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
            "rate" : "exponential_increase",
            "incidence" : 0.005,
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

measures = [
    # calculate crude mortality rate
    Measure(
        id = "crude_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = "population",
    ),
    # calculate subgroup specific rates
    Measure(
        id = "age_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup"],
    ),

    Measure(
        id = "sex_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex"],
    ),

    Measure(
        id = "bmi_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "bmi"],
    ),

    Measure(
        id = "ethnicity_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "ethnicity"],
    ),

    Measure(
        id = "imd_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "imd"],
    ),
]