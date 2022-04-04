######################################

# This script provides the formal specification of ethnicity that will be
# extracted from the OpenSAFELY database.

######################################

# IMPORT STATEMENTS ----
# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
)

# Import codelists from codelist.py (which pulls them from the codelist folder)
from codelists import ethnicity_codes

# Import config variables (dates)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

dates = config["dates"]
start_date = dates["start_date"]
end_date = dates["end_date"]

# DEFINE STUDY POPULATION ----
# Define study population and variables
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.5,
    },
    # Set index date to end date
    index_date=end_date,
    # Define the study population (= all patients in this case)
    # IN AND EXCLUSION CRITERIA
    population=patients.all(),

    # ETHNICITY IN 6 CATEGORIES
    eth=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=False,
        return_expectations={
                                "category": {
                                    "ratios": {
                                        "1": 0.2,
                                        "2": 0.2,
                                        "3": 0.2,
                                        "4": 0.2,
                                        "5": 0.2
                                        }
                                    },
                                "incidence": 0.75,
                                },
    ),

    # fill missing ethnicity from SUS
    ethnicity_sus=patients.with_ethnicity_from_sus(
        returning="group_6",
        use_most_frequent_code=True,
        return_expectations={
            "category": {
                            "ratios": {
                                "1": 0.2,
                                "2": 0.2,
                                "3": 0.2,
                                "4": 0.2,
                                "5": 0.2
                                }
                            },
            "incidence": 0.4,
            },
    ),

    ethnicity=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": "eth='1' OR (NOT eth AND ethnicity_sus='1')",
                "2": "eth='2' OR (NOT eth AND ethnicity_sus='2')",
                "3": "eth='3' OR (NOT eth AND ethnicity_sus='3')",
                "4": "eth='4' OR (NOT eth AND ethnicity_sus='4')",
                "5": "eth='5' OR (NOT eth AND ethnicity_sus='5')",
            },
            return_expectations={
                "category": {
                                "ratios": {
                                    "0": 0.5,  # missing in 50%
                                    "1": 0.1,
                                    "2": 0.1,
                                    "3": 0.1,
                                    "4": 0.1,
                                    "5": 0.1
                                    }
                                },
                "rate": "universal",
            },
    ),
)
