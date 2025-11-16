from joblib import load
import pandas as pd
from pathlib import Path

# Activity level mapping (category → Harris-Benedict multiplier)
ACTIVITY_MULTIPLIERS = {
    0: 1.2,    # Sedentary (little/no exercise)
    1: 1.375,  # Lightly active (1-3 days/week)
    2: 1.55,   # Moderately active (3-5 days/week)
    3: 1.725,  # Very active (6-7 days/week)
    4: 1.9     # Extremely active (athlete)
}

def getUserTarget(user) -> tuple[int, float, float, float]:
    """
    Calculate target calories and macros for a user.
    
    Args:
        user: Dict with user profile data
        
    Returns:
        tuple: (calories, protein_g, fat_g, carb_g)
    """
    # Required fields for the model
    required_fields = ['Height_in', 'Weight_lb', 'Age', 'Gender', 'Activity_Level', 'Goal']
    missing_fields = [f for f in required_fields if f not in user]
    if missing_fields:
        raise ValueError(f"Missing required fields: {missing_fields}")

    # Load trained model
    model_path = Path(__file__).parents[3] / "artifacts" / "models" / "model.joblib"
    model = load(model_path)

    # Convert Activity_Level category to multiplier
    activity_level = user["Activity_Level"]
    if activity_level in ACTIVITY_MULTIPLIERS:
        activity_multiplier = ACTIVITY_MULTIPLIERS[activity_level]
    else:
        # If already a multiplier (1.2-1.9 range), use as-is
        activity_multiplier = float(activity_level)
        if not (1.2 <= activity_multiplier <= 1.9):
            raise ValueError(f"Invalid activity multiplier: {activity_multiplier}. Must be between 1.2 and 1.9.")

    # Create user data with mapped activity level
    user_data = pd.DataFrame([{
        'Height_in': user['Height_in'],
        'Weight_lb': user['Weight_lb'],
        'Age': user['Age'],
        'Gender': user['Gender'],
        'Activity_Level': activity_multiplier,
        'Goal': user['Goal']
    }])
    
    # Predict target calories
    target_calories = int(round(model.predict(user_data)[0]))

    # Macro Split Logic
    weight_lb = user["Weight_lb"]
    goal = int(user["Goal"])   # -1=lose, 0=maintain, 1=gain

    # Protein: 1.0g per lb for cutting, 0.8g for maintenance/bulking
    protein_g = (1.0 if goal == -1 else 0.8) * weight_lb
    protein_cals = protein_g * 4

    # Fat: 25% of calories for bulking, 30% otherwise
    fat_frac = 0.25 if goal == 1 else 0.30
    fat_cals = target_calories * fat_frac
    fat_g = fat_cals / 9
    
    # Minimum fat: 0.25g per lb for hormonal health
    min_fat_g = 0.25 * weight_lb
    fat_g = max(fat_g, min_fat_g)
    fat_cals = fat_g * 9

    # Carbs: remaining calories
    carb_cals = target_calories - (protein_cals + fat_cals)
    carb_g = max(carb_cals / 4, 0)

    return (
        target_calories,
        round(protein_g),
        round(fat_g),
        round(carb_g)
    )