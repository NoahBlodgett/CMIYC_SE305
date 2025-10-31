from joblib import load
import pandas as pd
from pathlib import Path

def getUserTarget(user):
    # Add validation
    required_fields = ['Height_in', 'Weight_lb', 'Age', 'Gender', 'Activity_Level', 'Goal']
    
    # Check if all required fields are present
    missing_fields = [field for field in required_fields if field not in user]
    if missing_fields:
        raise ValueError(f"Missing required fields: {missing_fields}")
    
    model_path = Path(__file__).parents[3] / "artifacts" / "models" / "model.joblib"
    model = load(model_path)

    # Only use the required fields (ignore extra database fields)
    user_data = {field: user[field] for field in required_fields}
    user_X = pd.DataFrame([user_data])

    pred = model.predict(user_X)
    return float(pred[0]) 
