import pandas as pd
import os

def clean_files():
    # Update these paths based on your actual file structure - relative to ML_Service root
    meal_paths = {
        "breakfast": "data/raw/by_meal_type/breakfast_recipes.csv",
        "lunch":     "data/raw/by_meal_type/lunch_recipes.csv", 
        "dinner":    "data/raw/by_meal_type/dinner_recipes.csv",
        "snack":     "data/raw/by_meal_type/snacks_recipes.csv",
    }
    staples_path = "data/raw/by_meal_type/staples.csv"

    meal_dfs = []

    # Handle meal recipe files - only process if they exist
    for meal_type, path in meal_paths.items():
        if not os.path.exists(path):
            print(f"Skipping {meal_type}: {path} not found")
            continue
            
        df = pd.read_csv(path)
        print(f"Processing {meal_type}: found {len(df)} rows")
        print(f"Columns: {list(df.columns)}")

        # Keep only what we need for ML
        cols_needed = [
            "id", "name",
            "calories", "protein_g", "carbs_g", "fat_g",
            "nutrition_quality_flag"
        ]
        
        # Some files might not have the flag; handle that gracefully
        available_cols = [c for c in cols_needed if c in df.columns]
        df = df[available_cols].copy()

        # Add meal_type
        df["meal_type"] = meal_type

        # Drop rows with missing macros
        for col in ["calories", "protein_g", "carbs_g", "fat_g"]:
            df = df[df[col].notna()]

        # Drop obvious garbage
        df = df[(df["calories"] >= 50) & (df["calories"] <= 1500)]
        for col in ["calories", "protein_g", "carbs_g", "fat_g"]:
            df = df[df[col] >= 0]

        # If nutrition_quality_flag exists, keep only "good" rows
        if "nutrition_quality_flag" in df.columns:
            df = df[df["nutrition_quality_flag"] == True]

        # Protein floor for non-snack meals
        if meal_type in ["breakfast", "lunch", "dinner"]:
            df = df[df["protein_g"] >= 5]

        # Rename to ML schema
        df = df.rename(columns={
            "id": "recipe_id",
            "calories": "per_serving_kcal"
        })
        
        # Convert recipe_id to string to ensure consistency
        df["recipe_id"] = df["recipe_id"].astype(str)

        meal_dfs.append(df[["recipe_id", "name", "meal_type",
                            "per_serving_kcal", "protein_g", "carbs_g", "fat_g"]])

    # Handle staples as snack-like items - only if file exists
    if os.path.exists(staples_path):
        staples = pd.read_csv(staples_path)

        staples = staples[["food_name", "calories", "protein_g", "carbs_g", "fat_g"]].copy()
        staples = staples.dropna(subset=["food_name", "calories", "protein_g", "carbs_g", "fat_g"])

        # Same basic macro filters
        staples = staples[(staples["calories"] >= 0) & (staples["calories"] <= 1500)]
        for col in ["protein_g", "carbs_g", "fat_g"]:
            staples = staples[staples[col] >= 0]

        # Generate synthetic IDs
        staples = staples.reset_index(drop=True)
        staples["recipe_id"] = staples.index.map(lambda i: f"staple_{i}")
        staples["name"] = staples["food_name"]
        staples["meal_type"] = "snack"

        staples = staples.rename(columns={
            "calories": "per_serving_kcal"
        })

        staples = staples[["recipe_id", "name", "meal_type",
                           "per_serving_kcal", "protein_g", "carbs_g", "fat_g"]]
        
        meal_dfs.append(staples)
    else:
        print(f"Skipping staples: {staples_path} not found")

    # Check if we have any data at all
    if not meal_dfs:
        raise ValueError("No data files found! Please check your data directory structure.")

    # Combine everything 
    combined = pd.concat(meal_dfs, ignore_index=True)

    # Deduplicate on recipe_id just in case
    combined = combined.drop_duplicates(subset=["recipe_id"])

    return combined

def clean_files_and_save():
    df = clean_files()
    
    print(f"Final dataframe shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"Data types:\n{df.dtypes}")
    print(f"Sample data:\n{df.head()}")
    
    # Create processed directory if it doesn't exist
    os.makedirs("data/processed", exist_ok=True)
    
    df.to_parquet("data/processed/all_meals_clean.parquet", index=False)
    print("Successfully saved to data/processed/all_meals_clean.parquet")
    return df


if __name__ == "__main__":
    clean_files_and_save()