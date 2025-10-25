#!/usr/bin/env python3
"""
Process nutrition.csv dataset to create a clean staples.csv file with essential nutrients.
"""

import pandas as pd
import os
import re

def process_nutrition_data():
    """Process nutrition data and create staples.csv with essential nutrients only"""
    
    # File paths
    data_dir = "data/foods"
    nutrition_file = os.path.join(data_dir, "nutrition.csv")
    output_file = os.path.join(data_dir, "staples.csv")
    
    print("Loading nutrition.csv file...")
    
    # Load data
    df = pd.read_csv(nutrition_file)
    
    print(f"Loaded {len(df)} food items")
    print(f"Original columns: {len(df.columns)}")
    
    # Extract essential columns only
    essential_columns = {
        'name': 'food_name',
        'serving_size': 'serving_size', 
        'calories': 'calories',
        'protein': 'protein_g',
        'carbohydrate': 'carbs_g',
        'total_fat': 'fat_g'
    }
    
    # Select and rename columns
    df_clean = df[list(essential_columns.keys())].copy()
    df_clean = df_clean.rename(columns=essential_columns)
    
    print(f"Selected essential columns: {list(df_clean.columns)}")
    
    # Clean the data
    def clean_numeric_value(value):
        """Extract numeric value from strings like '72g', '100 g', etc."""
        if pd.isna(value):
            return None
        
        # Convert to string and remove extra whitespace
        value_str = str(value).strip()
        
        # Extract numeric part using regex
        match = re.search(r'(\d+\.?\d*)', value_str)
        if match:
            return float(match.group(1))
        return None
    
    # Clean numeric columns
    numeric_columns = ['calories', 'protein_g', 'carbs_g', 'fat_g']
    
    for col in numeric_columns:
        df_clean[col] = df_clean[col].apply(clean_numeric_value)
    
    # Clean serving size (keep as string but standardize)
    def clean_serving_size(value):
        """Standardize serving size format"""
        if pd.isna(value):
            return "100g"
        
        value_str = str(value).strip()
        # Most common formats: "100 g", "100g", etc.
        # Standardize to "100g" format
        match = re.search(r'(\d+\.?\d*)\s*g', value_str, re.IGNORECASE)
        if match:
            return f"{match.group(1)}g"
        return value_str
    
    df_clean['serving_size'] = df_clean['serving_size'].apply(clean_serving_size)
    
    # Remove rows with missing essential data
    print(f"Before cleaning: {len(df_clean)} rows")
    
    # Drop rows missing any essential nutrients
    df_clean = df_clean.dropna(subset=numeric_columns)
    
    # Remove duplicates
    df_clean = df_clean.drop_duplicates(subset=['food_name'])
    
    print(f"After cleaning: {len(df_clean)} rows")
    
    # Round numeric values to 1 decimal place
    for col in numeric_columns:
        df_clean[col] = df_clean[col].round(1)
    
    # Reorder columns for better readability
    final_columns = ['food_name', 'serving_size', 'calories', 'protein_g', 'carbs_g', 'fat_g']
    df_clean = df_clean[final_columns]
    
    # Save result
    df_clean.to_csv(output_file, index=False)
    print(f"Saved cleaned data to {output_file}")
    
    # Show sample
    print("\nSample of processed data:")
    print(df_clean.head(10))
    
    # Show summary stats
    print(f"\nDataset summary:")
    print(f"- Total foods: {len(df_clean)}")
    print(f"- Columns: {list(df_clean.columns)}")
    print(f"- Average calories per serving: {df_clean['calories'].mean():.1f}")
    print(f"- Foods with 100g serving: {len(df_clean[df_clean['serving_size'] == '100g'])}")
    
    return df_clean

if __name__ == "__main__":
    process_nutrition_data()