# Define vaccination variables needed accross waves

from cohortextractor import patients

vaccination_variables = dict(
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
)
