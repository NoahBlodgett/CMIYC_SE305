from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import sys
import pandas as pd
from pathlib import Path
from api.services.ml_models.nutritionRanker import getUserTarget
from api.utils import filterFoods
from src.models.create_candidates import build_all_candidate_pools
from src.models.meal_planning import weekly_greedy_meal_selection

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parents[2]))

router = APIRouter(prefix="/nutrition", tags=["nutrition"])

class UserData(BaseModel):
    """User data required for nutrition calculations"""
    Height_in: float
    Weight_lb: float
    Age: int
    Gender: int  # 0 = female, 1 = male
    Activity_Level: int  # 0-4 scale
    Goal: int  # -1 = lose, 0 = maintain, 1 = gain
    allergies: List[str] = []
    preferences: List[str] = []

    class Config:
        schema_extra = {
            "example": {
                "Height_in": 70,
                "Weight_lb": 180,
                "Age": 25,
                "Gender": 1,
                "Activity_Level": 2,
                "Goal": 0,
                "allergies": ["peanut", "shellfish"],
                "preferences": ["liver"]
            }
        }

@router.post("/generate")
async def generate(user: UserData):
    try:
        # Convert Pydantic model to dict
        user_dict = user.dict()
        
        # Get nutrition targets from ML model (returns tuple)
        nutrition_targets_tuple = getUserTarget(user_dict)
        
        # Convert tuple to dict for all downstream functions
        nutrition_targets_dict = {
            'calories': nutrition_targets_tuple[0],
            'protein_g': nutrition_targets_tuple[1],
            'fat_g': nutrition_targets_tuple[2],
            'carb_g': nutrition_targets_tuple[3]
        }
        
        # Pass user_dict instead of user object
        candidates = build_all_candidate_pools(
            daily_targets=nutrition_targets_tuple,  # build_all_candidate_pools can handle tuple
            user_data=user_dict  # Pass dict, not Pydantic object
        )

        week_plan, ingredient_counts = weekly_greedy_meal_selection(user_dict, candidates)

        # ADD RETURN STATEMENT
        return {
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
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid user data: {str(e)}")
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=f"Data file not found: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating nutrition: {str(e)}")

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "Nutrition service is running"}

