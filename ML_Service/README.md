# ML Service - Cache Me If You Can

A machine learning service for nutrition recommendation and meal planning.

## Project Structure

```
ML_Service/
├── README.md                    # This file
├── requirements.txt             # Python dependencies  
├── setup.py                     # Package setup
├── run_preprocessing.py         # Convenience script for data preprocessing
│
├── config/                      # Configuration files
│   └── config.py               # ML model and data configuration
│
├── data/                        # Data storage
│   ├── raw/                    # Original raw data
│   │   ├── by_meal_type/       # Meal categorized data
│   │   ├── nutrition_*.csv     # Nutrition training data
│   │   ├── exercises.csv       # Exercise data
│   │   └── *.csv               # Other raw datasets
│   ├── interim/                # Intermediate data (deprecated, use processed/)
│   ├── processed/              # Final processed data ready for ML
│   │   └── all_meals_clean.parquet
│   └── external/               # External datasets
│
├── src/                        # Source code
│   ├── __init__.py
│   ├── data/                   # Data processing modules
│   │   ├── __init__.py
│   │   ├── data_prep.py        # Data preparation utilities
│   │   ├── preprocessing.py    # Main data preprocessing (formerly buildClusters.py)
│   │   ├── separate_meal_types.py
│   │   ├── process_food_data.py
│   │   └── process_recipes.py
│   ├── features/               # Feature engineering
│   │   ├── __init__.py
│   │   └── features.py
│   ├── models/                 # ML models and algorithms
│   │   ├── __init__.py
│   │   ├── meal_selector.py    # Meal selection logic (formerly get_meals.py)
│   │   ├── meal_planning.py    # Meal planning algorithms (formerly greedy_meal.py)
│   │   └── train_nutrition_model.py  # Model training (formerly trainTargetCalsModel.py)
│   └── utils/                  # Utility functions
│       ├── __init__.py
│       └── filtering.py        # Food filtering utilities
│
├── scripts/                    # Standalone scripts (remaining scripts)
│
├── tests/                      # Test files
│   ├── __init__.py
│   └── test_meal_planning.py
│
├── notebooks/                  # Jupyter notebooks for analysis
│
├── api/                        # FastAPI application (unchanged structure)
│   ├── main.py
│   ├── utils.py
│   ├── routes/
│   └── services/
│
└── artifacts/                  # Model artifacts and reports
    ├── models/
    │   └── model.joblib
    └── reports/
        └── metrics.json
```

## Quick Start

### 1. Data Preprocessing

Run the data preprocessing pipeline:

```bash
# From ML_Service root directory
python run_preprocessing.py
```

This will:
- Process meal type data from `data/raw/by_meal_type/`
- Clean and filter the data
- Save processed data to `data/processed/all_meals_clean.parquet`

### 2. Import the modules

```python
# From the ML_Service directory
from src.data.preprocessing import clean_files_and_save
from src.models.meal_planning import weekly_greedy_meal_selection
from src.models.meal_selector import GetMeals
```

### 3. Train nutrition model

```bash
cd src/models
python train_nutrition_model.py
```

### 4. Run tests

```bash
cd tests
python test_meal_planning.py
```

### 5. Start API server

```bash
cd api
python -m uvicorn main:app --reload
```

## File Migration Summary

### Moved Files
- `scripts/buildClusters.py` → `src/data/preprocessing.py`
- `scripts/get_meals.py` → `src/models/meal_selector.py` 
- `scripts/greedy_meal.py` → `src/models/meal_planning.py`
- `scripts/trainTargetCalsModel.py` → `src/models/train_nutrition_model.py`
- `src/config.py` → `config/config.py`
- `test_meal_planning.py` → `tests/test_meal_planning.py`
- Raw data files → `data/raw/`
- Processed data → `data/processed/`

### Updated Import Paths
All import statements and file paths have been updated to work with the new structure:
- Relative paths adjusted for new directory levels
- Import statements updated for moved modules
- Data file paths updated to use new data organization

## Key Benefits of New Structure

1. **Clear Separation of Concerns**: Data processing, models, tests, and API are in separate directories
2. **Standard ML Project Layout**: Follows common machine learning project conventions
3. **Better Maintainability**: Related functionality is grouped together
4. **Cleaner Data Organization**: Raw, processed, and external data are separated
5. **Proper Package Structure**: With __init__.py files for clean imports
6. **Improved Testability**: Tests are in their own directory
7. **Configuration Management**: Configuration is centralized in config/

## Development Workflow

1. **Data Processing**: Use `src/data/` modules for data cleaning and preparation
2. **Feature Engineering**: Use `src/features/` for feature creation and selection  
3. **Model Development**: Use `src/models/` for model training and prediction logic
4. **Testing**: Add tests to `tests/` directory
5. **API Development**: API code remains in `api/` directory with updated import paths
6. **Configuration**: Update `config/config.py` for any configuration changes

## Dependencies

Install dependencies with:
```bash
pip install -r requirements.txt
```

Or install the package in development mode:
```bash
pip install -e .
```