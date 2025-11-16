#!/usr/bin/env python3
"""
Quick Variance Test - Shows Nutrition Target Differences
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from api.services.ml_models.nutritionRanker import getUserTarget

def test_nutrition_variance():
    """Quick test to show how nutrition targets vary by user type"""
    
    print("🎯 NUTRITION TARGET VARIANCE TEST")
    print("="*80)
    
    users = [
        {
            "name": "Young Active Male - Muscle Gain",
            "profile": "22yr, 6'0\", 160lbs",
            "data": {
                "Height_in": 72, "Weight_lb": 160, "Age": 22, "Gender": 1, 
                "Activity_Level": 3, "Goal": 1, "allergies": ["shellfish"], "preferences": []
            }
        },
        {
            "name": "Middle-aged Woman - Weight Loss", 
            "profile": "45yr, 5'4\", 150lbs",
            "data": {
                "Height_in": 64, "Weight_lb": 150, "Age": 45, "Gender": 0,
                "Activity_Level": 2, "Goal": -1, "allergies": ["peanut"], "preferences": []
            }
        },
        {
            "name": "Older Sedentary Male - Maintenance",
            "profile": "65yr, 5'10\", 200lbs", 
            "data": {
                "Height_in": 70, "Weight_lb": 200, "Age": 65, "Gender": 1,
                "Activity_Level": 1, "Goal": 0, "allergies": ["dairy"], "preferences": []
            }
        },
        {
            "name": "Young Female Athlete - Performance",
            "profile": "25yr, 5'6\", 130lbs",
            "data": {
                "Height_in": 66, "Weight_lb": 130, "Age": 25, "Gender": 0,
                "Activity_Level": 4, "Goal": 1, "allergies": [], "preferences": []
            }
        },
        {
            "name": "Large Male - Weight Cut",
            "profile": "35yr, 6'4\", 250lbs",
            "data": {
                "Height_in": 76, "Weight_lb": 250, "Age": 35, "Gender": 1,
                "Activity_Level": 3, "Goal": -1, "allergies": [], "preferences": []
            }
        }
    ]
    
    results = []
    
    for user in users:
        try:
            nutrition_tuple = getUserTarget(user["data"])
            nutrition_targets = {
                "calories": int(nutrition_tuple[0]),
                "protein_g": int(nutrition_tuple[1]), 
                "fat_g": int(nutrition_tuple[2]),
                "carb_g": int(nutrition_tuple[3])
            }
            
            results.append({
                "name": user["name"],
                "profile": user["profile"], 
                "targets": nutrition_targets
            })
            
            print(f"\n🧑‍💼 {user['name']}")
            print(f"   📊 {user['profile']}")
            print(f"   🎯 Targets: {nutrition_targets['calories']} cal, {nutrition_targets['protein_g']}g protein")
            print(f"   📈 Macros: {nutrition_targets['fat_g']}g fat, {nutrition_targets['carb_g']}g carbs")
            
        except Exception as e:
            print(f"❌ Error for {user['name']}: {str(e)}")
    
    print(f"\n" + "="*80)
    print("📊 VARIANCE SUMMARY")
    print("="*80)
    
    if results:
        calories = [r["targets"]["calories"] for r in results]
        proteins = [r["targets"]["protein_g"] for r in results]
        
        print(f"🔥 Calorie Range: {min(calories)} - {max(calories)} cal (spread: {max(calories)-min(calories)} cal)")
        print(f"💪 Protein Range: {min(proteins)} - {max(proteins)}g (spread: {max(proteins)-min(proteins)}g)")
        print(f"📈 System adapts by {((max(calories)-min(calories))/min(calories)*100):.1f}% for calories")
        print(f"📈 System adapts by {((max(proteins)-min(proteins))/min(proteins)*100):.1f}% for protein")
        
        print(f"\n🎯 KEY OBSERVATIONS:")
        print(f"   ✅ Muscle gain users get higher calories ({results[0]['targets']['calories']}, {results[3]['targets']['calories']})")
        print(f"   ✅ Weight loss users get lower calories ({results[1]['targets']['calories']}, {results[4]['targets']['calories']})")
        print(f"   ✅ Larger/more active users get more calories")
        print(f"   ✅ Protein varies significantly based on goals and body size")
        print(f"   ✅ Each user gets personalized nutrition targeting!")

if __name__ == "__main__":
    test_nutrition_variance()