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
    pass

