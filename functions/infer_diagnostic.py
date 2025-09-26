# infer_diagnostic.py
import numpy as np
import pandas as pd
import sys
import os
import joblib
import tensorflow as tf
from tensorflow import keras

# ---- CONFIG ----
MODEL_DIR = "model_artifacts"
FEATURES = [
    "solar_gen","solar_voltage","solar_current","consumption",
    "battery_voltage","battery_current","battery_temp","soc",
    "env_temp","env_humidity","relay_state"
]

# ---- 1. Load model, scaler, threshold ----
model = keras.models.load_model(os.path.join(MODEL_DIR, "autoencoder.keras"))
scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
with open(os.path.join(MODEL_DIR, "threshold.txt"), "r") as f:
    THRESHOLD = float(f.read().strip())

# ---- 2. Helper functions ----
def classify_failure(row):
    """Rule-based failure classification from raw features"""
    failures = []
    if row["solar_gen"] < 1 and row["solar_voltage"] > 15:
        failures.append("Solar (disconnected/shaded)")
    if row["battery_temp"] > 60:
        failures.append("Battery (overheating)")
    if row["relay_state"] == 0 and row["consumption"] > 2:
        failures.append("Relay/Load (mismatch)")
    if not failures:
        failures.append("Unknown anomaly")
    return failures

def classify_severity(error, threshold):
    """Classify anomaly severity"""
    if error < threshold * 2:
        return "Low"
    elif error < threshold * 5:
        return "Medium"
    else:
        return "High"

# ---- 3. Load dataset ----
if len(sys.argv) < 2:
    print("Usage: python infer_diagnostic.py <dataset.csv>")
    sys.exit(1)

csv_file = sys.argv[1]
df = pd.read_csv(csv_file, parse_dates=["timestamp"])
X = df[FEATURES].astype(float).values
X_scaled = scaler.transform(X)

# ---- 4. Run inference ----
X_pred = model.predict(X_scaled, verbose=0)
mse = np.mean(np.square(X_scaled - X_pred), axis=1)

# # ---- 5. Evaluate row by row ----
# for i, row in df.iterrows():
#     ts = row["timestamp"]
#     error = mse[i]

#     if error > THRESHOLD:
#         severity = classify_severity(error, THRESHOLD)
#         failures = classify_failure(row)
#         print(f"{ts}\nAnomaly = True\nSeverity = {severity}\nDevices = {', '.join(failures)}\n")
#     else:
#         print(f"{ts}\nAnomaly = False\nSystem Normal\n")
# ---- 5. Evaluate row by row ----
results = []

for i, row in df.iterrows():
    ts = row["timestamp"]
    error = mse[i]

    if error > THRESHOLD:
        severity = classify_severity(error, THRESHOLD)
        failures = classify_failure(row)
        results.append([ts, True, severity, ", ".join(failures)])
    else:
        results.append([ts, False, "None", "System Normal"])

# Convert results to DataFrame
results_df = pd.DataFrame(results, columns=["timestamp", "Anomaly", "Severity", "Devices"])

# Save all results to CSV
out_file = "diagnostic_results.csv"
results_df.to_csv(out_file, index=False)
print(f"✅ Results saved to {out_file}")

# Print a preview in terminal (first 50 rows)
print("\n🔎 Preview (first 50 rows):\n")
print(results_df.head(50).to_string(index=False))
