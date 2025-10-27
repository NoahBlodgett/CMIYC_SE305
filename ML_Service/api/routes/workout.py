from fastapi import APIRouter, HTTPException

router = APIRouter(prefix='/workout', tags=['workout'])

@router.get("/feedback")
def get_feedback():
    return {"message": "Workout Feedback"}

@router.post('/generate')
def generate_workout(response):

    response = {
        "Split": "Push Pull Legs",
        "days": [
            {
                "day": 1,
                "blocks": [
                    {"exercise": "Bench Press", "sets": 4, "reps": 8},
                    {"exercise": "Tricep press down", "sets": 3, "reps": 12},
                ]
            },
            {
                "day": 2,
                "blocks": [
                    {"exercise": "Pull ups", "sets": 4, "reps": 10},
                    {"exercise": "lat pulldown", "sets": 3, "reps": 12},
                ]
            },
            {
                "day": 3,
                "blocks": [
                    {"exercise": "Squats", "sets": 4, "reps": 10},
                    {"exercise": "Quad extensions", "sets": 3, "reps": 12},
                ]
            }
        ]
    }

    return response
