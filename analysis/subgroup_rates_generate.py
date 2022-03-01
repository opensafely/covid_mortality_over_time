from cohortextractor import Measure

measures = [
   
    Measure(
        id = "age_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup"],
    ),

    Measure(
        id = "sex_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex"],
    ),

    Measure(
        id = "bmi_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "bmi"],
    ),

    Measure(
        id = "ethnicity_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "ethnicity"],
    ),

    Measure(
        id = "imd_mortality_rate",
        numerator = "died_ons_covid_flag_any",
        denominator = "population",
        group_by = ["agegroup_std", "sex", "imd"],
    ),
]