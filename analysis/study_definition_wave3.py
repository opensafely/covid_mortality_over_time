######################################

# This script provides the formal specification of the study data that will
# be extracted from the OpenSAFELY database.
# This data extract is the data extract for one of the UK pandemic waves
# (see file name which wave)
# (see config.json for start and end dates of the wave)

######################################

# IMPORT STATEMENTS ----
# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
    filter_codes_by_category,
    combine_codelists,
)

# Import codelists from codelist.py (which pulls them from the codelist folder)
from codelists import (
    clear_smoking_codes,  # demographics
    hypertension_codes,  # comorbidities
    chronic_respiratory_disease_codes,
    asthma_codes,
    systolic_blood_pressure_codes,
    diastolic_blood_pressure_codes,
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
    other_organ_transplant_codes,
    spleen_codes,
    sickle_cell_codes,
    ra_sle_psoriasis_codes,
    immunosupression_diagnosis_codes,
    immunosuppression_medication_codes,
    learning_disability_codes,
    sev_mental_ill_codes,
    covid_codelist,  # outcomes
)

# Import config variables (start_date and end_date of wave1)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

wave3 = config["wave3"]
start_date = wave3["start_date"]
end_date = wave3["end_date"]

# DEFINE STUDY POPULATION ----
# Define study population and variables
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.95,
    },
    # Set index date to start date
    index_date=start_date,
    # Define the study population
    # IN AND EXCLUSION CRITERIA
    # (= > 1 year follow up, aged > 18 and no missings in age and sex)
    # missings in age are the ones > 110
    # missings in sex can be sex = U or sex = I (so filter on M and F)
    population=patients.satisfying(
        """
        has_follow_up AND
        NOT died AND
        (age >=18 AND age <= 110) AND
        (sex = "M" OR sex = "F") AND
        NOT stp = "" AND
        imd > 0
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 3 months", "index_date"
        ),
        died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.01},
        ),
    ),
    # DEMOGRAPHICS
    # age
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # age group (used for descriptives)
    agegroup=patients.categorised_as(
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
                    "80plus": 0.15,
                    "missing": 0,
                }
            },
        },
    ),
    # age group (used for age standardisation)
    agegroup_std=patients.categorised_as(
        {
            "15-19 years": "age >= 15 AND age < 20",
            # (age is always >= 18 in this study)
            "20-24 years": "age >= 20 AND age < 25",
            "25-29 years": "age >= 25 AND age < 30",
            "30-34 years": "age >= 30 AND age < 35",
            "35-39 years": "age >= 35 AND age < 40",
            "40-44 years": "age >= 40 AND age < 45",
            "45-49 years": "age >= 45 AND age < 50",
            "50-54 years": "age >= 50 AND age < 55",
            "55-59 years": "age >= 55 AND age < 60",
            "60-64 years": "age >= 60 AND age < 65",
            "65-69 years": "age >= 65 AND age < 70",
            "70-74 years": "age >= 70 AND age < 75",
            "75-79 years": "age >= 75 AND age < 80",
            "80-84 years": "age >= 80 AND age < 85",
            "85-89 years": "age >= 85 AND age < 90",
            "90plus years": "age >= 90",
            "missing": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "15-19 years": 0.05,
                    "20-24 years": 0.05,
                    "25-29 years": 0.05,
                    "30-34 years": 0.05,
                    "35-39 years": 0.05,
                    "40-44 years": 0.1,
                    "45-49 years": 0.1,
                    "50-54 years": 0.1,
                    "55-59 years": 0.1,
                    "60-64 years": 0.05,
                    "65-69 years": 0.05,
                    "70-74 years": 0.05,
                    "75-79 years": 0.05,
                    "80-84 years": 0.05,
                    "85-89 years": 0.05,
                    "90plus years": 0.05,
                    "missing": 0,
                }
            },
        },
    ),
    # sex
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # bmi
    # set maximum to avoid any impossibly extreme values being classified as
    # obese
    bmi_value=patients.most_recent_bmi(
        on_or_after="index_date - 5 years",
        minimum_age_at_measurement=16,
        return_expectations={
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 25.0, "stddev": 7.5},
            "incidence": 0.8,
        },
    ),
    bmi=patients.categorised_as(
        {
            "Not obese": "DEFAULT",
            "Obese I (30-34.9)": """ bmi_value >= 30 AND bmi_value < 35""",
            "Obese II (35-39.9)": """ bmi_value >= 35 AND bmi_value < 40""",
            "Obese III (40+)": """ bmi_value >= 40 AND bmi_value < 100""",
        },
        return_expectations={
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
    # smoking status
    smoking_status=patients.categorised_as(
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
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "S": 0.6,
                    "E": 0.1,
                    "N": 0.2,
                    "M": 0.1,
                }
            },
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="index_date",
        ),
    ),
    # smoking status (combining never and missing)
    smoking_status_comb=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (
                       most_recent_smoking_code = 'N' AND ever_smoked
                    )
                """,
            "N + M": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N + M": 0.3}, }
        },
    ),
    # imd (index of multiple deprivation) quintile
    index_of_multiple_deprivation=patients.address_as_of(
            date="index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
            return_expectations={
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
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND
                index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND
                index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND
                index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND
                index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND
                index_of_multiple_deprivation < 32844""",
        },
        return_expectations={
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
    # stp https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
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
    # region (one of NHS England 9 regions)
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
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
    # COMORBIDITIES
    # Diagnosed hypertension
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Respiratory disease ex asthma
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Asthma
    asthma=patients.categorised_as(
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
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "0": 0.8,
                                        "1": 0.1,
                                        "2": 0.1
                                        }
                                    },
                                },
        recent_asthma_code=patients.with_these_clinical_events(
            asthma_codes,  # imported from codelists.py
            between=["index_date - 3 years", "index_date"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(
            asthma_codes,  # imported from codelists.py
        ),
        copd_code_ever=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes,  # imported from codelists.py
        ),
        prednisolone_last_year=patients.with_these_medications(
            pred_codes,  # imported from codelists.py
            between=["index_date - 1 year", "index_date"],
            returning="number_of_matches_in_period",
        ),
    ),
    # Blood pressure
    # filtering on >0 as missing values are returned as 0
    bp=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                    (bp_sys > 0 AND bp_sys < 120) AND
                        (bp_dia > 0 AND bp_dia < 80)
            """,
            "2": """
                    ((bp_sys >= 120 AND bp_sys < 130) AND
                        (bp_dia > 0 AND bp_dia < 80)) OR
                    ((bp_sys >= 130) OR
                        (bp_dia >= 80))
            """,
        },
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "0": 0.8,
                                        "1": 0.1,
                                        "2": 0.1
                                        }
                                    },
                                },
        bp_sys=patients.mean_recorded_value(
            systolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before="index_date",
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "incidence": 0.6,
                "float": {"distribution": "normal", "mean": 80, "stddev": 10},
            },
        ),
        bp_dia=patients.mean_recorded_value(
            diastolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before="index_date",
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "incidence": 0.6,
                "float": {"distribution": "normal", "mean": 120, "stddev": 10},
            },
        ),
    ),
    # Chronic heart disease
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Diabetes
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # variable indicating whether patient has had a recent test yes/no
    hba1c_flag=patients.with_these_clinical_events(
        combine_codelists(
            hba1c_new_codes,
            hba1c_old_codes
        ),
        returning="binary_flag",
        between=["index_date - 15 months", "index_date"],
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.95,
        },
    ),
    # hba1c value in mmol/mol of recent test
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes,  # imported from codelists.py
        returning="numeric_value",
        between=["index_date - 15 months", "index_date"],
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM",
        return_expectations={
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    # hba1c value in % of recent test
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,  # imported from codelists.py
        returning="numeric_value",
        between=["index_date - 15 months", "index_date"],
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM",
        return_expectations={
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    # Subcategorise recent hba1c measures in no recent measure (0); measure
    # indicating controlled diabetes (1);
    # measure indicating uncontrolled diabetes (2)
    hba1c_category=patients.categorised_as(
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
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "0": 0.2,
                                        "1": 0.4,
                                        "2": 0.4
                                        }
                                    },
                                },
    ),
    # Subcategorise diabetes in no diabetes (0); controlled diabetes (1);
    # uncontrolled diabetes (2);
    # diabetes with missing recent hba1c measure (3)
    diabetes_controlled=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                diabetes AND hba1c_category = "1"
                """,
            "2": """
                diabetes AND hba1c_category = "2"
                """,
            "3": """
                diabetes AND hba1c_category = "0"
                """
        }, return_expectations={
                                "category": {
                                    "ratios": {
                                        "0": 0.8,
                                        "1": 0.09,
                                        "2": 0.09,
                                        "3": 0.02
                                        }
                                    },
                                },
    ),
    # Cancer
    cancer=patients.with_these_clinical_events(
        combine_codelists(
            lung_cancer_codes,
            other_cancer_codes
        ),
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
    ),
    # Haematological malignancy
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
    ),
    # Dialysis
    dialysis=patients.with_these_clinical_events(
        dialysis_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,  # generates dialysis_date
        date_format="YYYY-MM-DD",
    ),
    # Kidney transplant
    kidney_transplant=patients.with_these_clinical_events(
        kidney_transplant_codes,
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,  # generates kidney_transplant_date
        date_format="YYYY-MM-DD",
    ),
    # Categorise dialysis in dialysis with previous kidney transplant;
    # dialysis without previous transplant
    dialysis_kidney_transplant=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (dialysis AND kidney_transplant) AND
                kidney_transplant_date <= dialysis_date
            """,
            "2": """
                (dialysis AND NOT kidney_transplant) OR
                ((dialysis AND kidney_transplant) AND
                kidney_transplant_date > dialysis_date)
            """,
        },
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "0": 0.8,
                                        "1": 0.1,
                                        "2": 0.1
                                        }
                                    },
                                },
    ),
    # eGFR
    # egfr_flag is needed because missing egfr values will be coded as 0, and
    # we need to make a distinction between missing and not missing in variable
    # 'ckd' below
    egfr_flag=patients.with_these_clinical_events(
        egfr_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.95,
        },
    ),
    egfr=patients.with_these_clinical_events(
        egfr_codes,  # imported from codelists.py
        returning="numeric_value",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM",
        return_expectations={
            "date": {"latest": "index_date"},
            "float": {"distribution": "normal", "mean": 45.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    # Fetch the comparator (<, >=, = etc) associated with a numeric value.
    # Where a lab result is returned as e.g. <9.5 the numeric_value component
    # will contain only the value 9.5 and you will need to use this function
    # to fetch the comparator into a separate column.
    # https://docs.opensafely.org/study-def-variables/#cohortextractor.patients.comparator_from
    egfr_comparator=patients.comparator_from(
        "egfr",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {  # ~, =, >= , > , < , <=
                    None: 0.10,
                    "~": 0.05,
                    "=": 0.65,
                    ">=": 0.05,
                    ">": 0.05,
                    "<": 0.05,
                    "<=": 0.05,
                }
            },
            "incidence": 0.80,
        },
    ),
    # Category 1 is of the form egfr>=a, if value is *a* but
    # the comparator is '<', '<=' or '~' --> exclude.
    # Category 5 is of the form egfr<b, if value is *b* but
    # the comparator is '>', '>=', '~' or '=' --> exclude.
    # Categories 2, 3, and 4 are of the form a <= egfr < b.
    # We have to exclude patients who's comparator is not '=':
    # Suppose for category 2, value is '>45' or '>=45', this value fullfils
    # egfr>=45 BUT since second rule is <60, we're not sure it actually is <60.
    # Restricting to those not '<', '<=' and '~' (like is done for category 1)
    # is therefore not enough, and we need to be stricter by limiting to '='.
    # In addition, suppose for category value is '<60' this value fullfils
    # egfr<60 BUT since first rule is >45, we're not sure it actually is >45.
    # Restricting to those not '>', '>=', '~' or '=' (like is done for category
    # 5) is therefore not enough, and we need to be stricter by limiting to
    # '='. The only comparator that can be used AND fullfils both rules,
    # is '='.
    egfr_category=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                egfr_flag AND
                    (egfr>=60 AND NOT
                        (egfr_comparator = '<' OR
                        egfr_comparator = '<=' OR
                        egfr_comparator = '~'))
            """,
            "2": """
                egfr_flag AND
                    (egfr>=45 AND
                    egfr<60 AND
                    egfr_comparator = '=')
            """,
            "3": """
                egfr_flag AND
                    (egfr>=30 AND
                    egfr<45 AND
                    egfr_comparator = '=')

            """,
            "4": """
                egfr_flag AND
                    (egfr>=15 AND
                    egfr<30 AND
                    egfr_comparator = '=')
            """,
            "5": """
                egfr_flag AND
                    (egfr<15 AND NOT
                        (egfr_comparator = '>' OR
                        egfr_comparator = '>=' OR
                        egfr_comparator = '~' OR
                        egfr_comparator = '='))

            """,
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.95,
                    "1": 0.01,
                    "2": 0.01,
                    "3": 0.01,
                    "4": 0.01,
                    "5": 0.01,
                }
            },
        },
    ),
    # CKD
    # Exclude patients on dialysis / with a kidney transplant
    # Based on eGFR, stage 0/ 3a/ 3b/ 4 or 5
    ckd=patients.categorised_as(
        {
            "No CKD": "DEFAULT",
            "0": """
                (NOT dialysis AND NOT kidney_transplant) AND
                egfr_category = 1
            """,
            "3a": """
                (NOT dialysis AND NOT kidney_transplant) AND
                egfr_category = 2
            """,
            "3b": """
                (NOT dialysis AND NOT kidney_transplant) AND
                egfr_category = 3
            """,
            "4": """
                (NOT dialysis AND NOT kidney_transplant) AND
                egfr_category = 4
            """,
            "5": """
                (NOT dialysis AND NOT kidney_transplant) AND
                egfr_category = 5
            """,
        },
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "No CKD": 0.8,
                                        "0": 0.1,
                                        "3a": 0.025,
                                        "3b": 0.025,
                                        "4": 0.025,
                                        "5": 0.025
                                        }
                                    },
                                },
    ),
    # Liver disease
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Stroke
    stroke=patients.with_these_clinical_events(
        stroke,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Dementia
    dementia=patients.with_these_clinical_events(
        dementia,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Other neurological disease
    other_neuro=patients.with_these_clinical_events(
        other_neuro,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Other organ transplant (excluding kidney transplants)
    other_organ_transplant=patients.with_these_clinical_events(
        other_organ_transplant_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Organ or kidney transplant
    organ_kidney_transplant=patients.categorised_as(
        {
            "No transplant": "DEFAULT",
            "Kidney": """
                kidney_transplant
            """,
            "Organ": """
                other_organ_transplant
            """,
        },
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "No transplant": 0.95,
                                        "Kidney": 0.025,
                                        "Organ": 0.025
                                        }
                                    },
                                },
    ),
    # Asplenia (splenectomy or a spleen dysfunction, including sickle cell
    # disease)
    asplenia=patients.with_these_clinical_events(
        combine_codelists(
            sickle_cell_codes,
            spleen_codes
         ),  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Rheumatoid/Lupus/Psoriasis
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Immunosuppressive condition
    immunosuppression=patients.with_these_clinical_events(
        combine_codelists(
            immunosuppression_medication_codes,
            immunosupression_diagnosis_codes
        ),  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Learning disabilities
    learning_disability=patients.with_these_clinical_events(
        learning_disability_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Severe mental illness
    sev_mental_ill=patients.with_these_clinical_events(
        sev_mental_ill_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # OUTCOMES
    # Patients with ONS-registered death
    died_ons_covid_any_date=patients.with_these_codes_on_death_certificate(
        covid_codelist,  # imported from codelists.py
        returning="date_of_death",
        between=["index_date", end_date],
        match_only_underlying_cause=False,  # boolean for indicating if filters
        # results to only specified cause of death
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.05,
        },
    ),
    # Death from any cause (to be used for censoring)
    died_any_date=patients.died_from_any_cause(
        between=["index_date", end_date],
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.01,
        },
    ),
)
