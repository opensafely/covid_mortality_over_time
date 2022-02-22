from cohortextractor import (
    StudyDefinition, 
    patients,
)

# import codes from analysis/codelists.py
from codelists import (
    ethnicity_codes,
    clear_smoking_codes,
    hypertension_codes,
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
    dialysis_codes,
    chronic_liver_disease_codes
    stroke,
    dementia,
    other_neuro,
    organ_transplant_codes,
    spleen_codes,
    sickle_cell_codes,
    ra_sle_psoriasis_codes,
    aplastic_anaemia,
    permanent_immune_codes,
    temp_immune_codes,
    hiv_codes,
)

# define study
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
    ## self-reported ethnicity
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes, # imported from codelists.py
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ), 
    ## bmi
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
    ## smoking status https://github.com/ebmdatalab/tpp-sql-notebook/issues/6
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
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes, # imported from codelists.py
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="index_date",
        ),
    ),
    ## imd (index of multiple deprivation) quintile
    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),   
    ## stp https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
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
    ## region (one of NHS England 9 regions)
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
    ## Diagnosed hypertension
    hypertension=patients.with_these_clinical_events(
        hypertension_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Respiratory disease ex asthma
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Asthma https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
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
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code=patients.with_these_clinical_events(
            asthma_codes, # imported from codelists.py
            between=["2017-02-01", "2020-02-01"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(
            asthma_codes, # imported from codelists.py
        ),
        copd_code_ever=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes # imported from codelists.py
        ),
        prednisolone_last_year=patients.with_these_medications(
            pred_codes, # imported from codelists.py
            between=["2019-02-01", "2020-02-01"],
            returning="number_of_matches_in_period",
        ),
    ),
    ## Chronic heart disease
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Diabetes
    diabetes=patients.with_these_clinical_events(
        diabetes_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "index_date"}},
    ),
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes, # imported from codelists.py
        find_last_match_in_period=True,
        on_or_before="2020-02-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-02-29"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes, # imported from codelists.py
        find_last_match_in_period=True,
        on_or_before="2020-02-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-02-29"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    ## Lung cancer
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Other cancer
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Haematological malignancy
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ## Reduced kidney function
    creatinine=patients.with_these_clinical_events(
        creatinine_codes, # imported from codelists.py
        find_last_match_in_period=True,
        on_or_before="2020-02-01",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "date": {"earliest": "2019-02-28", "latest": "2020-02-29"},
            "incidence": 0.95,
        },
    ),
    ## Kidney dialysis
    dialysis=patients.with_these_clinical_events(
        dialysis_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Liver disease
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes, # imported from codelists.py
        on_or_before="index_date",
        return_first_date_in_period=True,
        include_month=True,
    ),
    ## Stroke
    stroke=patients.with_these_clinical_events(
        stroke, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Dementia
    dementia=patients.with_these_clinical_events(
        dementia, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Other neurological disease
    other_neuro=patients.with_these_clinical_events(
        other_neuro, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Organ transplant
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Asplenia (splenectomy or a spleen dysfunction, including sickle cell disease)
    dysplenia=patients.with_these_clinical_events(
        spleen_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    sickle_cell=patients.with_these_clinical_events(
        sickle_cell_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Rheumatoid/Lupus/Psoriasis
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    ## Other immunosuppressive condition (permanent immunodeficiency ever diagnosed, or aplastic anaemia or temporary immunodeficiency recorded within the last year)
    aplastic_anaemia=patients.with_these_clinical_events(
        aplastic_codes, # imported from codelists.py
        return_last_date_in_period=True, 
        include_month=True,
    ),  
    permanent_immunodeficiency=patients.with_these_clinical_events(
        permanent_immune_codes, # imported from codelists.py
        return_first_date_in_period=True, 
        include_month=True,
    ),
    temporary_immunodeficiency=patients.with_these_clinical_events(
        temp_immune_codes, # imported from codelists.py
        return_last_date_in_period=True, 
        include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        hiv_codes, # imported from codelists.py
        returning="category", 
        find_first_match_in_period=True, 
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "category": {"ratios": {"43C3.": 0.8, "XaFuL": 0.2}},
            },
    ), 
    # OUTCOMES
    died_date_cpns=patients.with_death_recorded_in_cpns(
        returning="date_of_death",
        include_month=True,
        include_day=True,
    ),
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist, # imported from codelists.py
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_ons_covid_flag_underlying=patients.with_these_codes_on_death_certificate(
        covid_codelist, # imported from codelists.py
        match_only_underlying_cause=True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_ons_covidconf_flag_underlying=patients.with_these_codes_on_death_certificate(
        covidconf_codelist, # imported from codelists.py
        match_only_underlying_cause=True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_date_ons=patients.died_from_any_cause(
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_cause_ons=patients.died_from_any_cause(
        returning="underlying_cause_of_death",
        return_expectations={"category": {"ratios": {"U071":0.2, "I21":0.2, "C34":0.15, "C83":0.05 , "J09":0.05 , "J45":0.1 ,"G30":0.2, "A01":0.05}},},
    ),
    died_date_1ocare=patients.with_death_recorded_in_primary_care(
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-02-02"}},
    ),
)
