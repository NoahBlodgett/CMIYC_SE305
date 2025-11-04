from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parents[2]))

from api.services.ml_models.nutritionRanker import getUserTarget
from api.utils import filterFoods

router = APIRouter(prefix="/api/nutrition", tags=["nutrition"])

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

@router.post("/calculate")
async def calculate_nutrition(user: UserData):
    """
    Calculate target calories, macros, and filter foods based on user profile
    
    Returns:
        - calories: Recommended daily calories
        - protein_g: Grams of protein
        - fat_g: Grams of fat
        - carb_g: Grams of carbohydrates
        - available_foods_count: Number of foods after filtering
        - foods_preview: Sample of available foods
    """
    try:
        # Convert Pydantic model to dict for ML functions
        user_dict = user.dict()
        
        # Get target calories and macros from ML model
        nutrition_targets = getUserTarget(user_dict)
        
        # Filter foods based on allergies/preferences
        filtered_foods = filterFoods(user_dict, food_data_path="data/foods/staples.csv")
        
        return {
            "nutrition_targets": nutrition_targets,
            "available_foods_count": len(filtered_foods),
            "foods_preview": filtered_foods.head(10).to_dict('records')
        }
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid user data: {str(e)}")
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=f"Data file not found: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating nutrition: {str(e)}")

@router.get("/test")
async def test_nutrition():
    """Test endpoint to verify nutrition service is working"""
    return {
        "status": "Nutrition service is running",
        "endpoints": {
            "POST /api/nutrition/calculate": "Calculate nutrition plan for user"
        }
    }

