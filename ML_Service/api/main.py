from fastapi import FastAPI
from api.routes.nutrition import router as nutrition_router
from api.routes.workout import router as workout_router

app = FastAPI()

app.include_router(nutrition_router)
app.include_router(workout_router)

@app.get("/health")
def health():
    return {"OK": True}