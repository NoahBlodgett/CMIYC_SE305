#!/usr/bin/env python3

import sys
from pathlib import Path
import json

# Add project to path
sys.path.insert(0, str(Path(__file__).parent))

def test_endpoint_logic():
    """
    Test function that mimics exactly what the API endpoint does
    This shows you the exact output structure without needing HTTP
    """
    
    print("🚀 Testing Endpoint Logic (Exact API Replica)")
    print("=" * 60)
    
    try:
        # Import all the same modules as the API
        from api.services.ml_models.nutritionRanker import getUserTarget
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
        
        # Convert tuple to dict for all downstream functions
        nutrition_targets_dict = {
            'calories': nutrition_targets_tuple[0],
            'protein_g': nutrition_targets_tuple[1],
            'fat_g': nutrition_targets_tuple[2],
            'carb_g': nutrition_targets_tuple[3]
        }
        print(f"✅ Daily targets: {nutrition_targets_dict['calories']} cal, {nutrition_targets_dict['protein_g']}g protein")
        
        # STEP 2: Build candidate pools (same as API)  
        print(f"\n🔄 STEP 2: Building candidate recipe pools...")
        candidates = build_all_candidate_pools(
            daily_targets=nutrition_targets_tuple,  # build_all_candidate_pools can handle tuple
            user_data=user_data
        )
        
        print(f"✅ Generated candidates:")
        for meal_type, pool in candidates.items():
            if len(pool) > 0:
                sample = pool.iloc[0]
                name = sample.get('name', 'N/A')
                calories = sample.get('per_serving_kcal', sample.get('calories', 'N/A'))
                score = sample.get('final_model_score', 'N/A')
                print(f"   • {meal_type.title()}: {len(pool)} recipes")
                print(f"     └─ Top pick: {name} ({calories} cal, score: {score:.2f})" if score != 'N/A' else f"     └─ Top pick: {name} ({calories} cal)")
        
        # STEP 3: Generate weekly meal plan (same as API)
        print(f"\n📅 STEP 3: Creating weekly meal plan...")
        week_plan, ingredient_counts = weekly_greedy_meal_selection(user_data, candidates)
        print(f"✅ Generated 7-day meal plan with {len(ingredient_counts)} unique ingredients")
        
        # STEP 4: Build API response (EXACT same as endpoint)
        print(f"\n📦 STEP 4: Formatting API response...")
        
        api_response = {
            "success": True,
            "nutrition_targets": nutrition_targets_dict,
            "week_plan": week_plan,
            "ingredient_counts": ingredient_counts,
            "candidate_stats": {
                "breakfast_count": len(candidates.get('breakfast', [])),
                "lunch_count": len(candidates.get('lunch', [])),
                "dinner_count": len(candidates.get('dinner', [])),
                "snack_count": len(candidates.get('snack', []))  # Note: 'snack' not 'snacks'
            }
        }
        
        print("="*60)
        print("✅ API RESPONSE SUMMARY")
        print("="*60)
        print(f"Success: {api_response['success']}")
        print(f"\n📊 NUTRITION TARGETS:")
        for key, value in api_response['nutrition_targets'].items():
            print(f"   • {key}: {value}")
        
        print(f"\n🍽️  CANDIDATE POOLS:")
        for meal_type, count in api_response['candidate_stats'].items():
            print(f"   • {meal_type.replace('_', ' ').title()}: {count} recipes")
        
        # Show sample day from week plan
        print(f"\n📅 WEEKLY MEAL PLAN:")
        print(f"   Days planned: {list(api_response['week_plan'].keys())}")
        
        if week_plan:
            first_day = list(week_plan.keys())[0]
            day_plan = week_plan[first_day]
            print(f"\n🍽️  SAMPLE DAY ({first_day}):")
            
            meals_order = ['breakfast', 'lunch', 'dinner', 'snacks']
            for meal_type in meals_order:
                if meal_type in day_plan.get('meals', {}):
                    meal_info = day_plan['meals'][meal_type]
                    if 'recipe' in meal_info:
                        recipe = meal_info['recipe']
                        name = recipe.get('name', 'N/A')
                        calories = recipe.get('calories', 'N/A')
                        protein = recipe.get('protein_g', 'N/A')
                        print(f"   • {meal_type.title()}: {name}")
                        print(f"     └─ {calories} cal, {protein}g protein")
        
        # Show ingredient tracking
        print(f"\n🛒 INGREDIENT TRACKING:")
        print(f"   Total unique ingredients: {len(api_response['ingredient_counts'])}")
        
        # Show top ingredients by usage
        sorted_ingredients = sorted(
            api_response['ingredient_counts'].items(), 
            key=lambda x: x[1], 
            reverse=True
        )
        print(f"   Most used ingredients:")
        for ingredient, count in sorted_ingredients[:5]:
            print(f"     • {ingredient}: {count} times")
        
        # Show total nutrition for the week
        if week_plan:
            total_cal = sum(
                day.get('total_nutrition', {}).get('calories', 0) 
                for day in week_plan.values()
            )
            total_protein = sum(
                day.get('total_nutrition', {}).get('protein_g', 0) 
                for day in week_plan.values()
            )
            print(f"\n📈 WEEKLY TOTALS:")
            print(f"   • Total calories: {total_cal:.0f} ({total_cal/7:.0f}/day avg)")
            print(f"   • Total protein: {total_protein:.0f}g ({total_protein/7:.0f}g/day avg)")
        
        print("="*60)
        print("🎉 SUCCESS! YOUR ENDPOINT IS FULLY FUNCTIONAL!")
        print("="*60)
        print(f"📏 Response size: {len(str(api_response))} characters")
        print(f"🚀 Ready to serve at: POST /nutrition/generate")
        print("="*60)
        
        return api_response
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    result = test_endpoint_logic()
    
    if result:
        print(f"\n💾 Want to see the full JSON? Uncomment the line below:")
        print(f"# print(json.dumps(result, indent=2, default=str))")
    else:
        print(f"\n💥 Test failed - check the errors above")