"""
Meal Type Separator Script
Categorizes cleaned recipes into breakfast, lunch, dinner, and snacks based on tags and keywords.
"""

import pandas as pd
import ast
import numpy as np
from pathlib import Path

def parse_tags(tag_str):
    """Safely parse tags string into a list"""
    try:
        if pd.isna(tag_str):
            return []
        return ast.literal_eval(tag_str)
    except:
        return []

def classify_meal_type(tags_str):
    """
    Classify recipe into meal categories based on tags only.
    Uses strict classification to avoid overlaps and keep categories clean.
    Returns list of meal types (prioritizes most specific meal type).
    """
    tags = parse_tags(tags_str)
    tags_lower = [tag.lower() for tag in tags if tag]
    
    # Define all meal indicators
    breakfast_indicators = ['breakfast']
    lunch_indicators = ['lunch', 'luncheon'] 
    dinner_indicators = ['dinner', 'main-dish', 'main-course', 'dinner-party', 'supper']
    snack_indicators = ['snacks', 'appetizers', 'finger-food', 'hors-d-oeuvres']
    dessert_indicators = ['desserts', 'sweet', 'candy', 'cookies-and-bars']
    
    # Check which categories this recipe belongs to
    has_breakfast = any(tag in tags_lower for tag in breakfast_indicators)
    has_lunch = any(tag in tags_lower for tag in lunch_indicators)
    has_dinner = any(tag in tags_lower for tag in dinner_indicators)
    has_snacks = any(tag in tags_lower for tag in snack_indicators)
    has_dessert = any(tag in tags_lower for tag in dessert_indicators)
    
    # STRICT CLASSIFICATION: Only assign ONE primary meal type
    # Priority order: Breakfast > Lunch > Dinner > Snacks/Desserts
    
    meal_types = []
    
    if has_breakfast and not (has_lunch or has_dinner):
        # Pure breakfast - no conflicting meal tags
        meal_types.append('breakfast')
    elif has_lunch and not (has_breakfast or has_dinner):
        # Pure lunch - no conflicting meal tags  
        meal_types.append('lunch')
    elif has_dinner and not (has_breakfast or has_lunch):
        # Pure dinner - no conflicting meal tags
        meal_types.append('dinner')
    elif (has_snacks or has_dessert) and not (has_breakfast or has_lunch or has_dinner):
        # Pure snacks/desserts - no conflicting meal tags
        meal_types.append('snacks')
    
    # If recipe has conflicting meal tags, skip it (no classification)
    # This ensures clean, non-overlapping categories
    
    return meal_types

def separate_meal_types(input_file, output_dir):
    """
    Main function to separate recipes by meal type
    """
    print("Loading recipe data...")
    
    # Load cleaned recipes
    df_cleaned = pd.read_csv(input_file)
    
    # Load original data for tags
    original_file = input_file.replace('cleaned_recipes.csv', 'RAW_recipes.csv')
    df_original = pd.read_csv(original_file)
    
    # Merge to get tags
    print("Merging with original data for tags...")
    df = df_cleaned.merge(df_original[['id', 'tags']], on='id', how='left')
    
    print(f"Processing {len(df)} recipes...")
    
    # Classify meal types (tags only)
    print("Classifying meal types based on tags...")
    df['meal_types'] = df['tags'].apply(classify_meal_type)
    
    # Filter only recipes that have at least one meal type
    df_with_types = df[df['meal_types'].str.len() > 0].copy()
    print(f"Found {len(df_with_types)} recipes with meal type tags ({len(df_with_types)/len(df)*100:.1f}%)")
    
    # Create output directory
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # Separate into different files
    meal_categories = ['breakfast', 'lunch', 'dinner', 'snacks']
    results = {}
    
    for category in meal_categories:
        print(f"\\nProcessing {category} recipes...")
        
        # Filter recipes that belong to this category
        category_mask = df_with_types['meal_types'].apply(
            lambda x: isinstance(x, list) and category in x
        )
        category_df = df_with_types[category_mask].copy()
        
        # Remove the meal_types column for cleaner output
        category_df = category_df.drop('meal_types', axis=1)
        
        # Save to CSV
        output_file = f"{output_dir}/{category}_recipes.csv"
        category_df.to_csv(output_file, index=False)
        
        results[category] = len(category_df)
        print(f"Saved {len(category_df)} {category} recipes to {output_file}")
        
        # Show sample recipes
        if len(category_df) > 0:
            print(f"Sample {category} recipes:")
            sample = category_df[['name', 'calories', 'protein_g']].head(5)
            for idx, row in sample.iterrows():
                print(f"  - {row['name']}: {row['calories']:.0f} cal, {row['protein_g']:.1f}g protein")
    
    # Create a summary file with overlaps
    print("\\nCreating overlap analysis...")
    
    # Count overlaps
    overlap_counts = {}
    for idx, row in df_with_types.iterrows():
        meal_combo = tuple(sorted(row['meal_types']))
        overlap_counts[meal_combo] = overlap_counts.get(meal_combo, 0) + 1
    
    print("\\nMeal type distribution:")
    for combo, count in sorted(overlap_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {' + '.join(combo)}: {count} recipes")
    
    return results

if __name__ == "__main__":
    # Configuration
    input_file = "data/foods/cleaned_recipes.csv"
    output_dir = "data/foods/by_meal_type"
    
    print("=== MEAL TYPE SEPARATOR ===")
    print(f"Input: {input_file}")
    print(f"Output directory: {output_dir}")
    
    # Run separation
    results = separate_meal_types(input_file, output_dir)
    
    print("\\n=== FINAL SUMMARY ===")
    total_categorized = sum(results.values())
    for meal_type, count in results.items():
        print(f"{meal_type.capitalize()}: {count:,} recipes")
    
    print(f"\\nTotal categorized: {total_categorized:,} recipes")
    print("\\nNote: Some recipes may appear in multiple categories!")
    print("Only recipes with explicit meal type tags are included.")