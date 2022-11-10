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

from dict_vax_vars import vaccination_variables

import codelists

# Import config variables (start_date and end_date of wave1)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

wave = config["wave1"]
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
        has_follow_up AND
        NOT died AND
        (age >=18 AND age <= 110) AND
        (sex = "M" OR sex = "F") AND
        NOT stp = "" AND
        index_of_multiple_deprivation != -1
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
    **demographic_variables,

    # COMORBIDITIES
    **comorbidity_variables,

    # VACCINATION
    **vaccination_variables,

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
)
