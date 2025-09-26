# functions/main.py

import os
import pickle
import pandas as pd
import json
from firebase_functions import https_fn, options
from firebase_admin import initialize_app

initialize_app()

model = None

@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    cors=options.CorsOptions(
        cors_origins=["*"], 
        cors_methods=["get", "post", "options"]
    )
)
def predict_load(req: https_fn.Request) -> https_fn.Response:
    try:
        global model
        if model is None:
            model_path = os.path.join(os.path.dirname(__file__), "load_forecasting_model.pkl")
            with open(model_path, "rb") as f:
                model = pickle.load(f)

        data = req.get_json()
        if not data or 'data' not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'data' field in JSON body."}),
                status=400,
                headers={"Content-Type": "application/json"}
            )

        base_input = data['data']
        predictions = []

        # Build the correct input for each hour of tomorrow
        for hour in range(24):
            current_input = {
                "hour": hour,
                "day_of_week": int(base_input.get("day_of_week", 0)),
                "day_of_month": int(base_input.get("day_of_month", 1)),
                "month": int(base_input.get("month", 1)),
                "quarter": int(base_input.get("quarter", 1)),
                "year": int(base_input.get("year", 2025)),
                "is_weekend": int(base_input.get("is_weekend", 0))
            }

            input_df = pd.DataFrame([current_input])
            prediction = model.predict(input_df)
            predictions.append(round(float(prediction[0]), 2))  # round to 2 decimals

        return https_fn.Response(
            json.dumps({"predictions": predictions}),
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )
