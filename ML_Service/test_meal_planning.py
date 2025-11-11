#!/usr/bin/env python3
"""
Test script for the meal planning functionality
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from scripts.greedy_meal import weekly_greedy_meal_selection

def test_weekly_meal_planning():
    # Test user data
    test_user = {
        'allergies': ['peanuts'],  # Example allergy
        'activity_level': 'moderate',
        # Required fields for ML model
        'Height_in': 70,  # 5'10"
        'Weight_lb': 180,
        'Age': 30,
        'Gender': 0,  # 0 = Female, 1 = Male (based on training data)
        'Activity_Level': 3,  # moderate
        'Goal': 0  # -1 = lose, 0 = maintain, 1 = gain
    }
    
    print("Testing weekly meal planning...")
    print(f"User data: {test_user}")
    
    try:
        # Test with empty ingredient tracking dictionary initially
        weekly_meals, total_ingredients = weekly_greedy_meal_selection(test_user, {})
        
        print("\n✅ Weekly meal planning completed successfully!")
        print(f"Generated meal plans for {len(weekly_meals)} days")
        
        # Print summary of each day
        for day_idx, (day_name, day_data) in enumerate(weekly_meals.items()):
            print(f"\nDay {day_idx + 1} ({day_name}):")
            if isinstance(day_data, dict) and 'meals' in day_data:
                meals = day_data['meals']
                for meal_type, meal_data in meals.items():
                    if meal_data and isinstance(meal_data, dict):
                        # The actual recipe data is nested under 'recipe'
                        recipe_data = meal_data.get('recipe', {})
                        if isinstance(recipe_data, dict):
                            meal_name = recipe_data.get('recipe_title', recipe_data.get('name', recipe_data.get('food_name', 'Unknown')))
                            calories = recipe_data.get('calories', 0)
                            print(f"  {meal_type.title()}: {meal_name} ({calories} calories)")
                        else:
                            print(f"  {meal_type.title()}: No recipe data")
                    else:
                        print(f"  {meal_type.title()}: Empty meal")
            else:
                print(f"  Unexpected structure: {type(day_data)}")
        
        print(f"\nTotal unique ingredients used across the week: {len(total_ingredients)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during weekly meal planning: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_weekly_meal_planning()
    if success:
        print("\n🎉 All tests passed!")
    else:
        print("\n💥 Tests failed!")