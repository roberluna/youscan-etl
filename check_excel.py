import pandas as pd

df = pd.read_excel("data/data_youscan.xlsx")
print("OK, shape:", df.shape)
print("Columns (primeras 15):", list(df.columns)[:15])
