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

import codelists

# Import config variables (start_date and end_date of wave1)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

period = config["thisyear"]
start_date = period["start_date"]
end_date = period["end_date"]

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

    population=patients.registered_as_of("index_date"),

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
