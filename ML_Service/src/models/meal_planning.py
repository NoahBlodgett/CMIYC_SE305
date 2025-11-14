import pandas as pd
import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))
from src.models.meal_selector import GetMeals

def greedy_meal_selection(user, overused):
    allergies = user.get('allergies', [])
    filter_out = allergies + overused

    # Load data
    breakfast_df = pd.read_csv('data/raw/by_meal_type/breakfast_recipes.csv')
    lunch_df = pd.read_csv('data/raw/by_meal_type/lunch_recipes.csv')
    dinner_df = pd.read_csv('data/raw/by_meal_type/dinner_recipes.csv')
    snacks_df = pd.read_csv('data/raw/by_meal_type/snacks_recipes.csv')
    staples_df = pd.read_csv('data/raw/by_meal_type/staples.csv')

    if filter_out:
        print(f"Filtering out recipes with allergens or overused ingredients: {filter_out}")
        breakfast_df = filter_foods(breakfast_df, filter_out)
        lunch_df = filter_foods(lunch_df, filter_out)
        dinner_df = filter_foods(dinner_df, filter_out)
        snacks_df = filter_foods(snacks_df, filter_out)
        staples_df = filter_foods(staples_df, filter_out)
    
    meal_planner = GetMeals(
        breakfast_df=breakfast_df,
        lunch_df=lunch_df,
        dinner_df=dinner_df,
        snacks_df=snacks_df,
        staples_df=staples_df
    )

    meal_plan = meal_planner.create_meal_plan(user)

    ingredient_list = meal_plan.get('ingredients', [])

    return meal_plan, ingredient_list

def weekly_greedy_meal_selection(user, ingredients=None):
    allergies = user.get('allergies', [])

    # Load data
    breakfast_df = pd.read_csv('data/raw/by_meal_type/breakfast_recipes.csv')
    lunch_df = pd.read_csv('data/raw/by_meal_type/lunch_recipes.csv')
    dinner_df = pd.read_csv('data/raw/by_meal_type/dinner_recipes.csv')
    snacks_df = pd.read_csv('data/raw/by_meal_type/snacks_recipes.csv')
    staples_df = pd.read_csv('data/raw/by_meal_type/staples.csv')

    if allergies:
        print(f"Filtering out recipes with allergens: {allergies}")
        breakfast_df = filter_foods(breakfast_df, allergies)
        lunch_df = filter_foods(lunch_df, allergies)
        dinner_df = filter_foods(dinner_df, allergies)
        snacks_df = filter_foods(snacks_df, allergies)
        staples_df = filter_foods(staples_df, allergies)
    
    week_plan = {}

    if ingredients is None:
        ingredients = {}
    ingredient_counts = ingredients.copy()  # Dict like {'chicken': 2, 'rice': 1}
    
    for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]:
        # Filter DataFrames based on current ingredient_counts
        # Create meal plan for the day
        overused = []  # Initialize empty overused list

        if ingredient_counts:
            # Only mark ingredients as overused if they've been used 4+ times (instead of 3+)
            # This prevents filtering out too many meals
            overused = [ingredient for ingredient, count in ingredient_counts.items() if count >= 4]

        daily_plan, _ = greedy_meal_selection(user, overused)
        
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
        if meal_ingredients:
            # Handle both string and list ingredients
            if isinstance(meal_ingredients, str):
                # Parse ingredients string that looks like "['ingredient1', 'ingredient2', ...]"
                # Remove brackets and quotes, then split
                cleaned = meal_ingredients.strip("[]").replace("'", "").replace('"', '')
                ingredients.extend([ing.strip() for ing in cleaned.split(',') if ing.strip()])
            else:
                ingredients.extend(meal_ingredients)
    return ingredients