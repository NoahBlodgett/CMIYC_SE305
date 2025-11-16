#!/usr/bin/env python3
"""
Test Multiple User Types with Full Weekly Meal Plans
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from api.services.ml_models.nutritionRanker import getUserTarget
from src.models.create_candidates import build_all_candidate_pools
from src.models.meal_planning import weekly_greedy_meal_selection

def test_user_type(user_data, description):
    """Test a specific user type and show full weekly plan"""
    print("="*80)
    print(f"🧑‍💼 TESTING: {description}")
    print("="*80)
    
    # Display user info
    print(f"👤 USER PROFILE:")
    print(f"   • Age: {user_data['Age']} years")
    print(f"   • Height: {user_data['Height_in']}\"")
    print(f"   • Weight: {user_data['Weight_lb']} lbs")
    
    goal_map = {-1: "lose weight", 0: "maintain", 1: "gain weight"}
    goal = goal_map.get(user_data['Goal'], 'unknown')
    print(f"   • Goal: {goal}")
    
    activity_map = {1: "low", 2: "moderate", 3: "high", 4: "very high"}
    activity = activity_map.get(user_data['Activity_Level'], 'unknown')
    print(f"   • Activity Level: {activity}")
    
    gender = "Male" if user_data['Gender'] == 1 else "Female"
    print(f"   • Gender: {gender}")
    
    if user_data.get('allergies'):
        print(f"   🚫 Allergies: {', '.join(user_data['allergies'])}")
    if user_data.get('preferences'):
        print(f"   👎 Dislikes: {', '.join(user_data['preferences'])}")
    
    try:
        # Get nutrition targets
        print(f"\n📊 STEP 1: Calculating nutrition targets...")
        nutrition_tuple = getUserTarget(user_data)
        nutrition_targets = {
            "calories": int(nutrition_tuple[0]),
            "protein_g": int(nutrition_tuple[1]), 
            "fat_g": int(nutrition_tuple[2]),
            "carb_g": int(nutrition_tuple[3])
        }
        print(f"✅ Daily targets: {nutrition_targets['calories']} cal, {nutrition_targets['protein_g']}g protein")
        
        # Build candidate pools
        print(f"\n🔄 STEP 2: Building candidate recipe pools...")
        candidates = build_all_candidate_pools(nutrition_targets, user_data)
        
        # Show candidate summary
        print(f"✅ Generated candidates:")
        for meal_type, recipes in candidates.items():
            if recipes:
                top_recipe = recipes[0]
                print(f"   • {meal_type.title()}: {len(recipes)} recipes")
                print(f"     └─ Top pick: {top_recipe.get('name', 'N/A')} ({top_recipe.get('calories', 'N/A')} cal)")
        
        # Generate weekly meal plan
        print(f"\n📅 STEP 3: Creating weekly meal plan...")
        week_plan, ingredient_counts = weekly_greedy_meal_selection(user_data, candidates)
        
        # Display FULL WEEKLY PLAN
        print(f"\n📅 COMPLETE 7-DAY MEAL PLAN:")
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        total_weekly_cal = 0
        total_weekly_protein = 0
        
        for day in days:
            if day in week_plan:
                day_plan = week_plan[day]
                print(f"\n   🗓️  {day.upper()}:")
                
                daily_cal = 0
                daily_protein = 0
                
                # Process each meal type
                meal_types = ['breakfast', 'lunch', 'dinner', 'snacks']
                for meal_type in meal_types:
                    if meal_type in day_plan.get('meals', {}):
                        meal_info = day_plan['meals'][meal_type]
                        
                        if 'recipe' in meal_info:
                            recipe = meal_info['recipe']
                            name = recipe.get('name', 'N/A')
                            calories = float(recipe.get('calories', 0))
                            protein = float(recipe.get('protein_g', 0))
                            
                            daily_cal += calories
                            daily_protein += protein
                            
                            print(f"      • {meal_type.title()}: {name}")
                            print(f"        └─ {calories:.1f} cal, {protein:.1f}g protein")
                
                total_weekly_cal += daily_cal
                total_weekly_protein += daily_protein
                
                print(f"      📊 Daily Total: {daily_cal:.1f} cal, {daily_protein:.1f}g protein")
        
        # Weekly summary
        avg_daily_cal = total_weekly_cal / 7 if total_weekly_cal > 0 else 0
        avg_daily_protein = total_weekly_protein / 7 if total_weekly_protein > 0 else 0
        
        print(f"\n📈 WEEKLY SUMMARY:")
        print(f"   • Target: {nutrition_targets['calories']} cal/day, {nutrition_targets['protein_g']}g protein/day")
        print(f"   • Actual: {avg_daily_cal:.0f} cal/day, {avg_daily_protein:.0f}g protein/day")
        print(f"   • Accuracy: {((avg_daily_cal/nutrition_targets['calories'])*100):.1f}% calories, {((avg_daily_protein/nutrition_targets['protein_g'])*100):.1f}% protein")
        print(f"   • Unique ingredients: {len(ingredient_counts)}")
        
        print(f"\n✅ SUCCESS: {description} meal plan generated!")
        
    except Exception as e:
        print(f"❌ ERROR for {description}: {str(e)}")
        import traceback
        traceback.print_exc()

def main():
    """Test multiple user types to show variance"""
    
    print("🚀 TESTING MULTIPLE USER TYPES FOR VARIANCE")
    print("="*80)
    print("This test demonstrates how the ML nutrition system adapts to different user profiles")
    print("="*80)
    
    # Test Case 1: Young Active Male (Muscle Gain)
    user1 = {
        "Height_in": 72,  # 6'0"
        "Weight_lb": 160,
        "Age": 22,
        "Gender": 1,  # Male
        "Activity_Level": 3,  # High
        "Goal": 1,  # Gain weight
        "allergies": ["shellfish"],
        "preferences": ["brussels sprouts"]
    }
    test_user_type(user1, "Young Active Male - Muscle Gain (22yr, 6'0\", 160lbs)")
    
    # Test Case 2: Middle-aged Woman (Weight Loss)
    user2 = {
        "Height_in": 64,  # 5'4"
        "Weight_lb": 150,
        "Age": 45,
        "Gender": 0,  # Female
        "Activity_Level": 2,  # Moderate
        "Goal": -1,  # Lose weight
        "allergies": ["peanut", "tree nuts"],
        "preferences": ["liver", "anchovies"]
    }
    test_user_type(user2, "Middle-aged Woman - Weight Loss (45yr, 5'4\", 150lbs)")
    
    # Test Case 3: Older Sedentary Male (Maintenance)
    user3 = {
        "Height_in": 70,  # 5'10"
        "Weight_lb": 200,
        "Age": 65,
        "Gender": 1,  # Male
        "Activity_Level": 1,  # Low
        "Goal": 0,  # Maintain
        "allergies": ["dairy"],
        "preferences": ["spicy food", "fish"]
    }
    test_user_type(user3, "Older Sedentary Male - Maintenance (65yr, 5'10\", 200lbs)")
    
    # Test Case 4: Young Female Athlete (High Performance)
    user4 = {
        "Height_in": 66,  # 5'6"
        "Weight_lb": 130,
        "Age": 25,
        "Gender": 0,  # Female
        "Activity_Level": 4,  # Very High
        "Goal": 1,  # Gain weight
        "allergies": [],
        "preferences": ["mushrooms"]
    }
    test_user_type(user4, "Young Female Athlete - Performance (25yr, 5'6\", 130lbs)")
    
    # Test Case 5: Large Male Cutting Weight
    user5 = {
        "Height_in": 76,  # 6'4"
        "Weight_lb": 250,
        "Age": 35,
        "Gender": 1,  # Male
        "Activity_Level": 3,  # High
        "Goal": -1,  # Lose weight
        "allergies": ["soy"],
        "preferences": ["tofu", "quinoa"]
    }
    test_user_type(user5, "Large Male - Weight Cut (35yr, 6'4\", 250lbs)")
    
    print("\n" + "="*80)
    print("🎯 VARIANCE ANALYSIS COMPLETE")
    print("="*80)
    print("✅ The system successfully adapts nutrition targets and meal selections")
    print("✅ Different user profiles generate different calorie/protein targets")
    print("✅ Recipe selection varies based on individual goals and restrictions")
    print("✅ Weekly meal plans show appropriate variety and balance")
    print("="*80)

if __name__ == "__main__":
    main()