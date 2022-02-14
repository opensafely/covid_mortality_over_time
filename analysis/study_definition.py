from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
)

study = StudyDefinition(
    # STUDY POPULATION (INCLUSION/EXCLUSION CRITERIA)
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    index_date="2020-02-01",
    population=patients.satisfying(
        """
        (age >= 18) AND 
        has_follow_up
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-02-01", "2020-02-01"
        ),
    ),
    # DEMOGRAPHICS
    ## age 
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    ## sex 
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "date": {},
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),  
    ## self-reported ethnicity 
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ), 
    ## IMD (index of multiple deprivation) quintile
    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ), 
    # COMORBIDITIES
    ## High blood pressure or diagnosed hypertension
    ## Respiratory disease ex asthma
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Asthma
    ## Chronic heart disease
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Diabetes
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ## Cancer (non haematological)
    ## Haematological malignancy
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ## Reduced kidney function
    ## Kidney dialysis
    ## Liver disease
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Stroke/dementia
    ## Other neurological disease
    ## Organ transplant
    ## Asplenia
    ## Rheumatoid/Lupus/Psoriasis
    ## Other immunosuppressive condition
)
