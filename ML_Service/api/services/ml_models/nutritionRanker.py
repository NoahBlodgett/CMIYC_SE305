from joblib import load
import pandas as pd

def getUserTarget(user):
    model = load("artifacts/models/model.joblib")

    user_X = pd.DataFrame[user]

    pred = model.predict(user_X)

    print(pred)
