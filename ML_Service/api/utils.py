def mealTargets(daily_targets: dict | tuple, splits: dict[str, float]) -> dict[str, dict[str, float]]:
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
