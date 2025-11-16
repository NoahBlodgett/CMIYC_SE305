import pandas as pd
import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))
from src.models.meal_selector import GetMeals

def greedy_meal_selection(user, data, overused=[]):
    allergies = user.get('allergies', [])
    filter_out = allergies + overused

    # Load data
    breakfast_df = data['breakfast']
    lunch_df = data['lunch']
    dinner_df = data['dinner']
    snacks_df = data['snack']  # Use 'snack' to match the config

    if filter_out:
        print(f"Filtering out recipes with allergens or overused ingredients: {filter_out}")
        breakfast_df = filter_foods(breakfast_df, filter_out)
        lunch_df = filter_foods(lunch_df, filter_out)
        dinner_df = filter_foods(dinner_df, filter_out)
        snacks_df = filter_foods(snacks_df, filter_out)
    
    meal_planner = GetMeals(
        breakfast_df=breakfast_df,
        lunch_df=lunch_df,
        dinner_df=dinner_df,
        snacks_df=snacks_df,
    )

    meal_plan = meal_planner.create_meal_plan(user)

    ingredient_list = meal_plan.get('ingredients', [])

    return meal_plan, ingredient_list

def greedy_meal_selection_with_planner(user, data, overused=[], meal_planner=None):
    """Version that accepts and returns a meal planner to maintain state."""
    allergies = user.get('allergies', [])
    filter_out = allergies + overused

    # Load data
    breakfast_df = data['breakfast']
    lunch_df = data['lunch']
    dinner_df = data['dinner']
    snacks_df = data['snack']  # Use 'snack' to match the config

    if filter_out:
        print(f"Filtering out recipes with allergens or overused ingredients: {filter_out}")
        breakfast_df = filter_foods(breakfast_df, filter_out)
        lunch_df = filter_foods(lunch_df, filter_out)
        dinner_df = filter_foods(dinner_df, filter_out)
        snacks_df = filter_foods(snacks_df, filter_out)
    
    # Create new planner if none provided, or reuse existing one
    if meal_planner is None:
        meal_planner = GetMeals(
            breakfast_df=breakfast_df,
            lunch_df=lunch_df,
            dinner_df=dinner_df,
            snacks_df=snacks_df,
        )
    else:
        # Update the existing planner with filtered data
        meal_planner.breakfast_df = breakfast_df
        meal_planner.lunch_df = lunch_df
        meal_planner.dinner_df = dinner_df
        meal_planner.snacks_df = snacks_df

    meal_plan = meal_planner.create_meal_plan(user)
    ingredient_list = meal_plan.get('ingredients', [])

    return meal_plan, ingredient_list, meal_planner

def weekly_greedy_meal_selection(user, data, ingredients=None):

    week_plan = {}

    if ingredients is None:
        ingredients = {}
    ingredient_counts = ingredients.copy()  # Dict like {'chicken': 2, 'rice': 1}
    
    # Create a single meal planner instance to track used recipes across the week
    global_meal_planner = None
    
    for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]:
        # Filter DataFrames based on current ingredient_counts
        # Create meal plan for the day
        overused = []  # Initialize empty overused list

        if ingredient_counts:
            # Only mark ingredients as overused if they've been used 4+ times (instead of 3+)
            # This prevents filtering out too many meals
            overused = [ingredient for ingredient, count in ingredient_counts.items() if count >= 4]

        # Pass the global meal planner to maintain used recipe tracking
        daily_plan, _, global_meal_planner = greedy_meal_selection_with_planner(user, data, overused, global_meal_planner)
        
        # Extract ingredients from today's meals
        todays_ingredients = getIngredients(daily_plan)
        print(f"{day} ingredients: {todays_ingredients}")
        
        # Update running counts for each ingredient used today
        for ingredient in todays_ingredients:
            if ingredient in ingredient_counts:
                ingredient_counts[ingredient] += 1
            else:
                ingredient_counts[ingredient] = 1
        
        print(f"Running ingredient counts after {day}: {dict(list(ingredient_counts.items())[:5])}")  # Show first 5
            
        # Store the day's plan
        week_plan[day] = daily_plan
    
    return week_plan, ingredient_counts  

# Filter out recipes with allergens using regex
def filter_foods(df, filters):
    if not filters:
        return df
    
    # Create single regex pattern for all allergens
    filters_pattern = '|'.join(filters)
    
    # Check if this is a recipe DataFrame (has 'ingredients' column) or staples DataFrame (has 'food_name' column)
    if 'ingredients' in df.columns:
        # Recipe DataFrame - filter by ingredients
        return df[~df['ingredients'].str.contains(filters_pattern, case=False, na=False, regex=True)]
    elif 'food_name' in df.columns:
        # Staples DataFrame - filter by food name
        return df[~df['food_name'].str.contains(filters_pattern, case=False, na=False, regex=True)]
    else:
        # Unknown structure, return unchanged
        return df

def getIngredients(meal_plan):
    ingredients = []
    
    meals = meal_plan.get('meals', {})
    
    for meal_type in ['breakfast', 'lunch', 'dinner', 'snacks']:
        meal_data = meals.get(meal_type, {})
        recipe_data = meal_data.get('recipe', {})
        meal_ingredients = recipe_data.get('ingredients', [])
        
        if meal_ingredients and not isinstance(meal_ingredients, float):
            # Handle both string and list ingredients
            if isinstance(meal_ingredients, str):
                # Parse ingredients string that looks like "['ingredient1', 'ingredient2', ...]"
                # Remove brackets and quotes, then split
                cleaned = meal_ingredients.strip("[]").replace("'", "").replace('"', '')
                ingredients.extend([ing.strip() for ing in cleaned.split(',') if ing.strip()])
            elif isinstance(meal_ingredients, list):
                ingredients.extend(meal_ingredients)
            # Skip any other data types (float, int, etc.)
    return ingredients