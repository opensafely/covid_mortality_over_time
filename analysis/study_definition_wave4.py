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
)

from dict_demographic_vars import demographic_variables

from dict_comorbidity_vars import comorbidity_variables

import codelists

# Import config variables (start_date and end_date of wave1)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

wave = config["wave4"]
start_date = wave["start_date"]
end_date = wave["end_date"]

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
        NOT died AND
        (age >=18 AND age <= 110) AND
        (sex = "M" OR sex = "F") AND
        NOT stp = "" AND
        index_of_multiple_deprivation != -1
        """,
        died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.01},
        ),
    ),
    # DEMOGRAPHICS
    **demographic_variables,

    # COMORBIDITIES
    **comorbidity_variables,

    # OUTCOMES (not in dict because end_date is used)
    # Patients with ONS-registered death
    died_ons_covid_any_date=patients.with_these_codes_on_death_certificate(
        codelists.covid_codelist,  # imported from codelists.py
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
    # Is there an associated positive test in the 8 weeks before
    # covid associated death?
    covid_test_positive_date=patients.with_test_result_in_sgss(
        between=["died_ons_covid_any_date - 57 days", "died_ons_covid_any_date + 2 days"],
        pathogen="SARS-CoV-2",
        test_result="positive",
        find_first_match_in_period=False,
        restrict_to_earliest_specimen_date=False,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.01
        },
    ),
    # Date of first COVID vaccination - source nhs-covid-vaccination-coverage
    covid_vax_date_1=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["2020-12-01", end_date],  # any dose recorded after 01/12/2020
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
        between=["covid_vax_date_1 + 1 day", end_date],  # from day after previous dose
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
        between=["covid_vax_date_2 + 1 day", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.5,
        },
    ),
    # Date of fourth COVID vaccination (primary or booster) -
    covid_vax_date_4=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_3 + 1 day", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.5,
        },
    ),
    # Date of fifth COVID vaccination (primary or booster) -
    covid_vax_date_5=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_4 + 1 day", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.5,
        },
    ),
    # Date of sixth COVID vaccination (primary or booster) -
    covid_vax_date_6=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_5 + 1 day", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": "index_date"},
            "incidence": 0.5,
        },
    ),
)
