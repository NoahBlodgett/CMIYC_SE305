import pandas as pd
def filterFoods(user, path):
    """
    Filter foods based on user allergies and preferences
    
    Args:
        user: Dict with 'allergies' and 'preferences' keys
        path: Path to CSV with food data
        
    Returns:
        DataFrame with filtered foods
    """
    # Handle both dict and object
    if isinstance(user, dict):
        allergies = user.get('allergies', [])
        dislikes = user.get('preferences', [])
    else:
        allergies = getattr(user, 'allergies', [])
        dislikes = getattr(user, 'preferences', [])
    
    # Load food database
    foods_df = pd.read_csv(path)
    
    # Combine all terms to exclude
    exclude_terms = allergies + dislikes
    
    # If no exclusions, return all foods
    if not exclude_terms:
        return foods_df
    
    # Create regex pattern: "peanut|egg|liver|anchovy"
    pattern = '|'.join(exclude_terms)
    
    # Keep rows that DON'T contain any of these terms
    # ~ inverts so we get all rows that don't match
    filtered_df = foods_df[~foods_df['food_name'].str.contains(pattern, case=False, na=False)]
    
    return filtered_df.reset_index(drop=True)

def mealTargets(daily_targets: dict | tuple, splits: dict[str, float]) -> dict[str, dict[str, float]]:
    """
    Split daily nutrition targets across meals based on percentage splits.
    
    Args:
        daily_targets: Either a dict {'calories': X, 'protein_g': Y, ...} 
                      or a tuple (calories, protein_g, fat_g, carb_g) from getUserTarget
        splits: Dict mapping meal names to percentage splits
        
    Returns:
        Dict mapping meal names to their nutrition targets
    """
    # Handle tuple format (from getUserTarget)
    if isinstance(daily_targets, tuple):
        calories, protein_g, fat_g, carb_g = daily_targets
        daily_targets_dict = {
            'calories': calories,
            'protein_g': protein_g,
            'fat_g': fat_g,
            'carb_g': carb_g
        }
    else:
        daily_targets_dict = daily_targets
    
    out: dict[str, dict[str, float]] = {}

    # loop through each split percentage and store the total cals then go through the macros
    for meal, i in splits.items():
        out[meal] = {'calories': i * daily_targets_dict['calories']}

        for j in ('protein_g','carb_g','fat_g'):
            out[meal][j] = i * daily_targets_dict[j]

    return out
