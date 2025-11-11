import pandas as pd
import sys
from pathlib import Path
from typing import Dict, Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))
from api.services.ml_models.nutritionRanker import getUserTarget

class GetMeals:
    def __init__(self, breakfast_df=None, lunch_df=None, dinner_df=None, snacks_df=None, staples_df=None):
        # Set up data directory
        script_dir = Path(__file__).parent
        self.data_dir = script_dir.parent / "data" / "foods" / "by_meal_type"
        
        # Use provided DataFrames or load default ones
        if breakfast_df is not None and lunch_df is not None and dinner_df is not None and snacks_df is not None:
            # Use pre-filtered DataFrames
            self.breakfast_df = breakfast_df
            self.lunch_df = lunch_df
            self.dinner_df = dinner_df
            self.snacks_df = snacks_df
            
            # Handle staples DataFrame
            if staples_df is not None:
                self.filtered_staples = self.filterSnacks(staples_df)
            else:
                # Try to load staples from default location
                staples_path = self.data_dir / "staples.csv"
                if staples_path.exists():
                    staples_df = pd.read_csv(staples_path)
                    self.filtered_staples = self.filterSnacks(staples_df)
                else:
                    print("staples.csv not found")
                    self.filtered_staples = pd.DataFrame()
                
            print("Using provided pre-filtered DataFrames")
        else:
            # Load default DataFrames
            self.load_meal_dataframes()
        
        # Meal splits
        self.splits = {
            'breakfast': 0.25,
            'lunch': 0.35, 
            'dinner': 0.35,
            'snacks': 0.05
        }
    
    def load_meal_dataframes(self):
        """Load all meal DataFrames once during initialization (fallback method)."""
        try:
            self.breakfast_df = pd.read_csv(self.data_dir / "breakfast_recipes.csv")
            self.lunch_df = pd.read_csv(self.data_dir / "lunch_recipes.csv")
            self.dinner_df = pd.read_csv(self.data_dir / "dinner_recipes.csv")
            self.snacks_df = pd.read_csv(self.data_dir / "snacks_recipes.csv")
            
            # Load and filter staples for snacks
            staples_path = self.data_dir.parent / "staples.csv"
            if staples_path.exists():
                staples_df = pd.read_csv(staples_path)
                self.filtered_staples = self.filterSnacks(staples_df)
            else:
                print("staples.csv not found")
                self.filtered_staples = pd.DataFrame()
                
            print("Loaded default meal DataFrames")
        except Exception as e:
            print(f"Error loading meal data: {e}")
    
    def create_meal_plan(self, user_data: Dict) -> Dict:
        """Create complete meal plan from user data."""
        # Get targets from ML model
        nutrition_targets = getUserTarget(user_data)
        
        # Calculate meal targets
        meal_targets = {}
        for meal, split in self.splits.items():
            meal_targets[meal] = {
                'calories': int(nutrition_targets['calories'] * split),
                'protein_g': int(nutrition_targets['protein_g'] * split),
                'carbs_g': int(nutrition_targets['carb_g'] * split),
                'fat_g': int(nutrition_targets['fat_g'] * split)
            }
        
        # Get main meals first
        meals = {
            'breakfast': self.get_meal(self.breakfast_df, 'breakfast', meal_targets['breakfast']),
            'lunch': self.get_meal(self.lunch_df, 'lunch', meal_targets['lunch']),
            'dinner': self.get_meal(self.dinner_df, 'dinner', meal_targets['dinner']),
        }
        
        # Calculate totals from main meals
        main_meal_totals = {
            'calories': sum(meal['recipe']['calories'] for meal in meals.values()),
            'protein_g': sum(meal['recipe']['protein_g'] for meal in meals.values()),
            'carbs_g': sum(meal['recipe']['carbs_g'] for meal in meals.values()),
            'fat_g': sum(meal['recipe']['fat_g'] for meal in meals.values())
        }
        
        # Check if we need snacks to fill the gap
        calorie_deficit = nutrition_targets['calories'] - main_meal_totals['calories']
        
        if calorie_deficit > 50:  # Only add snacks if significant deficit
            # Use the FULL deficit - no cap
            snack_targets = {
                'calories': calorie_deficit,  # Use full deficit amount
                'protein_g': max(meal_targets['snacks']['protein_g'], (nutrition_targets['protein_g'] - main_meal_totals['protein_g'])),
                'carbs_g': meal_targets['snacks']['carbs_g'],
                'fat_g': meal_targets['snacks']['fat_g']
            }
            
            meals['snacks'] = self.get_Snack(snack_targets)
            print(f"Added snacks to fill {calorie_deficit} calorie gap")
        else:
            print(f"No snacks needed - deficit only {calorie_deficit} calories")
        
        # Recalculate final totals including snacks
        final_totals = {
            'calories': sum(meal['recipe']['calories'] for meal in meals.values()),
            'protein_g': sum(meal['recipe']['protein_g'] for meal in meals.values()),
            'carbs_g': sum(meal['recipe']['carbs_g'] for meal in meals.values()),
            'fat_g': sum(meal['recipe']['fat_g'] for meal in meals.values())
        }
        
        return {
            'nutrition_targets': nutrition_targets,
            'meals': meals,
            'total_nutrition': final_totals
        }
    
    def get_meal(self, meal_df: Optional[pd.DataFrame], meal_type: str, targets: Dict) -> Dict:
        #meal_df = pd.read_csv(self.data_dir / f"{meal_type}_recipes.csv")
        
        target_calories = targets['calories']
        target_protein = targets['protein_g']
        
        # Filter by calorie range (10% tolerance)
        tolerance = target_calories * 0.10
        min_calories = target_calories - tolerance
        max_calories = target_calories + tolerance
        
        candidates = meal_df[
            (meal_df['calories'] >= min_calories) & 
            (meal_df['calories'] <= max_calories)
        ].copy()
        
        # Fallback if no candidates
        if candidates.empty:
            candidates = meal_df.copy()
            candidates['calorie_diff'] = abs(candidates['calories'] - target_calories)
            candidates = candidates.nsmallest(50, 'calorie_diff')
        
        # Simple scoring: protein efficiency + protein target
        candidates['protein_efficiency'] = candidates['protein_g'] / candidates['calories']
        candidates['protein_target_score'] = 1 / (1 + abs(candidates['protein_g'] - target_protein))
        candidates['meal_score'] = (candidates['protein_efficiency'] * 0.7) + (candidates['protein_target_score'] * 0.3)
        
        # Select best option
        selected = candidates.loc[candidates['meal_score'].idxmax()]
        
        print(f"{meal_type.title()}: {selected['name']} ({selected['calories']} cal, {selected['protein_g']:.1f}g protein)")
        
        return {
            'recipe': {
                'id': selected['id'],
                'name': selected['name'],
                'calories': selected['calories'],
                'protein_g': selected['protein_g'],
                'carbs_g': selected['carbs_g'],
                'fat_g': selected['fat_g'],
                'ingredients': selected.get('ingredients'),
                'steps': selected.get('steps')
            },
            'targets': targets,
            'meal_type': meal_type
        }
    
    def get_Snack(self, targets: Dict) -> Dict:
        meal_df = pd.read_csv(self.data_dir / "snacks_recipes.csv")
        foods_df = pd.read_csv(self.data_dir / "staples.csv")
        
        # Filter out supplements and problematic items
        foods_df_filtered = self.filterSnacks(foods_df)
        
        target_calories = targets['calories']
        target_protein = targets['protein_g']
        
        # Filter by calorie range
        tolerance = target_calories * 0.15  # Increase tolerance for snacks
        min_calories = target_calories - tolerance
        max_calories = target_calories + tolerance
        
        # Get candidates from recipes
        recipe_candidates = meal_df[
            (meal_df['calories'] >= min_calories) & 
            (meal_df['calories'] <= max_calories)
        ].copy()
        recipe_candidates['source'] = 'recipe'
        
        # Get candidates from filtered staples
        food_candidates = foods_df_filtered[
            (foods_df_filtered['calories'] >= min_calories) & 
            (foods_df_filtered['calories'] <= max_calories)
        ].copy()
        food_candidates['source'] = 'staple'
        
        # Combine candidates using concat instead of +=
        candidates_list = []
        if not recipe_candidates.empty:
            candidates_list.append(recipe_candidates)
        if not food_candidates.empty:
            candidates_list.append(food_candidates)
        
        if candidates_list:
            candidates = pd.concat(candidates_list, ignore_index=True)
        else:
            candidates = pd.DataFrame()
        
        # Fallback if no candidates
        if candidates.empty:
            # Try with just recipes
            candidates = meal_df.copy()
            candidates['calorie_diff'] = abs(candidates['calories'] - target_calories)
            candidates = candidates.nsmallest(50, 'calorie_diff')
            candidates['source'] = 'recipe'
        
        # Simple scoring
        candidates['protein_efficiency'] = candidates['protein_g'] / candidates['calories']
        candidates['protein_target_score'] = 1 / (1 + abs(candidates['protein_g'] - target_protein))
        candidates['meal_score'] = (candidates['protein_efficiency'] * 0.7) + (candidates['protein_target_score'] * 0.3)
        
        # Select best option
        selected = candidates.loc[candidates['meal_score'].idxmax()]
        
        source_info = f" [{selected['source']}]"
        print(f"Snacks: {selected['name']}{source_info} ({selected['calories']} cal, {selected['protein_g']:.1f}g protein)")
        
        return {
            'recipe': {
                'id': selected.get('id', 'unknown'),
                'name': selected['name'],
                'calories': selected['calories'],
                'protein_g': selected['protein_g'],
                'carbs_g': selected['carbs_g'],
                'fat_g': selected['fat_g'],
                'source': selected['source'],
                'ingredients': selected.get('ingredients'),  # Add this
                'steps': selected.get('steps')               # Add this
            },
            'targets': targets,
            'meal_type': 'snacks'
        }

    def filterSnacks(self, foods_df: pd.DataFrame) -> pd.DataFrame:
        """Filter staples DataFrame to remove supplements and inappropriate items."""
        
        # Create a copy and standardize the name column
        filtered_df = foods_df.copy()

        filtered_df['name'] = filtered_df['food_name']
        
        # Convert to lowercase for filtering
        filtered_df['name_lower'] = filtered_df['name'].str.lower().fillna('')
        
        exclude_keywords = [
            'supplement', 'powder', 'pill', 'tablet', 'capsule', 
            'vitamin', 'mineral', 'creatine', 'bcaa', 'whey',
            'protein powder', 'mass gainer', 'pre-workout',
            'oil', 'extract', 'syrup', 'herb'
        ]
        
        # Filter out items
        for keyword in exclude_keywords:
            filtered_df = filtered_df[~filtered_df['name_lower'].str.contains(keyword, na=False)]
        
        # Filter by reasonable nutrition ranges for snacks
        filtered_df = filtered_df[
            (filtered_df['calories'] >= 30) &      # Minimum meaningful calories
            (filtered_df['calories'] <= 500) &     # Maximum reasonable snack size
            (filtered_df['protein_g'] >= 0) &      # No negative protein
            (filtered_df['protein_g'] <= 100) &    # No crazy high protein (likely powder)
            (filtered_df['carbs_g'] >= 0) &        # No negative carbs
            (filtered_df['fat_g'] >= 0)            # No negative fat
        ]
        print(f"Filtered staples: {len(foods_df)} → {len(filtered_df)} items")
        
        return filtered_df.drop(['name_lower'], axis=1)
    
# Example usage
if __name__ == "__main__":
    user_data = {
        'Height_in': 70,
        'Weight_lb': 180,
        'Age': 25,
        'Gender': 1,
        'Activity_Level': 2,
        'Goal': 0
    }
    
    print("SIMPLE MEAL PLANNER")
    print("=" * 50)
    
    planner = GetMeals()
    meal_plan = planner.create_meal_plan(user_data)
    
    print(f"Total: {meal_plan['total_nutrition']['calories']} cal, {meal_plan['total_nutrition']['protein_g']:.1f}g protein")