#!/usr/bin/env python3
"""
Show Full Weekly Meal Plans for Two Different User Types
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from api.services.ml_models.nutritionRanker import getUserTarget

def test_original_user():
    """Test the original working example"""
    print("🚀 Testing Original User (Exact API Replica)")
    print("=" * 60)
    
    try:
        # Import all the same modules as the API
        from src.models.create_candidates import build_all_candidate_pools
        from src.models.meal_planning import weekly_greedy_meal_selection
        
        print("✅ All imports successful")
        
        # Create test user data (same as UserData Pydantic model)
        user_data = {
            "Height_in": 70,
            "Weight_lb": 180,
            "Age": 25,
            "Gender": 1,
            "Activity_Level": 2,
            "Goal": 0,
            "allergies": ["peannut"],
            "preferences": ["liver"]
        }
        
        print("🎯 USER DATA:")
        user_summary = f"   👤 {user_data['Age']}yr old, {user_data['Height_in']}\" tall, {user_data['Weight_lb']}lbs"
        goal_map = {-1: "lose weight", 0: "maintain", 1: "gain weight"}
        goal = goal_map.get(user_data['Goal'], 'unknown')
        user_summary += f", Goal: {goal}"
        if user_data.get('allergies'):
            user_summary += f"\n   🚫 Allergies: {', '.join(user_data['allergies'])}"
        if user_data.get('preferences'): 
            user_summary += f"\n   👎 Dislikes: {', '.join(user_data['preferences'])}"
        print(user_summary)
        
        # STEP 1: Get nutrition targets from ML model (same as API)
        print(f"\n📊 STEP 1: Calculating nutrition targets...")
        nutrition_targets_tuple = getUserTarget(user_data)
        nutrition_targets_dict = {
            "calories": int(nutrition_targets_tuple[0]),
            "protein_g": int(nutrition_targets_tuple[1]), 
            "fat_g": int(nutrition_targets_tuple[2]),
            "carb_g": int(nutrition_targets_tuple[3])
        }
        print(f"✅ Daily targets: {nutrition_targets_dict['calories']} cal, {nutrition_targets_dict['protein_g']}g protein")
        
        # STEP 2: Build candidate recipe pools (same as API)
        print(f"\n🔄 STEP 2: Building candidate recipe pools...")
        candidates = build_all_candidate_pools(nutrition_targets_dict, user_data)
        
        # Show candidate summary
        print(f"✅ Generated candidates:")
        for meal_type, recipes in candidates.items():
            if not recipes.empty:
                top_recipe = recipes.iloc[0]
                print(f"   • {meal_type.title()}: {len(recipes)} recipes")
                print(f"     └─ Top pick: {top_recipe.get('name', 'N/A')} ({top_recipe.get('calories', 'N/A'):.1f} cal)")
        
        # STEP 3: Generate weekly meal plan (same as API)
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
        print(f"   • Target: {nutrition_targets_dict['calories']} cal/day, {nutrition_targets_dict['protein_g']}g protein/day")
        print(f"   • Actual: {avg_daily_cal:.0f} cal/day, {avg_daily_protein:.0f}g protein/day")
        print(f"   • Accuracy: {((avg_daily_cal/nutrition_targets_dict['calories'])*100):.1f}% calories, {((avg_daily_protein/nutrition_targets_dict['protein_g'])*100):.1f}% protein")
        print(f"   • Unique ingredients: {len(ingredient_counts)}")
        
        return week_plan, nutrition_targets_dict
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return None, None

def main():
    """Test original user and show its meal plan"""
    print("🎯 FULL WEEKLY MEAL PLAN DEMONSTRATION")
    print("="*80)
    
    week_plan, targets = test_original_user()
    
    if week_plan:
        print(f"\n✅ SUCCESS! Full weekly meal plan generated!")
        print(f"📊 This demonstrates how the system creates personalized 7-day plans")
        print(f"🍽️  Each day has balanced meals that meet nutrition targets")
        print(f"📈 The system adapts meal selection based on user profile")
        print(f"🛒 Ingredient tracking prevents repetitive meals")
    else:
        print(f"❌ Failed to generate meal plan")
    
    print("="*80)

if __name__ == "__main__":
    main()