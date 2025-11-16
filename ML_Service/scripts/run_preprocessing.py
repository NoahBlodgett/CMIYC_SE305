#!/usr/bin/env python3
"""
Convenience script to run data preprocessing from the ML_Service root directory
"""
import os
import sys
from pathlib import Path

# Change to the script's directory for relative path imports
script_dir = Path(__file__).parent
os.chdir(script_dir)

# Add src to Python path
sys.path.append(str(script_dir / "src"))

from src.data.preprocessing import clean_files_and_save

if __name__ == "__main__":
    print("Running data preprocessing...")
    df = clean_files_and_save()
    print(f"Preprocessing complete! Generated {len(df)} records")