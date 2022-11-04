# Define comorbidity variables needed accross waves

from cohortextractor import (
    patients,
    combine_codelists,
)

import codelists

comorbidity_variables = dict(
  
    # Diagnosed hypertension
    hypertension=patients.with_these_clinical_events(
        codelists.hypertension_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Respiratory disease ex asthma
    chronic_respiratory_disease=patients.with_these_clinical_events(
        codelists.chronic_respiratory_disease_codes,  # imported from codelists.py
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
            codelists.asthma_codes,  # imported from codelists.py
            between=["index_date - 3 years", "index_date"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(
            codelists.asthma_codes,  # imported from codelists.py
        ),
        copd_code_ever=patients.with_these_clinical_events(
            codelists.chronic_respiratory_disease_codes,  # imported from codelists.py
        ),
        prednisolone_last_year=patients.with_these_medications(
            codelists.pred_codes,  # imported from codelists.py
            between=["index_date - 1 year", "index_date"],
            returning="number_of_matches_in_period",
        ),
    ),
    # Blood pressure
    bp_sys=patients.mean_recorded_value(
        codelists.systolic_blood_pressure_codes,
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
        codelists.diastolic_blood_pressure_codes,
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
        codelists.chronic_cardiac_disease_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Diabetes
    diabetes=patients.with_these_clinical_events(
        codelists.diabetes_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # variable indicating whether patient has had a recent test yes/no
    hba1c_flag=patients.with_these_clinical_events(
        combine_codelists(
            codelists.hba1c_new_codes,
            codelists.hba1c_old_codes
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
        codelists.hba1c_new_codes,  # imported from codelists.py
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
        codelists.hba1c_old_codes,  # imported from codelists.py
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
            codelists.lung_cancer_codes,
            codelists.other_cancer_codes
        ),
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
    ),
    # Haematological malignancy
    haem_cancer=patients.with_these_clinical_events(
        codelists.haem_cancer_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,
        date_format="YYYY-MM-DD",
    ),
    # Dialysis
    dialysis=patients.with_these_clinical_events(
        codelists.dialysis_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True,  # generates dialysis_date
        date_format="YYYY-MM-DD",
    ),
    # Kidney transplant
    kidney_transplant=patients.with_these_clinical_events(
        codelists.kidney_transplant_codes,
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
        codelists.creatinine_codes,
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
        codelists.chronic_liver_disease_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Stroke
    stroke=patients.with_these_clinical_events(
        codelists.stroke,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Dementia
    dementia=patients.with_these_clinical_events(
        codelists.dementia,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Other neurological disease
    other_neuro=patients.with_these_clinical_events(
        codelists.other_neuro,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Other organ transplant (excluding kidney transplants)
    other_organ_transplant=patients.with_these_clinical_events(
        codelists.other_organ_transplant_codes,  # imported from codelists.py
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
            codelists.sickle_cell_codes,
            codelists.spleen_codes
         ),  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Rheumatoid/Lupus/Psoriasis
    ra_sle_psoriasis=patients.with_these_clinical_events(
        codelists.ra_sle_psoriasis_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Immunosuppressive condition
    immunosuppression=patients.with_these_clinical_events(
        combine_codelists(
            codelists.immunosuppression_medication_codes,
            codelists.immunosupression_diagnosis_codes
        ),  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Learning disabilities
    learning_disability=patients.with_these_clinical_events(
        codelists.learning_disability_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
    # Severe mental illness
    sev_mental_ill=patients.with_these_clinical_events(
        codelists.sev_mental_ill_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
    ),
)
