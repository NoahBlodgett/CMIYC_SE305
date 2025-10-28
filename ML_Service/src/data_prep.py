import pandas as pd
import os
import re
from sklearn.model_selection import train_test_split
from config import *

def make_splits():
    
    file = os.path.join(DATA_DIR, RAW_FILE)

    print("loading csvs")
    df = pd.read_csv(file)

    print(f"Loaded {len(df)} items")
    print(f"Original columns: {len(df.columns)}")

    X = df[FEATURES]
    Y = df[TARGET]

    print(X.head())
    print(Y.head())

    stratify = df[STRATIFY_COL]

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        Y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=stratify)
    # Check results
    print("Train shape:", X_train.shape, y_train.shape)
    print("Test shape:", X_test.shape, y_test.shape)
    print("\nTrain mean calories:", round(y_train.mean(), 1))
    print("Test mean calories:", round(y_test.mean(), 1))
    print("\nGoal distribution in train:")
    print(X_train["Goal"].value_counts(normalize=True).round(3))
    print("\nGoal distribution in test:")
    print(X_test["Goal"].value_counts(normalize=True).round(3))
    
    # Combine features and target back together for saving
    train_df = X_train.copy()
    train_df[TARGET] = y_train
    
    test_df = X_test.copy()
    test_df[TARGET] = y_test
    
    # Save to CSV files
    train_output_path = os.path.join(DATA_DIR, "nutrition_train.csv")
    test_output_path = os.path.join(DATA_DIR, "nutrition_test.csv")
    
    train_df.to_csv(train_output_path, index=False)
    test_df.to_csv(test_output_path, index=False)
    
    print(f"\nSaved training data to: {train_output_path}")
    print(f"Saved test data to: {test_output_path}")
    print(f"Training set: {len(train_df)} samples")
    print(f"Test set: {len(test_df)} samples")


if __name__ == "__main__":
    make_splits()