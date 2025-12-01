import pandas as pd
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent.parent))
from src.models.meal_selector import GetMeals


class WeeklyMealPlanner:
    """
    Manages weekly meal planning with ingredient tracking and variety control.
    
    Handles:
    - Daily meal selection with allergen filtering
    - Weekly ingredient tracking and usage limits
    - Recipe variety enforcement across days
    - State management for meal planners
    """
    
    def __init__(self, 
                 ingredient_limit: int = 4,
                 days_of_week: List[str] = None):

        self.ingredient_limit = ingredient_limit
        self.days_of_week = days_of_week or ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        # Track state across the week
        self.ingredient_counts = {}
        self.global_meal_planner = None
        self.week_plan = {}
        
    def _filter_candidate_data(self, data: Dict[str, pd.DataFrame], filter_terms: List[str]) -> Dict[str, pd.DataFrame]:

        if not filter_terms:
            return data
            
        return {
            'breakfast': self._filter_foods(data['breakfast'], filter_terms),
            'lunch': self._filter_foods(data['lunch'], filter_terms),
            'dinner': self._filter_foods(data['dinner'], filter_terms),
            'snack': self._filter_foods(data['snack'], filter_terms)  # Use 'snack' to match config
        }
    
    def _filter_foods(self, df: pd.DataFrame, filters: List[str]) -> pd.DataFrame:

        if not filters:
            return df
        
        # Create single regex pattern for all allergens
        filters_pattern = '|'.join(filters)
        
        # Check if this is a recipe DataFrame (has 'ingredients' column) or staples DataFrame (has 'food_name' column)
        if 'ingredients' in df.columns:
            # Recipe DataFrame - filter by ingredients
            return df[~df['ingredients'].str.contains(filters_pattern, case=False, na=False, regex=True)]
        elif 'food_name' in df.columns:
            # Staples DataFrame - filter by food name
            return df[~df['food_name'].str.contains(filters_pattern, case=False, na=False, regex=True)]
        else:
            # Unknown structure, return unchanged
            return df
    
    def _extract_ingredients(self, meal_plan: Dict[str, Any]) -> List[str]:

        ingredients = []
        
        meals = meal_plan.get('meals', {})
        
        for meal_type in ['breakfast', 'lunch', 'dinner', 'snacks']:
            meal_data = meals.get(meal_type, {})
            recipe_data = meal_data.get('recipe', {})
            meal_ingredients = recipe_data.get('ingredients', [])
            
            if meal_ingredients and not isinstance(meal_ingredients, float):
                # Handle both string and list ingredients
                if isinstance(meal_ingredients, str):
                    # Parse ingredients string that looks like "['ingredient1', 'ingredient2', ...]"
                    # Remove brackets and quotes, then split
                    cleaned = meal_ingredients.strip("[]").replace("'", "").replace('"', '')
                    ingredients.extend([ing.strip() for ing in cleaned.split(',') if ing.strip()])
                elif isinstance(meal_ingredients, list):
                    ingredients.extend(meal_ingredients)
                # Skip any other data types (float, int, etc.)
        return ingredients
    
    def _get_overused_ingredients(self) -> List[str]:

        return [
            ingredient for ingredient, count in self.ingredient_counts.items() 
            if count >= self.ingredient_limit
        ]
    
    def _update_ingredient_counts(self, ingredients: List[str]):

        for ingredient in ingredients:
            if ingredient in self.ingredient_counts:
                self.ingredient_counts[ingredient] += 1
            else:
                self.ingredient_counts[ingredient] = 1
    
    # single day plans
    def plan_daily_meals(self, user: Dict[str, Any], candidate_data: Dict[str, pd.DataFrame],
                        overused_ingredients: List[str] = None) -> Tuple[Dict[str, Any], List[str]]:

        # Combine allergens and overused ingredients for filtering
        allergies = user.get('allergies', [])
        filter_out = allergies + (overused_ingredients or [])
        
        # Filter candidate data
        filtered_data = self._filter_candidate_data(candidate_data, filter_out)
        
        # Create or update meal planner
        if self.global_meal_planner is None:
            self.global_meal_planner = GetMeals(
                breakfast_df=filtered_data['breakfast'],
                lunch_df=filtered_data['lunch'],
                dinner_df=filtered_data['dinner'],
                snacks_df=filtered_data['snack'],
            )
        else:
            # Update existing planner with filtered data to maintain state
            self.global_meal_planner.breakfast_df = filtered_data['breakfast']
            self.global_meal_planner.lunch_df = filtered_data['lunch']
            self.global_meal_planner.dinner_df = filtered_data['dinner']
            self.global_meal_planner.snacks_df = filtered_data['snack']
        
        # Generate meal plan
        meal_plan = self.global_meal_planner.create_meal_plan(user)
        ingredient_list = self._extract_ingredients(meal_plan)
        
        return meal_plan, ingredient_list
    
    def plan_weekly_meals(self, user: Dict[str, Any], candidate_data: Dict[str, pd.DataFrame],
                         initial_ingredient_counts: Dict[str, int] = None) -> Tuple[Dict[str, Dict], Dict[str, int]]:
        
        # Initialize or reset state
        self.ingredient_counts = initial_ingredient_counts.copy() if initial_ingredient_counts else {}
        self.week_plan = {}
        self.global_meal_planner = None
        
        for day in self.days_of_week:
            print(f"\n=== Planning meals for {day} ===")
            
            # Get currently overused ingredients
            overused = self._get_overused_ingredients()
            if overused:
                print(f"Overused ingredients (≥{self.ingredient_limit} uses): {overused}")
            
            # Plan daily meals
            daily_plan, todays_ingredients = self.plan_daily_meals(
                user, candidate_data, overused
            )
            
            # Update ingredient tracking
            self._update_ingredient_counts(todays_ingredients)
            
            # Store the day's plan
            self.week_plan[day] = daily_plan
            
            # Log progress
            print(f"{day} ingredients: {todays_ingredients}")
            
        return self.week_plan, self.ingredient_counts
    
    def reset_state(self):
        self.ingredient_counts = {}
        self.global_meal_planner = None
        self.week_plan = {}