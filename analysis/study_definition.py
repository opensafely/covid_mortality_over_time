######################################

# This script provides the formal specification of the study data that will
# be extracted from the OpenSAFELY database.

######################################

# IMPORT STATEMENTS ----
# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
    filter_codes_by_category,
    combine_codelists,
    Measure,
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
    creatinine_codes,
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

# Import config variables (dates, list of demographics and list of
# comorbidities)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

dates = config["dates"]
start_date = dates["start_date"]
end_date = dates["end_date"]
demographics_list = config["demographics"]
# demographics_list and comorbidities_list is used in the measures framework,
# the variable ckd_rrt is added to the data in an R script, and hence
# discarded here
comorbidities_list = config["comorbidities"]
comorbidities_list.remove("ckd_rrt")

# DEFINE STUDY POPULATION ----
# Define study population and variables
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.5,
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
        has_msoa
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
    has_msoa=patients.satisfying(
        "NOT (msoa = '')",
        msoa=patients.address_as_of(
         "index_date",
         returning="msoa",
        ),
        return_expectations={"incidence": 0.2}
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
                        "0": 0,
                        "1": 0.2,
                        "2": 0.2,
                        "3": 0.2,
                        "4": 0.2,
                        "5": 0.2,
                        }
                    },
                "incidence": 1.0
                },
    ),
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": "index_of_multiple_deprivation >= 0 AND index_of_multiple_deprivation < 32800*1/5",
            "2": "index_of_multiple_deprivation >= 32800*1/5 AND index_of_multiple_deprivation < 32800*2/5",
            "3": "index_of_multiple_deprivation >= 32800*2/5 AND index_of_multiple_deprivation < 32800*3/5",
            "4": "index_of_multiple_deprivation >= 32800*3/5 AND index_of_multiple_deprivation < 32800*4/5",
            "5": "index_of_multiple_deprivation >= 32800*4/5 AND index_of_multiple_deprivation <= 32800",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0,
                    "1": 0.2,
                    "2": 0.2,
                    "3": 0.2,
                    "4": 0.2,
                    "5": 0.2,
                }
            },
            "incidence": 1.0,
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
                            "incidence": 1.0,
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
    # blood pressure category (low, moderate/high)
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
                                "incidence": 1.0,
                            },
    ),
    # High blood pressure or hypertension
    bp_ht=patients.satisfying(
        "bp_sys >= 140 OR bp_dia >= 90 OR hypertension",
        return_expectations={
                                "incidence": 0.3,
                            },
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
                                "incidence": 1.0,
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
    # Categorise dialysis or kidney transplant
    # ref for logic:
    # https://docs.google.com/document/d/1hi_lMyuAa23u1xXLULLMdAiymiPopPZrAtQCDzYtjtE/edit
    # 0: no rrt
    # 1: rrt (dialysis)
    # 2: rrt (kidney transplant)
    rrt_cat=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (dialysis AND NOT kidney_transplant) OR
                ((dialysis AND kidney_transplant) AND
                dialysis_date > kidney_transplant_date)
            """,
            "2": """
                (kidney_transplant AND NOT dialysis) OR
                ((kidney_transplant AND dialysis) AND
                kidney_transplant_date >= dialysis_date)
            """,
        },
        return_expectations={
            "category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},
            "incidence": 1.0,
        },
    ),
    # CKD DEFINITIONS -
    # adapted from https://github.com/opensafely/risk-factors-research
    # Creatinine level for eGFR calculation
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["index_date - 2 years", "index_date - 1 day"],
        returning="numeric_value",
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "float": {"distribution": "normal", "mean": 90, "stddev": 30},
            "incidence": 0.95,
            },
    ),
    # Extract any operators associated with creatinine readings
    creatinine_operator=patients.comparator_from(
        "creatinine",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
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
    # Age at creatinine test
    creatinine_age=patients.age_as_of(
        "creatinine_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
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
                other_organ_transplant AND NOT kidney_transplant
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
                                "incidence": 1.0,
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
    # Date of first COVID vaccination - source nhs-covid-vaccination-coverage
    covid_vax_date_1=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["2020-12-01", "index_date"],  # any dose recorded after 01/12/2020
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.8,
        },
    ),
    # Date of second COVID vaccination - source nhs-covid-vaccination-coverage
    covid_vax_date_2=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_1 + 1 day", "index_date"],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.6,
        },
    ),
    # Date of third COVID vaccination (primary or booster) -
    # modified from nhs-covid-vaccination-coverage
    # 01 Sep 2021: 3rd dose (primary) at interval of >=8w recommended for
    # immunosuppressed
    # 14 Sep 2021: 3rd dose (booster) reommended for JCVI groups 1-9 at >=6m
    # 15 Nov 2021: 3rd dose (booster) recommended for 40–49y at >=6m
    # 29 Nov 2021: 3rd dose (booster) recommended for 18–39y at >=3m
    covid_vax_date_3=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_2 + 1 day", "index_date"],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.5,
        },
    ),
    # OUTCOMES
    # Patients with ONS-registered death
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,  # imported from codelists.py
        returning="binary_flag",
        between=["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause=False,  # boolean for indicating if filters
        # results to only specified cause of death
        return_expectations={
            "rate": "exponential_increase",
            "incidence": 0.05,
        },
    ),
)

measures = [
    # calculate crude mortality rate
    Measure(
        id="crude_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by="population",
    ),
    # calculate rates in age groups (for females and males seperately)
    Measure(
        id="age_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by=["sex", "agegroup"],
    ),
    # calculate rates in females/males
    Measure(
        id="sex_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by=["agegroup_std", "sex"],
    ),
]

for demographic in demographics_list:
    m = Measure(
        id=f"{demographic}_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by=["agegroup_std", "sex", f"{demographic}"],
    )
    measures.append(m),

for comorbidity in comorbidities_list:
    m = Measure(
        id=f"{comorbidity}_mortality_rate",
        numerator="died_ons_covid_flag_any",
        denominator="population",
        group_by=["agegroup_std", "sex", f"{comorbidity}"],
    )
    measures.append(m)
