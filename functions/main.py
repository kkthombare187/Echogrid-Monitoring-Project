# functions/main.py

import os
import pickle
import pandas as pd
import json
from firebase_functions import https_fn, options
from firebase_admin import initialize_app

initialize_app()

model = None

# --- MODIFIED LINE ---
# Add the memory option to the decorator
@https_fn.on_request(
    memory=options.MemoryOption.GB_1, 
    cors=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])
)
def predict_load(req: https_fn.Request) -> https_fn.Response:
    try:
        global model
        if model is None:
            model_path = os.path.join(os.path.dirname(__file__), "load_forecasting_model.pkl")
            with open(model_path, "rb") as f:
                model = pickle.load(f)

        # ... the rest of your function code remains exactly the same ...
        data = req.get_json()
        if not data or 'data' not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'data' field in JSON body."}),
                status=400,
                headers={"Content-Type": "application/json"}
            )

        base_input = data['data']
        predictions = []

        for hour in range(24):
            current_input = base_input.copy()
            current_input['hour_of_day'] = hour
            input_df = pd.DataFrame([current_input])
            prediction = model.predict(input_df)
            predictions.append(float(prediction[0]))

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