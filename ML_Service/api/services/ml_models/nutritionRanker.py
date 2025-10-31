from joblib import load
import pandas as pd
from pathlib import Path

def getUserTarget(user):
    # Required fields for the model
    required_fields = ['Height_in', 'Weight_lb', 'Age', 'Gender', 'Activity_Level', 'Goal']
    missing_fields = [f for f in required_fields if f not in user]
    if missing_fields:
        raise ValueError(f"Missing required fields: {missing_fields}")

    # Load trained model
    model_path = Path(__file__).parents[3] / "artifacts" / "models" / "model.joblib"
    model = load(model_path)

    # Predict target calories
    user_data = {field: user[field] for field in required_fields}
    user_X = pd.DataFrame([user_data])
    target_calories = float(model.predict(user_X)[0])

    # Macro Split Logic
    weight_lb = user["Weight_lb"]
    goal = int(user["Goal"])   # -1=lose, 0=maintain, 1=gain

    # Protein
    protein_g = (1.0 if goal == -1 else 0.8) * weight_lb
    protein_cals = protein_g * 4

    # Fat 
    fat_frac = 0.25 if goal == 1 else 0.30
    fat_cals = target_calories * fat_frac
    fat_g = fat_cals / 9
    min_fat_g = 0.25 * weight_lb
    fat_g = max(fat_g, min_fat_g)
    fat_cals = fat_g * 9 #(1g fat = 9 cals)

    # Carbs (leftover)
    carb_cals = target_calories - (protein_cals + fat_cals)
    carb_g = max(carb_cals / 4, 0)

    # Round everything
    result = {
        "calories": round(target_calories),
        "protein_g": round(protein_g),
        "fat_g": round(fat_g),
        "carb_g": round(carb_g)
    }

    return result
