# train_autoencoder.py
import numpy as np
import pandas as pd
import os
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow import keras
import joblib

# ---- CONFIG ----
CSV_FILE = "solar_dataset_7000_normal.csv"
MODEL_DIR = "model_artifacts"
os.makedirs(MODEL_DIR, exist_ok=True)

FEATURES = [
    "solar_gen","solar_voltage","solar_current","consumption",
    "battery_voltage","battery_current","battery_temp","soc",
    "env_temp","env_humidity","relay_state"
]

TEST_SIZE = 0.2
RANDOM_STATE = 42
BATCH_SIZE = 32
EPOCHS = 80   # start here; reduce/increase based on loss behavior
LATENT_DIM = 6  # bottleneck size (tune)
VALIDATION_SPLIT = 0.1

# ---- 1. Load data ----
df = pd.read_csv(CSV_FILE, parse_dates=["timestamp"])
df = df.sort_values("timestamp").reset_index(drop=True)
X = df[FEATURES].astype(float).values

# ---- 2. Preprocess: scale features ----
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# ---- 3. Train/val/test split ----
# For generative anomaly detection it's best to train on "normal" data.
# If you only have mostly normal synthetic data, split normally:
X_train, X_test = train_test_split(X_scaled, test_size=TEST_SIZE, random_state=RANDOM_STATE)
# Further split train -> train/val for early stopping
X_train, X_val = train_test_split(X_train, test_size=VALIDATION_SPLIT, random_state=RANDOM_STATE)

print("Shapes:", X_train.shape, X_val.shape, X_test.shape)

# ---- 4. Build Autoencoder (simple dense) ----
input_dim = X_train.shape[1]
input_layer = keras.Input(shape=(input_dim,))

# Encoder
x = keras.layers.Dense(64, activation="relu")(input_layer)
x = keras.layers.Dense(32, activation="relu")(x)
latent = keras.layers.Dense(LATENT_DIM, activation="relu")(x)

# Decoder
x = keras.layers.Dense(32, activation="relu")(latent)
x = keras.layers.Dense(64, activation="relu")(x)
output_layer = keras.layers.Dense(input_dim, activation="linear")(x)

autoencoder = keras.Model(inputs=input_layer, outputs=output_layer)
autoencoder.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-3), loss="mse")

autoencoder.summary()

# ---- 5. Train with early stopping ----
es = keras.callbacks.EarlyStopping(monitor="val_loss", patience=8, restore_best_weights=True)
history = autoencoder.fit(
    X_train, X_train,
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    validation_data=(X_val, X_val),
    callbacks=[es],
    verbose=2
)

# ---- 6. Determine reconstruction error threshold ----
# Compute reconstruction MSE on validation set
X_val_pred = autoencoder.predict(X_val)
mse_val = np.mean(np.square(X_val - X_val_pred), axis=1)

# Choose threshold: e.g., 95th percentile of val reconstruction error
threshold = np.percentile(mse_val, 99.5)
print(f"Validation MSE statistics: mean={mse_val.mean():.6f}, std={mse_val.std():.6f}, 95pct={threshold:.6f}")

# ---- 7. Save artifacts: model, scaler, threshold ----
model_path = os.path.join(MODEL_DIR, "autoencoder.keras")
autoencoder.save(model_path)

joblib.dump(scaler, os.path.join(MODEL_DIR, "scaler.pkl"))
# Save threshold
with open(os.path.join(MODEL_DIR, "threshold.txt"), "w") as f:
    f.write(str(threshold))

print("Saved model to:", model_path)
print("Saved scaler and threshold to:", MODEL_DIR)

# ---- 8. Quick evaluation on test set (print summary) ----
X_test_pred = autoencoder.predict(X_test)
mse_test = np.mean(np.square(X_test - X_test_pred), axis=1)
print(f"Test MSE mean: {mse_test.mean():.6f}, anomalies (mse>{threshold}): {(mse_test>threshold).sum()} / {len(mse_test)}")

# Save MSEs alongside timestamps for inspection
result_df = df.iloc[X.shape[0]-len(X_test):].copy() if False else pd.DataFrame()  # skip timestamp alignment here
pd.DataFrame({
    "mse_test": mse_test
}).to_csv(os.path.join(MODEL_DIR, "test_mse.csv"), index=False)

print("Training complete.")
