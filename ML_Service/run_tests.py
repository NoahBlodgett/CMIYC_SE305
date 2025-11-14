#!/usr/bin/env python3
"""
Test runner for meal planning functionality
"""
import os
import sys
from pathlib import Path

# Change to ML_Service root directory
ml_service_root = Path(__file__).parent
os.chdir(ml_service_root)

# Run the tests
sys.path.append(str(ml_service_root))

from tests.test_meal_planning import *

if __name__ == "__main__":
    print("Running meal planning tests...")
    test_weekly_meal_planning()
    print("All tests passed!")