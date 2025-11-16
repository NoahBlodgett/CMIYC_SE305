"""
Nutrition service for handling meal planning business logic.
Separates API concerns from business logic.
"""

from typing import Dict, List, Tuple, Any
import sys
import json
import numpy as np
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parents[2]))

from api.services.ml_models.nutritionRanker import getUserTarget
from src.models.create_candidates import CandidatePoolBuilder
from src.models.meal_planning import WeeklyMealPlanner


def sanitize_for_json(obj):
    """Recursively sanitize data structure for JSON serialization"""
    if isinstance(obj, dict):
        return {k: sanitize_for_json(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [sanitize_for_json(item) for item in obj]
    elif isinstance(obj, tuple):
        return [sanitize_for_json(item) for item in obj]
    elif isinstance(obj, (np.integer, np.int64, np.int32, np.int16, np.int8)):
        return int(obj)
    elif isinstance(obj, (np.floating, np.float64, np.float32, np.float16)):
        if np.isnan(obj) or np.isinf(obj):
            return None
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return sanitize_for_json(obj.tolist())
    elif isinstance(obj, (int, float)):
        if isinstance(obj, float) and (np.isnan(obj) or np.isinf(obj)):
            return None
        return obj
    elif hasattr(obj, 'item'):  # Handle pandas scalars
        return sanitize_for_json(obj.item())
    elif hasattr(obj, 'tolist'):  # Handle pandas Series/DataFrame
        return sanitize_for_json(obj.tolist())
    else:
        return obj


class NutritionService:
    """
    Service class for nutrition-related business logic.
    
    Handles:
    - Nutrition target calculation
    - Candidate pool generation
    - Weekly meal planning coordination
    - Error handling and validation
    """
    
    def __init__(self, 
                 candidate_pool_size: int = 40,
                 ingredient_limit: int = 4,
                 candidate_recall_size: int = 200):

        self.candidate_builder = CandidatePoolBuilder(
            pool_size=candidate_pool_size,
            recall_size=candidate_recall_size
        )
        
        self.meal_planner = WeeklyMealPlanner(
            ingredient_limit=ingredient_limit
        )
    
    def validate_user_data(self, user_data: Dict[str, Any]) -> None:
        required_fields = ['Height_in', 'Weight_lb', 'Age', 'Gender', 'Activity_Level', 'Goal']
        missing_fields = [f for f in required_fields if f not in user_data]
        
        if missing_fields:
            raise ValueError(f"Missing required fields: {missing_fields}")
        
        # Validate ranges
        if not (1 <= user_data['Height_in'] <= 120):
            raise ValueError("Height must be between 1 and 120 inches")
        if not (50 <= user_data['Weight_lb'] <= 1000):
            raise ValueError("Weight must be between 50 and 1000 pounds")
        if not (10 <= user_data['Age'] <= 120):
            raise ValueError("Age must be between 10 and 120 years")
        if user_data['Gender'] not in [0, 1]:
            raise ValueError("Gender must be 0 (female) or 1 (male)")
        if user_data['Activity_Level'] not in [0, 1, 2, 3, 4]:
            raise ValueError("Activity_Level must be 0-4")
        if user_data['Goal'] not in [-1, 0, 1]:
            raise ValueError("Goal must be -1 (lose), 0 (maintain), or 1 (gain)")
    
    def calculate_nutrition_targets(self, user_data: Dict[str, Any]) -> Dict[str, float]:
        self.validate_user_data(user_data)
        
        # Get nutrition targets from ML model (returns tuple)
        nutrition_targets_tuple = getUserTarget(user_data)
        
        # Convert tuple to dict for easier handling
        return {
            'calories': nutrition_targets_tuple[0],
            'protein_g': nutrition_targets_tuple[1],
            'fat_g': nutrition_targets_tuple[2],
            'carb_g': nutrition_targets_tuple[3]
        }
    
    def generate_candidate_pools(self, nutrition_targets: Dict[str, float], user_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            candidates = self.candidate_builder.build_pools(
                daily_targets=nutrition_targets,
                user_data=user_data
            )
            
            # Validate that we have candidates for each meal type
            empty_meals = [meal for meal, df in candidates.items() if df.empty]
            if empty_meals:
                print(f"Warning: No candidates available for: {empty_meals}")
            
            return candidates
            
        except Exception as e:
            raise ValueError(f"Failed to generate candidate pools: {str(e)}")
    
    def plan_weekly_meals(self, user_data: Dict[str, Any],
                         candidate_pools: Dict[str, Any]) -> Tuple[Dict[str, Dict], Dict[str, int]]:
        try:
            # Reset planner state for fresh planning
            self.meal_planner.reset_state()
            
            week_plan, ingredient_counts = self.meal_planner.plan_weekly_meals(
                user_data, candidate_pools
            )
            
            # Validate that we have plans for each day
            if not week_plan:
                raise ValueError("No meal plans generated")
            
            missing_days = [day for day in self.meal_planner.days_of_week if day not in week_plan]
            if missing_days:
                print(f"Warning: Missing meal plans for: {missing_days}")
            
            return week_plan, ingredient_counts
            
        except Exception as e:
            raise ValueError(f"Failed to plan weekly meals: {str(e)}")
    
    def generate_complete_meal_plan(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            # Calculate nutrition targets
            nutrition_targets = self.calculate_nutrition_targets(user_data)
            print(f"Calculated nutrition targets: {nutrition_targets}")
            
            # Generate candidate pools
            candidate_pools = self.generate_candidate_pools(nutrition_targets, user_data)
            print(f"Generated candidate pools for {len(candidate_pools)} meal types")
            
            # Plan weekly meals
            week_plan, ingredient_counts = self.plan_weekly_meals(user_data, candidate_pools)
            print(f"Planned meals for {len(week_plan)} days")
            
            return sanitize_for_json({
                "success": True,
                "nutrition_targets": nutrition_targets,
                "week_plan": week_plan,
                "ingredient_counts": ingredient_counts
            })
            
        except ValueError as ve:
            # Re-raise validation errors
            raise ve
        except Exception as e:
            raise RuntimeError(f"Unexpected error in meal plan generation: {str(e)}")

# Service instance for dependency injection
nutrition_service = NutritionService()