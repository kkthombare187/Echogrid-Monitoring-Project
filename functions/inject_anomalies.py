# inject_anomalies.py
import pandas as pd
import numpy as np

RNG = np.random.default_rng(12345)  # deterministic for repeatability

df = pd.read_csv("solar_dataset_6788.csv", parse_dates=["timestamp"])

df_bad = df.copy()

# pick daytime rows (using solar_voltage > 15 as daytime proxy)
day_idx = df_bad.index[df_bad["solar_voltage"] > 15].tolist()

# 1) Inject 3 solar-failure anomalies: set V,I,gen = 0
solar_fail_idx = RNG.choice(day_idx, size=3, replace=False)
for i in solar_fail_idx:
    df_bad.loc[i, ["solar_voltage","solar_current","solar_gen"]] = [0.0, 0.0, 0.0]

# 2) Inject 3 battery overheating anomalies
batt_idx = RNG.choice(df_bad.index, size=3, replace=False)
for i in batt_idx:
    df_bad.loc[i, "battery_temp"] = 65.0

# 3) Inject 3 relay mismatch anomalies: relay_state=0 but high consumption
# prefer rows currently with relay_state==0; if not enough, pick random
relay_off_idx = df_bad.index[df_bad["relay_state"] == 0].tolist()
if len(relay_off_idx) < 3:
    relay_mismatch_idx = RNG.choice(df_bad.index, size=3, replace=False)
else:
    relay_mismatch_idx = RNG.choice(relay_off_idx, size=3, replace=False)

for i in relay_mismatch_idx:
    df_bad.loc[i, "relay_state"] = 0
    df_bad.loc[i, "consumption"] = max(df_bad.loc[i, "consumption"], 3.0)

# Print which timestamps were modified
print("Solar-failure injected at:")
print(df_bad.loc[solar_fail_idx, "timestamp"].to_list())
print("Battery-overheat injected at:")
print(df_bad.loc[batt_idx, "timestamp"].to_list())
print("Relay-mismatch injected at:")
print(df_bad.loc[relay_mismatch_idx, "timestamp"].to_list())

# Save new CSV
out = "solar_dataset_500_bad.csv"
df_bad.to_csv(out, index=False)
print(f"Saved bad dataset to {out}")
