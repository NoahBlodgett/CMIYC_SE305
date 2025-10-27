from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/nutrition", tags=["nutrition"])

@router.get("/feedback")
def get_feedback():
    return {"message": "Nutrition Feedback"}

@router.post("/generate")
def generate_plan(response):

    response = {
        "Plan": "Balanced High-Protein",
        "meals": [
            {
                "meal": "Breakfast",
                "items": [
                    {"food": "Greek Yogurt", "grams": 200, "calories": 130, "protein": 23, "carbs": 7, "fats": 0},
                    {"food": "Oats", "grams": 50, "calories": 190, "protein": 6, "carbs": 33, "fats": 4},
                    {"food": "Banana", "grams": 120, "calories": 110, "protein": 1, "carbs": 27, "fats": 0}
                ]
            },
            {
                "meal": "Lunch",
                "items": [
                    {"food": "Grilled Chicken Breast", "grams": 150, "calories": 250, "protein": 45, "carbs": 0, "fats": 5},
                    {"food": "Cooked Rice", "grams": 200, "calories": 260, "protein": 5, "carbs": 56, "fats": 1},
                    {"food": "Olive Oil", "grams": 10, "calories": 90, "protein": 0, "carbs": 0, "fats": 10}
                ]
            },
            {
                "meal": "Dinner",
                "items": [
                    {"food": "Baked Salmon", "grams": 150, "calories": 280, "protein": 30, "carbs": 0, "fats": 17},
                    {"food": "Sweet Potato", "grams": 180, "calories": 160, "protein": 3, "carbs": 37, "fats": 0},
                    {"food": "Steamed Spinach", "grams": 75, "calories": 20, "protein": 2, "carbs": 3, "fats": 0}
                ]
            },
            {
                "meal": "Snack",
                "items": [
                    {"food": "Protein Bar", "grams": 60, "calories": 200, "protein": 20, "carbs": 20, "fats": 7}
                ]
            }
        ],
        "totals": {
            "calories": 2010,
            "protein": 135,
            "carbs": 180,
            "fats": 44
        }
    }

    return response

