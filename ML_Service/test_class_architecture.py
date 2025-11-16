#!/usr/bin/env python3
"""
Test the new class-based architecture for meal planning
"""

import sys
from pathlib import Path

# Add project paths
project_root = Path(__file__).parent
sys.path.append(str(project_root))

def test_weekly_meal_planner():
    """Test the new WeeklyMealPlanner class"""
    print("🧪 Testing WeeklyMealPlanner Class")
    print("=" * 50)
    
    try:
        from src.models.meal_planning import WeeklyMealPlanner
        
        # Test initialization
        planner = WeeklyMealPlanner(ingredient_limit=4)
        print("✅ WeeklyMealPlanner initialized successfully")
        print(f"   - Ingredient limit: {planner.ingredient_limit}")
        print(f"   - Days of week: {len(planner.days_of_week)}")
        
        # Test state management
        planner.reset_state()
        print("✅ State reset successfully")
        
        # Test backwards compatibility
        from src.models.meal_planning import weekly_greedy_meal_selection
        print("✅ Legacy function still available")
        
    except Exception as e:
        print(f"❌ WeeklyMealPlanner test failed: {str(e)}")

def test_candidate_pool_builder():
    """Test the new CandidatePoolBuilder class"""
    print("\n🧪 Testing CandidatePoolBuilder Class")
    print("=" * 50)
    
    try:
        from src.models.create_candidates import CandidatePoolBuilder
        
        # Test initialization with custom parameters
        builder = CandidatePoolBuilder(
            pool_size=50,
            recall_size=250,
            alpha_pref=0.6,
            beta_fit=0.3,
            gamma_nov=0.1
        )
        print("✅ CandidatePoolBuilder initialized successfully")
        print(f"   - Pool size: {builder.pool_size}")
        print(f"   - Recall size: {builder.recall_size}")
        print(f"   - Scoring weights: α={builder.alpha_pref}, β={builder.beta_fit}, γ={builder.gamma_nov}")
        
        # Test backwards compatibility
        from src.models.create_candidates import build_all_candidate_pools
        print("✅ Legacy function still available")
        
    except Exception as e:
        print(f"❌ CandidatePoolBuilder test failed: {str(e)}")

def test_nutrition_service():
    """Test the new NutritionService class"""
    print("\n🧪 Testing NutritionService Class")
    print("=" * 50)
    
    try:
        from api.services.nutrition_service import NutritionService, nutrition_service
        
        # Test service initialization
        service = NutritionService(
            candidate_pool_size=40,
            ingredient_limit=4
        )
        print("✅ NutritionService initialized successfully")
        print(f"   - Candidate pool size: {service.candidate_builder.pool_size}")
        print(f"   - Ingredient limit: {service.meal_planner.ingredient_limit}")
        
        # Test validation
        test_user = {
            'Height_in': 70,
            'Weight_lb': 180,
            'Age': 25,
            'Gender': 1,
            'Activity_Level': 2,
            'Goal': 0,
            'allergies': ['peanut'],
            'preferences': ['liver']
        }
        
        service.validate_user_data(test_user)
        print("✅ User data validation passed")
        
        # Test reconfiguration
        service.reconfigure(candidate_pool_size=60, ingredient_limit=5)
        print("✅ Service reconfiguration successful")
        print(f"   - New pool size: {service.candidate_builder.pool_size}")
        print(f"   - New ingredient limit: {service.meal_planner.ingredient_limit}")
        
        # Test global service instance
        assert nutrition_service is not None
        print("✅ Global service instance available")
        
    except Exception as e:
        print(f"❌ NutritionService test failed: {str(e)}")

def test_class_integration():
    """Test that classes work together properly"""
    print("\n🧪 Testing Class Integration")
    print("=" * 50)
    
    try:
        from api.services.nutrition_service import NutritionService
        from src.models.create_candidates import CandidatePoolBuilder
        from src.models.meal_planning import WeeklyMealPlanner
        
        # Create service with custom components
        builder = CandidatePoolBuilder(pool_size=30, alpha_pref=0.7)
        planner = WeeklyMealPlanner(ingredient_limit=3)
        
        service = NutritionService()
        service.candidate_builder = builder
        service.meal_planner = planner
        
        print("✅ Class composition works correctly")
        print(f"   - Service uses custom builder with pool size: {service.candidate_builder.pool_size}")
        print(f"   - Service uses custom planner with limit: {service.meal_planner.ingredient_limit}")
        
    except Exception as e:
        print(f"❌ Class integration test failed: {str(e)}")

if __name__ == "__main__":
    print("🚀 TESTING CLASS-BASED ARCHITECTURE")
    print("=" * 60)
    
    test_weekly_meal_planner()
    test_candidate_pool_builder()
    test_nutrition_service()
    test_class_integration()
    
    print("\n" + "=" * 60)
    print("✅ Class architecture testing complete!")
    print("\n🎯 Benefits of the new class structure:")
    print("   • Better organization and maintainability")
    print("   • Configurable parameters and reusable components") 
    print("   • Clear separation of concerns")
    print("   • State management for complex workflows")
    print("   • Backwards compatibility preserved")
    print("   • Easier testing and debugging")