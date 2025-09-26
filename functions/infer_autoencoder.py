# infer_autoencoder.py
import numpy as np
import pandas as pd
import joblib
import os
from tensorflow import keras

MODEL_DIR = "model_artifacts"
FEATURES = [
    "solar_gen","solar_voltage","solar_current","consumption",
    "battery_voltage","battery_current","battery_temp","soc",
    "env_temp","env_humidity","relay_state"
]

# Load artifacts
scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
autoencoder = keras.models.load_model(os.path.join(MODEL_DIR, "autoencoder.keras"))

threshold = float(open(os.path.join(MODEL_DIR, "threshold.txt")).read().strip())

def infer_batch(X_raw):
    """
    X_raw: numpy array shape (n_samples, n_features) in original scale
    returns: list of dicts with mse and is_anomaly
    """
    X_scaled = scaler.transform(X_raw)
    X_pred = autoencoder.predict(X_scaled)
    mse = np.mean(np.square(X_scaled - X_pred), axis=1)
    results = []
    for m in mse:
        results.append({"mse": float(m), "is_anomaly": bool(m > threshold)})
    return results

if __name__ == "__main__":
    # Example: load a small CSV or single row
    df = pd.read_csv("solar_dataset_6788.csv", parse_dates=["timestamp"])
    # Take last 5 rows as sample
    sample = df[FEATURES].tail(5).values
    res = infer_batch(sample)
    for idx, r in enumerate(res):
        ts = df["timestamp"].iloc[-5 + idx]
        print(f"{ts}  MSE={r['mse']:.6f}  Anomaly={r['is_anomaly']}")
