# Define demographic variables needed accross waves

from cohortextractor import (
    patients,
    filter_codes_by_category,
)

import codelists

demographic_variables = dict(
    # follow up
    has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 3 months", "index_date"
    ),

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
            "incidence": 1.0,
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
            codelists.clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(codelists.clear_smoking_codes, include=["S", "E"]),
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
    # Rurality
    rural_urban=patients.address_as_of(
      "index_date",
      returning="rural_urban_classification",
      return_expectations={
        "rate": "universal",
        "category": {"ratios": {1: 0.125, 2: 0.125, 3: 0.125, 4: 0.125, 5: 0.125, 6: 0.125, 7: 0.125, 8: 0.125}},
        "incidence": 1,
        },
    ),
)
