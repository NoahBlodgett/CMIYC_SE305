from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import sys
from pathlib import Path
from api.services.ml_models.nutritionRanker import getUserTarget
from api.utils import filterFoods

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
        
        # Get nutrition targets from ML model
        nutrition_targets = getUserTarget(user_dict)
        
        # Filter foods based on allergies/preferences
        filtered_foods = filterFoods(user_dict, path="data/foods/staples.csv")
        
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

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "Nutrition service is running"}

