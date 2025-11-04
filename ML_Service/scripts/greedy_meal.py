import pandas as pd
from pathlib import Path


def greedy_meals(target_calories, food_data_path="../data/foods/staples.csv"):
   
    # Meal splits (should add up to 1.0)
    splits = {
        'breakfast': 0.25,  # 25% of daily calories
        'lunch': 0.35,      # 35% of daily calories  
        'dinner': 0.35,     # 35% of daily calories
        'snack': 0.05       # 5% of daily calories
    }
    
    # Load food database
    foods_df = pd.read_csv(food_data_path)
    
    meal_plan = {}
    
    for meal, split in splits.items():
        target_meal_calories = target_calories * split
        meal_foods = select_foods(foods_df, target_meal_calories)
        meal_plan[meal] = meal_foods
    
    return meal_plan

def select_foods(foods_df, target_calories, tolerance=50):
    selected_foods = []
    remaining_calories = target_calories

    # ✅ BETTER: Sort by a balanced score, not just calories
    # Could sort by protein density, or calorie efficiency, or randomly
    foods_df = foods_df.sample(frac=1).reset_index(drop=True)  # Shuffle for variety
    
    while remaining_calories > tolerance and len(foods_df) > 0:
        best_food = None
        best_score = float('inf')
        
        for _, food in foods_df.iterrows():  
            calories = food['kcal_per_100g']
            
            # ✅ BETTER: Target reasonable portion sizes (50-300g)
            if 50 <= calories <= 500:  # Only foods with reasonable calorie density
                # Calculate how much we'd need of this food
                needed_serving = (remaining_calories / calories) * 100
                
                # Only consider if serving size is reasonable (50-300g)
                if 50 <= needed_serving <= 300:
                    score = abs(remaining_calories - calories)
                    if score < best_score:
                        best_score = score
                        best_food = food
        
        if best_food is not None:
            # Take a reasonable portion, not necessarily all remaining calories
            max_portion_calories = min(remaining_calories, 400)  # Cap at 400 cal per food
            actual_calories = min(max_portion_calories, best_food['kcal_per_100g'])
            serving_size = (actual_calories / best_food['kcal_per_100g']) * 100
            
            selected_foods.append({
                'food_name': best_food['description'],
                'serving_size_g': round(serving_size, 1),
                'calories': round(actual_calories, 1),
                'protein_g': round((best_food['protein_per_100g'] / 100) * serving_size, 1),
                'carbs_g': round((best_food['carbs_per_100g'] / 100) * serving_size, 1),
                'fat_g': round((best_food['fat_per_100g'] / 100) * serving_size, 1)
            })
            
            remaining_calories -= actual_calories
            
            # Remove this food to ensure variety
            foods_df = foods_df[foods_df['fdc_id'] != best_food['fdc_id']]
        else:
            break

    return selected_foods