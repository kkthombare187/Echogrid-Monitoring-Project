import os
import pickle
import json
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, db
from datetime import datetime, date, timedelta
import sys

# Initialize Firebase app once
initialize_app()

# --- Global variables for lazy loading models ---
load_model = None
anomaly_model = None
anomaly_scaler = None
anomaly_threshold = None


# --- MODEL 1: LOAD FORECASTING (Unchanged) ---
@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"])
)
def predict_load(req: https_fn.Request) -> https_fn.Response:
    """Predicts load for the next 24 hours from JSON input."""
    import pandas as pd

    global load_model
    try:
        if load_model is None:
            model_path = os.path.join(os.path.dirname(__file__), "load_forecasting_model.pkl")
            with open(model_path, "rb") as f: load_model = pickle.load(f)
        
        data = req.get_json()['data']
        predictions = []
        for hour in range(24):
            current_input = { "hour": hour, "day_of_week": int(data.get("day_of_week", 0)), "day_of_month": int(data.get("day_of_month", 1)), "month": int(data.get("month", 1)), "quarter": int(data.get("quarter", 1)), "year": int(data.get("year", 2025)), "is_weekend": int(data.get("is_weekend", 0)) }
            input_df = pd.DataFrame([current_input])
            prediction = load_model.predict(input_df)
            predictions.append(round(float(prediction[0]), 2))
        return https_fn.Response(json.dumps({"predictions": predictions}), status=200, headers={"Content-Type": "application/json"})
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})


# --- NEW MODEL 2: TOTAL DAILY SOLAR FORECAST (Corrected) ---

def _fetch_historical_data():
    """Fetches the last 168 hours of generation data from Realtime Database."""
    import pandas as pd
    history_ref = db.reference('history/generation')
    snapshot = history_ref.order_by_key().limit_to_last(168).get()
    
    if not snapshot:
        # If there's no data at all, return an empty DataFrame.
        return pd.DataFrame({'timestamp': [], 'generation_kw': []})
    
    if isinstance(snapshot, dict):
        historical_data = list(snapshot.values())
    else:
        historical_data = list(snapshot)

    # Use a fixed interval from the current time to create timestamps
    end_time = datetime.now()
    timestamps = [end_time - timedelta(hours=i) for i in range(len(historical_data) - 1, -1, -1)]
    
    df = pd.DataFrame({
        'timestamp': pd.to_datetime(timestamps),
        # --- FIX #1: Handle potential null values from Firebase ---
        'generation_kw': [float(e or 0.0) for e in historical_data]
    })
    return df

def _fetch_weather_forecast():
    """Fetches tomorrow's weather forecast from Open-Meteo."""
    import pandas as pd
    import requests
    # Using Pune, India as the default location
    lat, lon = 18.5204, 73.8567
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&hourly=temperature_2m,direct_radiation&forecast_days=2"
    
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()['hourly']
    
    df = pd.DataFrame({
        'timestamp': pd.to_datetime(data['time']),
        'irradiance': [float(e or 0.0) for e in data['direct_radiation']],
        'temp': [float(e or 0.0) for e in data['temperature_2m']]
    })
    
    tomorrow = date.today() + timedelta(days=1)
    return df[df['timestamp'].dt.date == tomorrow].reset_index(drop=True)

def predict_full_day(historical_df, forecast_df, model_path="pv_forecast_model.pkl"):
    """Predicts solar generation for each hour in the forecast."""
    import pandas as pd
    import numpy as np

    # --- FIX #2: Pad historical data if it's less than the required 168 hours ---
    required_history = 168
    if len(historical_df) < required_history:
        padding_needed = required_history - len(historical_df)
        first_timestamp = historical_df['timestamp'].min() if not historical_df.empty else datetime.now()
        
        padding_timestamps = [first_timestamp - timedelta(hours=i) for i in range(padding_needed, 0, -1)]
        padding_df = pd.DataFrame({
            'timestamp': pd.to_datetime(padding_timestamps),
            'generation_kw': [0.0] * padding_needed
        })
        historical_df = pd.concat([padding_df, historical_df], ignore_index=True)

    with open(model_path, "rb") as f:
        model_dict = pickle.load(f)
    model = model_dict["model"]
    features = model_dict["features"]

    forecast_df['generation_kw'] = np.nan
    # Use forecast 'temp' column, but historical 'temperature' column may not exist.
    # Rename historical column if needed, but safer to handle concat carefully.
    if 'temperature' in historical_df.columns:
        historical_df = historical_df.rename(columns={'temperature': 'temp'})

    combined_df = pd.concat([historical_df, forecast_df], ignore_index=True)
    combined_df = combined_df.sort_values(by='timestamp').reset_index(drop=True)

    predictions = []
    for index, row in forecast_df.iterrows():
        target_time = row['timestamp']
        target_idx_query = combined_df[combined_df['timestamp'] == target_time]
        if target_idx_query.empty: continue
        target_idx = target_idx_query.index[0]

        hour_sin = np.sin(2 * np.pi * target_time.hour / 24)
        hour_cos = np.cos(2 * np.pi * target_time.hour / 24)
        dow_sin = np.sin(2 * np.pi * target_time.weekday() / 7)
        dow_cos = np.cos(2 * np.pi * target_time.weekday() / 7)

        lag_1 = combined_df.loc[target_idx - 1, 'generation_kw']
        lag_24 = combined_df.loc[target_idx - 24, 'generation_kw']
        lag_168 = combined_df.loc[target_idx - 168, 'generation_kw']

        rolling_window = combined_df.loc[target_idx - 24:target_idx - 1, 'generation_kw']
        roll24_mean = rolling_window.mean()
        roll24_std = rolling_window.std()
        roll24_std = 0 if pd.isna(roll24_std) else roll24_std

        input_data = {
            "irradiance": row['irradiance'], "temp": row['temp'],
            "lag_1": lag_1, "lag_24": lag_24, "lag_168": lag_168,
            "roll24_mean": roll24_mean, "roll24_std": roll24_std,
            "hour_sin": hour_sin, "hour_cos": hour_cos,
            "dow_sin": dow_sin, "dow_cos": dow_cos
        }

        input_df = pd.DataFrame([input_data], columns=features)
        prediction = model.predict(input_df)[0]
        prediction = max(0, prediction)

        predictions.append({'timestamp': target_time, 'predicted_kw': prediction})
        combined_df.loc[target_idx, 'generation_kw'] = prediction

    return pd.DataFrame(predictions)

@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["get"])
)
def predict_total_solar_generation(req: https_fn.Request) -> https_fn.Response:
    """
    HTTP endpoint that fetches data, runs a full-day forecast,
    and returns the total predicted generation for tomorrow.
    """
    try:
        history_df = _fetch_historical_data()
        forecast_df = _fetch_weather_forecast()
        
        # Check if weather forecast is empty (e.g., API issue)
        if forecast_df.empty:
            raise Exception("Failed to get weather forecast for tomorrow.")

        daily_predictions_df = predict_full_day(history_df, forecast_df)
        
        total_generation = daily_predictions_df['predicted_kw'].sum()
        
        return https_fn.Response(json.dumps({"total_generation_kwh": total_generation}),
                                  headers={"Content-Type": "application/json"})

    except Exception as e:
        print(f"Error in predict_total_solar_generation: {e}", file=sys.stderr)
        return https_fn.Response(json.dumps({"error": str(e)}), status=500,
                                  headers={"Content-Type": "application/json"})


# --- MODEL 3: ANOMALY DETECTION (Unchanged) ---
def classify_failure(row):
    failures = []
    if row.get("solar_gen", 0) < 1 and row.get("solar_voltage", 0) > 15: failures.append("Solar (disconnected/shaded)")
    if row.get("battery_temp", 0) > 60: failures.append("Battery (overheating)")
    if row.get("relay_state", 0) == 0 and row.get("consumption", 0) > 2: failures.append("Relay/Load (mismatch)")
    if not failures: failures.append("Unknown anomaly")
    return failures
def classify_severity(error, threshold):
    if error < threshold * 2: return "Low"
    elif error < threshold * 5: return "Medium"
    else: return "High"

@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    timeout_sec=300,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"])
)
def predict_anomalies(req: https_fn.Request) -> https_fn.Response:
    """Receives a JSON array of sensor records and returns anomaly predictions."""
    import pandas as pd
    import numpy as np
    import joblib
    import tensorflow as tf
    from tensorflow import keras
    
    global anomaly_model, anomaly_scaler, anomaly_threshold
    try:
        if anomaly_model is None:
            model_dir = os.path.join(os.path.dirname(__file__), "model_artifacts")
            anomaly_model = keras.models.load_model(os.path.join(model_dir, "autoencoder.keras"))
            anomaly_scaler = joblib.load(os.path.join(model_dir, "scaler.pkl"))
            with open(os.path.join(model_dir, "threshold.txt"), "r") as f: anomaly_threshold = float(f.read().strip())
        
        request_data = req.get_json()
        if not request_data or 'records' not in request_data:
            return https_fn.Response(json.dumps({"error": "Missing 'records' field in JSON body."}), status=400, headers={"Content-Type": "application/json"})
        df = pd.DataFrame.from_records(request_data['records'])
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        features = ["solar_gen", "solar_voltage", "solar_current", "consumption", "battery_voltage", "battery_current", "battery_temp", "soc", "env_temp", "env_humidity", "relay_state"]
        for col in features:
            if col not in df.columns: df[col] = 0
        X = df[features].astype(float).values
        X_scaled = anomaly_scaler.transform(X)
        X_pred = anomaly_model.predict(X_scaled, verbose=0)
        mse = np.mean(np.square(X_scaled - X_pred), axis=1)
        results = []
        for i, row in df.iterrows():
            error = mse[i]
            if error > anomaly_threshold:
                results.append({"timestamp": str(row["timestamp"]), "Anomaly": True, "Severity": classify_severity(error, anomaly_threshold), "Devices": classify_failure(row)})
            else:
                results.append({"timestamp": str(row["timestamp"]), "Anomaly": False, "Severity": None, "Devices": ["System Normal"]})
        return https_fn.Response(json.dumps({"results": results}), status=200, headers={"Content-Type": "application/json"})
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, headers={"Content-Type": "application/json"})

# --- SCHEDULED LOGGER FUNCTION (Unchanged) ---
@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["get"])
)
def log_hourly_data(req: https_fn.Request) -> https_fn.Response:
    print("Executing hourly data log...")
    sensor_paths = { "solar_generation": "/solar_generation", "solar_voltage": "/sensors/solar_voltage", "solar_current": "/sensors/solar_current", "battery_voltage": "/sensors/battery_voltage", "battery_current": "/sensors/battery_current", "ds18b20_temp": "/sensors/ds18b20_temp", "soc": "/sensors/soc", "dht_temp": "/sensors/dht_temp", "dht_humidity": "/sensors/dht_humidity", }
    control_paths = { "energy_consumption": "/energy_consumption", "Load": "/controls/Load", }
    sensor_readings = {}
    control_readings = {}
    try:
        for key, path in sensor_paths.items(): sensor_readings[key] = db.reference(path).get()
        for key, path in control_paths.items(): control_readings[key] = db.reference(path).get()
        record = { "timestamp": datetime.now().isoformat(), "sensors": sensor_readings, "controls": control_readings, }
        db.reference("/sensor_history").push(record)
        message = "Successfully logged data snapshot to /sensor_history."
        print(message)
        return https_fn.Response(message, status=200)
    except Exception as e:
        error_message = f"An error occurred: {e}"
        print(error_message, file=sys.stderr)
        return https_fn.Response(error_message, status=500)

