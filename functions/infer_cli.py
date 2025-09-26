# infer_cli.py
import sys, joblib, os
import pandas as pd
import numpy as np
from tensorflow import keras

MODEL_DIR = "model_artifacts"
FEATURES = [
    "solar_gen","solar_voltage","solar_current","consumption",
    "battery_voltage","battery_current","battery_temp","soc",
    "env_temp","env_humidity","relay_state"
]

if len(sys.argv) < 2:
    print("Usage: python infer_cli.py <csv_file>")
    sys.exit(1)

csv_file = sys.argv[1]
df = pd.read_csv(csv_file, parse_dates=["timestamp"])

scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
autoencoder = keras.models.load_model(os.path.join(MODEL_DIR, "autoencoder.keras"))
threshold = float(open(os.path.join(MODEL_DIR, "threshold.txt")).read().strip())

X = df[FEATURES].values.astype(float)
X_scaled = scaler.transform(X)
X_pred = autoencoder.predict(X_scaled)
mse = np.mean((X_scaled - X_pred)**2, axis=1)

# print anomalies only
print("timestamp, mse, anomaly")
for ts, m in zip(df["timestamp"], mse):
    if m > threshold:
        print(f"{ts}  {m:.6f}  Anomaly=True")
