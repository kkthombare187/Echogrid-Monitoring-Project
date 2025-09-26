# forecast_pipeline_final_v3.py

import pandas as pd
import lightgbm as lgb
import joblib

# FIX FOR THE TKINTER ERROR
import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt


def prepare_data(file_path):
    """Loads data, handles the specific date format, and creates features."""
    print(f"Loading data from {file_path}...")
    df = pd.read_csv(file_path)
    df['timestamp'] = pd.to_datetime(df['timestamp'], format='%d-%m-%Y %H:%M')
    df = df.sort_values('timestamp').reset_index(drop=True)

    # Feature Engineering
    df['hour'] = df['timestamp'].dt.hour
    df['day_of_week'] = df['timestamp'].dt.dayofweek
    df['day_name'] = df['timestamp'].dt.day_name()
    df['day_of_month'] = df['timestamp'].dt.day
    df['month'] = df['timestamp'].dt.month
    df['quarter'] = df['timestamp'].dt.quarter
    df['year'] = df['timestamp'].dt.year
    df['is_weekend'] = (df['day_of_week'] >= 5).astype(int)

    print("Data preparation complete.")
    return df


def plot_historical_data(df, image_path='load_demand_plot.png'):
    """Creates and saves a plot of the historical time-series load data."""
    print(f"\n--- Generating Historical Plot ---")
    plt.figure(figsize=(15, 7))
    plt.plot(df['timestamp'], df['load_demand_mw'], label='Load Demand (MW)', color='blue')
    plt.title('Historical Load Demand Over Time')
    plt.xlabel('Timestamp')
    plt.ylabel('Load Demand (MW)')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(image_path)
    print(f"Historical plot saved as '{image_path}'")


def plot_forecast_for_tomorrow(forecast_df, image_path='tomorrow_forecast_plot.png'):
    """Creates and saves a plot of the forecasted load for the next day."""
    print(f"\n--- Generating Forecast Plot ---")
    plt.figure(figsize=(15, 7))
    plt.plot(forecast_df['timestamp'], forecast_df['predicted_load_mw'], label='Predicted Load (MW)', color='red',
             marker='o', linestyle='--')
    plt.title("Tomorrow's Load Forecast (30-minute intervals)")
    plt.xlabel('Timestamp')
    plt.ylabel('Predicted Load (MW)')
    plt.legend()
    plt.grid(True)
    plt.gca().xaxis.set_major_formatter(plt.matplotlib.dates.DateFormatter('%H:%M'))
    plt.tight_layout()
    plt.savefig(image_path)
    print(f"Forecast plot saved as '{image_path}'")


def train_and_save_model(df, model_path='load_forecasting_model.pkl'):
    """Trains and saves the LightGBM model."""
    print("\n--- Model Training ---")
    features = ['hour', 'day_of_week', 'day_of_month', 'month', 'quarter', 'year', 'is_weekend']
    target = 'load_demand_mw'
    X = df[features]
    y = df[target]

    model = lgb.LGBMRegressor(objective='regression_l1', n_estimators=1000, learning_rate=0.05, num_leaves=31)
    model.fit(X, y)
    joblib.dump(model, model_path)
    print(f"Model training complete. Model saved to {model_path}")
    return model_path


def predict_for_tomorrow(model_path, last_timestamp):
    """Loads the model and predicts the load for the next 24 hours at 30-minute intervals."""
    print("\n--- Generating Forecast for Tomorrow ---")
    model = joblib.load(model_path)

    future_dates = pd.date_range(start=last_timestamp, periods=49, freq='30min')[1:]
    future_df = pd.DataFrame({'timestamp': future_dates})

    future_df['hour'] = future_df['timestamp'].dt.hour
    future_df['day_of_week'] = future_df['timestamp'].dt.dayofweek
    future_df['day_name'] = future_df['timestamp'].dt.day_name()
    future_df['day_of_month'] = future_df['timestamp'].dt.day
    future_df['month'] = future_df['timestamp'].dt.month
    future_df['quarter'] = future_df['timestamp'].dt.quarter
    future_df['year'] = future_df['timestamp'].dt.year
    future_df['is_weekend'] = (future_df['day_of_week'] >= 5).astype(int)

    features = ['hour', 'day_of_week', 'day_of_month', 'month', 'quarter', 'year', 'is_weekend']
    future_features = future_df[features]
    future_df['predicted_load_mw'] = model.predict(future_features)

    # --- UPDATED LOGIC TO PRINT A TIME RANGE ---
    # Find the single highest and lowest load points
    highest_load_row = future_df.loc[future_df['predicted_load_mw'].idxmax()]
    lowest_load_row = future_df.loc[future_df['predicted_load_mw'].idxmin()]

    # Define the time range (e.g., a 1-hour window starting from the identified slot)
    peak_start_time = highest_load_row['timestamp']
    peak_end_time = peak_start_time + pd.Timedelta(hours=1)
    peak_value = highest_load_row['predicted_load_mw']
    day_name = highest_load_row['day_name']

    trough_start_time = lowest_load_row['timestamp']
    trough_end_time = trough_start_time + pd.Timedelta(hours=1)
    trough_value = lowest_load_row['predicted_load_mw']

    print("\n--- Forecast Results ---")
    # Modified print statements to show the calculated range
    print(
        f"📈 Predicted Highest Load Range ({day_name}): From {peak_start_time.strftime('%H:%M')} to {peak_end_time.strftime('%H:%M')} (around {peak_value:.2f} MW)")
    print(
        f"📉 Predicted Lowest Load Range ({day_name}):  From {trough_start_time.strftime('%H:%M')} to {trough_end_time.strftime('%H:%M')} (around {trough_value:.2f} MW)")

    return future_df


# --- Main Execution ---
if __name__ == "__main__":
    DATA_FILE_PATH = 'modeldata.csv'

    prepared_df = prepare_data(DATA_FILE_PATH)
    plot_historical_data(prepared_df)

    model_file = train_and_save_model(prepared_df)
    last_known_timestamp = prepared_df['timestamp'].iloc[-1]
    forecast = predict_for_tomorrow(model_file, last_known_timestamp)

    plot_forecast_for_tomorrow(forecast)

    forecast.to_csv('tomorrow_forecast.csv', index=False)
    print("\nForecast for tomorrow saved to 'tomorrow_forecast.csv'")