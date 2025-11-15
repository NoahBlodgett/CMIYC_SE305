import pandas as pd
import numpy as np

from sklearn.preprocessing import MinMaxScaler

DAILY_KCAL = None

Meal_limits = {
    'breakfast': {
        'min': .20,
        'max': .30,
    }
}