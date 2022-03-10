import os

import pandas as pd

ethnicity_df = pd.read_csv("output/input_ethnicity.csv.gz")

for file in os.listdir("output"):
    if file.startswith("input"):
        # exclude ethnicity
        if file.split("_")[1] not in ["ethnicity.csv.gz", "practice"]:
            file_path = os.path.join("output", file)
            df = pd.read_csv(file_path)
            merged_df = df.merge(ethnicity_df, how = "left", on = "patient_id")

            merged_df.to_csv(file_path, index=False)