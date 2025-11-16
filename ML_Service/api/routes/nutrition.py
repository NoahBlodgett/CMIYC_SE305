from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parents[2]))

from api.services.nutrition_service import nutrition_service

router = APIRouter(prefix="/nutrition", tags=["nutrition"])

class UserData(BaseModel):
    """User data required for nutrition calculations"""
    Height_in: float
    Weight_lb: float
    Age: int
    Gender: int  # 0 = female, 1 = male
    Activity_Level: float  # 0-4 scale
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
    """
    Generate a complete weekly meal plan with nutrition targeting.
    
    Args:
        user: User profile data including demographics, goals, allergies, and preferences
        
    Returns:
        Complete meal plan with nutrition targets, weekly schedule, and statistics
    """
    try:
        # Convert Pydantic model to dict for the service
        user_dict = user.dict()
        
        # Generate complete meal plan using the service
        result = nutrition_service.generate_complete_meal_plan(user_dict)
        
        return result
    
    except ValueError as e:
        # Client errors (bad input data)
        raise HTTPException(status_code=400, detail=f"Invalid user data: {str(e)}")
    except FileNotFoundError as e:
        # Server errors (missing files)
        raise HTTPException(status_code=500, detail=f"Data file not found: {str(e)}")
    except RuntimeError as e:
        # Server errors (processing failures)
        raise HTTPException(status_code=500, detail=f"Processing error: {str(e)}")
    except Exception as e:
        # Catch-all for unexpected errors
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@router.get("/health")
async def health_check():
    """Health check endpoint for the nutrition service"""
    return {"status": "Nutrition service is running"}

@router.get("/config")
async def get_config():
    """Get current service configuration"""
    return {
        "candidate_pool_size": nutrition_service.candidate_builder.pool_size,
        "ingredient_limit": nutrition_service.meal_planner.ingredient_limit,
        "candidate_recall_size": nutrition_service.candidate_builder.recall_size
    }

@router.post("/config")
async def update_config(
    candidate_pool_size: int = None,
    ingredient_limit: int = None,
    candidate_recall_size: int = None
):
    """Update service configuration"""
    try:
        nutrition_service.reconfigure(
            candidate_pool_size=candidate_pool_size,
            ingredient_limit=ingredient_limit,
            candidate_recall_size=candidate_recall_size
        )
        return {"message": "Configuration updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid configuration: {str(e)}")

