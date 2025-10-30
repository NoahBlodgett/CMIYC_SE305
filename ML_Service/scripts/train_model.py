import os
import sys
import json
import pandas as pd
from pathlib import Path

# Ensure project root is on sys.path so `src` package can be imported when running from /scripts
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from src.config import TARGET, DATA_DIR

from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_absolute_error, r2_score


# Resolve DATA_DIR relative to project root when a relative path is provided.
from pathlib import Path as _Path
_data_dir = _Path(DATA_DIR)
if not _data_dir.is_absolute():
    # DATA_DIR in src.config is relative to the `src/` package (e.g. "../data").
    # Resolve it relative to ML_Service/src so we get ML_Service/data.
    src_dir = _Path(ROOT) / "src"
    _data_dir = (src_dir / _data_dir).resolve()

TRAIN_CSV = str(_data_dir / "nutrition_train.csv")
TEST_CSV = str(_data_dir / "nutrition_test.csv")

# Model artifacts saves the state of the model for use
ARTIFACT_DIR = "artifacts"
MODEL_DIR = os.path.join(ARTIFACT_DIR, "models")
REPORT_DIR = os.path.join(ARTIFACT_DIR, "reports")
MODEL_PATH = os.path.join(MODEL_DIR, "model.joblib")
METRICS_PATH = os.path.join(REPORT_DIR, "metrics.json")

# Save the data in a pandas data frame for training 
train_df = pd.read_csv(TRAIN_CSV)
test_df  = pd.read_csv(TEST_CSV)

X_train = train_df.drop(columns=[TARGET]) # remove the target column from features
Y_train = train_df[TARGET]
X_test  = test_df.drop(columns=[TARGET])
y_test  = test_df[TARGET]

# the piece that scales all the features
from src.features import build_preprocessor   
pre = build_preprocessor()

# build model pipeline
reg = Ridge(alpha=1.0, random_state=42) # ridge is just a linear reg model that has regularization to reduce over fitting
model = Pipeline([("prep", pre), ("reg", reg),])

# fit, Where it actually trains to find the coefficients for the model
model.fit(X_train, Y_train)

# evaluate
y_pred = model.predict(X_test)
mae = mean_absolute_error(y_test, y_pred)
r2  = r2_score(y_test, y_pred)
print(f"Ridge MAE: {mae:.1f}") # how many calories the model is off by
print(f"Ridge R2 : {r2:.3f}") # % to how well the model fits

# save artifacts
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(REPORT_DIR, exist_ok=True)

# save model
from joblib import dump
dump(model, MODEL_PATH)

# save metrics
with open(METRICS_PATH, "w") as f:
    json.dump({"mae": float(mae), "r2": float(r2)}, f, indent=2)

print(f"Saved model → {MODEL_PATH}")
print(f"Saved metrics → {METRICS_PATH}")