import pandas as pd
import ast
import numpy as np

def parse_raw_recipes(input_file, output_file):
    """
    Parse RAW_recipes.csv and extract key columns with proper nutrition conversion.
    
    Converts %DV nutrition values to grams using FDA Daily Values:
    - Fat: 78g DV
    - Saturated Fat: 20g DV  
    - Carbs: 275g DV
    - Protein: 50g DV
    - Sodium: 2300mg DV
    - Sugar: 50g DV
    """
    
    # FDA Daily Values for conversion
    DV_VALUES = {
        'fat': 78,           # grams
        'saturated_fat': 20, # grams
        'carbs': 275,        # grams
        'protein': 50,       # grams
        'sodium': 2300,      # mg
        'sugar': 50          # grams
    }
    
    print("Loading RAW_recipes.csv...")
    df = pd.read_csv(input_file)
    
    print(f"Original shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    
    # Select only the columns you want
    columns_to_keep = ['id', 'name', 'nutrition', 'ingredients', 'n_ingredients', 'steps', 'description']
    
    # Check which columns exist
    existing_columns = [col for col in columns_to_keep if col in df.columns]
    missing_columns = [col for col in columns_to_keep if col not in df.columns]
    
    if missing_columns:
        print(f"Warning: Missing columns: {missing_columns}")
    
    # Keep only existing columns
    df_filtered = df[existing_columns].copy()
    
    print("Parsing nutrition data...")
    
    def parse_nutrition(nutrition_str):
        """Parse nutrition string and convert %DV to grams"""
        try:
            # Parse the string list
            nutrition_list = ast.literal_eval(nutrition_str)
            
            if len(nutrition_list) != 7:
                return {
                    'calories': np.nan,
                    'fat_g': np.nan,
                    'sugar_g': np.nan,
                    'sodium_mg': np.nan,
                    'protein_g': np.nan,
                    'saturated_fat_g': np.nan,
                    'carbs_g': np.nan
                }
            
            # Extract values: [calories, fat_%DV, sugar_%DV, sodium_%DV, protein_%DV, sat_fat_%DV, carbs_%DV]
            calories = nutrition_list[0]
            fat_pdv = nutrition_list[1]
            sugar_pdv = nutrition_list[2]
            sodium_pdv = nutrition_list[3]
            protein_pdv = nutrition_list[4]
            sat_fat_pdv = nutrition_list[5]
            carbs_pdv = nutrition_list[6]
            
            # Convert %DV to grams/mg
            fat_g = (fat_pdv * DV_VALUES['fat']) / 100 if fat_pdv is not None else np.nan
            sugar_g = (sugar_pdv * DV_VALUES['sugar']) / 100 if sugar_pdv is not None else np.nan
            sodium_mg = (sodium_pdv * DV_VALUES['sodium']) / 100 if sodium_pdv is not None else np.nan
            protein_g = (protein_pdv * DV_VALUES['protein']) / 100 if protein_pdv is not None else np.nan
            sat_fat_g = (sat_fat_pdv * DV_VALUES['saturated_fat']) / 100 if sat_fat_pdv is not None else np.nan
            carbs_g = (carbs_pdv * DV_VALUES['carbs']) / 100 if carbs_pdv is not None else np.nan
            
            return {
                'calories': calories,
                'fat_g': round(fat_g, 2) if not pd.isna(fat_g) else np.nan,
                'sugar_g': round(sugar_g, 2) if not pd.isna(sugar_g) else np.nan,
                'sodium_mg': round(sodium_mg, 1) if not pd.isna(sodium_mg) else np.nan,
                'protein_g': round(protein_g, 2) if not pd.isna(protein_g) else np.nan,
                'saturated_fat_g': round(sat_fat_g, 2) if not pd.isna(sat_fat_g) else np.nan,
                'carbs_g': round(carbs_g, 2) if not pd.isna(carbs_g) else np.nan
            }
            
        except (ValueError, SyntaxError, TypeError):
            # Return NaN for unparseable nutrition data
            return {
                'calories': np.nan,
                'fat_g': np.nan,
                'sugar_g': np.nan,
                'sodium_mg': np.nan,
                'protein_g': np.nan,
                'saturated_fat_g': np.nan,
                'carbs_g': np.nan
            }
    
    # Parse nutrition column if it exists
    if 'nutrition' in df_filtered.columns:
        nutrition_data = df_filtered['nutrition'].apply(parse_nutrition)
        nutrition_df = pd.json_normalize(nutrition_data)
        
        # Add nutrition columns to main dataframe
        for col in nutrition_df.columns:
            df_filtered[col] = nutrition_df[col]
    
    # Add a sanity check column for calories vs macros
    if all(col in df_filtered.columns for col in ['calories', 'protein_g', 'carbs_g', 'fat_g']):
        df_filtered['calculated_calories'] = (
            (df_filtered['protein_g'] * 4) + 
            (df_filtered['carbs_g'] * 4) + 
            (df_filtered['fat_g'] * 9)
        ).round(0)
        
        # Calculate relative error
        df_filtered['calorie_error_pct'] = (
            abs(df_filtered['calories'] - df_filtered['calculated_calories']) / 
            df_filtered['calories'] * 100
        ).round(1)
        
        # Flag suspicious entries (>40% error)
        df_filtered['nutrition_quality_flag'] = df_filtered['calorie_error_pct'] < 40
    
    print("Cleaning outliers...")
    
    # Clip extreme outliers (99th percentile cap)
    nutrition_cols = ['fat_g', 'sugar_g', 'protein_g', 'saturated_fat_g', 'carbs_g']
    for col in nutrition_cols:
        if col in df_filtered.columns:
            q99 = df_filtered[col].quantile(0.99)
            df_filtered[col] = df_filtered[col].clip(upper=q99)
    
    # Remove rows with zero or negative calories
    if 'calories' in df_filtered.columns:
        df_filtered = df_filtered[df_filtered['calories'] > 0]
    
    print(f"Final shape: {df_filtered.shape}")
    print(f"Columns: {list(df_filtered.columns)}")
    
    # Save to CSV
    df_filtered.to_csv(output_file, index=False)
    print(f"Saved cleaned data to: {output_file}")
    
    # Print some stats
    if 'nutrition_quality_flag' in df_filtered.columns:
        good_nutrition = df_filtered['nutrition_quality_flag'].sum()
        total = len(df_filtered)
        print(f"Nutrition quality: {good_nutrition}/{total} ({good_nutrition/total*100:.1f}%) recipes have reasonable calorie calculations")
    
    return df_filtered

# Usage
if __name__ == "__main__":
    # Adjust paths as needed
    input_file = "data/foods/RAW_recipes.csv"
    output_file = "data/foods/cleaned_recipes.csv"
    
    df = parse_raw_recipes(input_file, output_file)
    
    # Show sample of results
    print("\nSample of cleaned data:")
    sample_cols = ['id', 'name', 'calories', 'protein_g', 'carbs_g', 'fat_g', 'calculated_calories', 'nutrition_quality_flag']
    available_cols = [col for col in sample_cols if col in df.columns]
    print(df[available_cols].head())