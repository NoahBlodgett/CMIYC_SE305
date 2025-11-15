import pandas as pd
import numpy as np
import sys
from pathlib import Path

from sklearn.preprocessing import MinMaxScaler

# Add config and utils to path
config_path = Path(__file__).parent.parent.parent / "config"
utils_path = Path(__file__).parent.parent.parent / "api"
sys.path.append(str(config_path))
sys.path.append(str(utils_path))

from config import SPLITS
from utils import mealTargets

DAILY_KCAL = None

MEAL_LIMITS = {
    'breakfast': {'min': .20, 'max': .25},
    'lunch': { 'min': .30, 'max': .35},
    'dinner': {'min': .30, 'max': .35},
    'snack': {'min': .10, 'max': .15}
}

RECALL_WINDOW_PCT = .40 # how broad the nutrition window is
POOL_SIZE = 40 # how many candidates per meal the greedy algo sees
RECALL_SIZE = 200 # how many to keep before diversity filter

# Weights for preference, fit for nutrition, and novelty/diversity
ALPHA_PREF = .55 
BETA_FIT = .35
GAMMA_NOV = .10

# no more than 25% of pool from a single cluster
MAX_CLUSTER_FRACTION = .25

def compute_meal_limits(meal_type: str) -> tuple[float, float]:
    """Get calorie limits for a specific meal type based on DAILY_KCAL"""
    if DAILY_KCAL is None:
        raise ValueError("DAILY_KCAL must be set before computing meal limits")
    
    limits = MEAL_LIMITS.get(meal_type)
    if limits is None:
        raise ValueError(f"Unknown meal_type: {meal_type}")
    
    low_limit = DAILY_KCAL * limits['min']
    high_limit = DAILY_KCAL * limits['max']
    
    return low_limit, high_limit

def get_meal_scoring_targets(meal_type: str, per_meal_targets: dict[str, dict[str, float]],
    kcal_band_width: float = 0.20,    # band = +/- 10% around target
    kcal_window_extra: float = 0.40,  # recall window = band +/- 40%
) -> dict[str, float]:
    # Pull this meal's macro targets from the per_meal_targets dict
    target_info = per_meal_targets[meal_type]

    target_kcal = float(target_info["calories"])
    protein_target = float(target_info["protein_g"])

    # Compute the ideal kcal band around the target
    half_band_width = target_kcal * (kcal_band_width / 2.0)

    kcal_low = target_kcal - half_band_width
    kcal_high = target_kcal + half_band_width

    # 3) Compute a wider recall window around the band
    #    Example: window_extra_frac=0.40 -> window extends band by 40% on each side
    window_low = kcal_low * (1.0 - kcal_window_extra)
    window_high = kcal_high * (1.0 + kcal_window_extra)

    return {
        "kcal_low": kcal_low,
        "kcal_high": kcal_high,
        "window_low": window_low,
        "window_high": window_high,
        "protein_target": protein_target,
    }

def nutrition_fit(row: pd.Series, kcal_low: float, kcal_high: float, window_low: float,
                window_high: float, protein_target: float, protein_tol: float = 0.20,   # +/- 20% of target is "good"
) -> float:    
    
    cal = row['per_serving_kcal']
    protein = row['protein_g']

    # Use the passed window values (these should be computed in get_meal_scoring_targets)

    if cal < window_low or cal > window_high:
        kcal_score = 0.0 # 0 score if outside window
    else:
        # Inside the ideal band
        if kcal_low <= cal <= kcal_high:
            kcal_score = 1.0
        # Below the band but inside the window: decay 1 -> 0 as we go toward window_low
        elif cal < kcal_low:
            denom = max(1e-6, kcal_low - window_low)
            kcal_score = 1.0 - (kcal_low - cal) / denom
        # Above the band but inside the window: decay 1 -> 0 as we go toward window_high
        else:  # kcal > kcal_high and <= window_high
            denom = max(1e-6, window_high - kcal_high)
            kcal_score = 1.0 - (cal - kcal_high) / denom

        # Clamp just in case
        kcal_score = max(0.0, min(1.0, float(kcal_score)))
    
    tol = protein_tol * protein_target          # e.g. +/- 20% of target is "good"
    max_error = 3.0 * tol                            # beyond this, score ~ 0

    error = abs(protein - protein_target)

    if error <= tol:
        protein_score = 1.0
    elif error >= max_error:
        protein_score = 0.0
    else:
        # Linearly decay from 1 at tol to 0 at max_error
        protein_score = 1.0 - (error - tol) / (max_error - tol)

    protein_score = max(0.0, min(1.0, float(protein_score)))

    fit = 0.7 * kcal_score + 0.3 * protein_score
    fit = max(0.0, min(1.0, float(fit)))

    return fit

# essentially starts a user as liking the avergae of all the recipes as a start
def build_cold_start_user_vector(emb_matrix: np.ndarray) -> np.ndarray:
    # Average across all recipes to get a "typical" embedding
    mean_vec = emb_matrix.mean(axis=0)  # shape: (emb_dim,)

    # Compute its L2 norm (length of the vector)
    norm = np.linalg.norm(mean_vec)

    # If norm is zero (degenerate case), just return the unnormalized mean
    if norm == 0:
        return mean_vec

    # Otherwise, return the unit vector (L2-normalized)
    return mean_vec / norm

# unused for now.
def build_user_preference_vector(
    history_emb: np.ndarray,
    global_emb_matrix: np.ndarray | None = None,
    history_weight: float = 0.7,
) -> np.ndarray:
    """
    Build a personalized user vector from the embeddings of recipes the user
    has actually chosen (accepted/liked/cooked).

    If history is empty, or too small, this falls back to a cold-start vector
    based on global_emb_matrix (if provided) or just returns the mean.

    Args:
        history_emb:      (n_history, emb_dim) embeddings of recipes this user liked.
        global_emb_matrix:(n_recipes, emb_dim) all recipe embeddings (for cold-start).
        history_weight:   how much to weight user history vs global average in [0,1].

    Returns:
        user_vec: L2-normalized user preference vector (emb_dim,)
    """
    # Defensive: ensure we have a 2D float array for history
    history_emb = np.asarray(history_emb, dtype=np.float32)

    # Case 1: no history at all -> pure cold-start
    if history_emb.size == 0:
        if global_emb_matrix is None:
            # Degenerate fallback: zero vector
            return np.zeros((global_emb_matrix.shape[1] if global_emb_matrix is not None else 0,), dtype=np.float32)
        return build_cold_start_user_vector(global_emb_matrix)

    # Case 2: very small history (1–2 recipes)
    # We'll still use it, but blending with cold-start is important
    # Compute the mean of the history embeddings
    user_mean = history_emb.mean(axis=0)

    # If we have a global matrix, build a cold-start vector to blend with
    if global_emb_matrix is not None and history_weight < 1.0:
        cold_vec = build_cold_start_user_vector(global_emb_matrix)
        # Blend: history_weight * user_mean + (1 - history_weight) * cold_vec
        blended = history_weight * user_mean + (1.0 - history_weight) * cold_vec
    else:
        # No global matrix or history_weight==1.0 -> just use the history mean
        blended = user_mean

    # L2-normalize the blended vector
    norm = np.linalg.norm(blended)
    if norm == 0:
        return blended.astype(np.float32)

    return (blended / norm).astype(np.float32)

def compute_preference_scores(emb_matrix: np.ndarray, user_vec: np.ndarray) -> np.ndarray:

    # Make sure user_vec is a 1D float array
    user_vec = np.asarray(user_vec, dtype=np.float32).reshape(-1)

    # Optionally re-normalize user_vec to unit length (defensive)
    norm = np.linalg.norm(user_vec)
    if norm > 0:
        user_vec = user_vec / norm

    # Compute cosine-like similarity as dot product (rows are recipes)
    sims = emb_matrix @ user_vec  # shape: (n_recipes,)

    # Reshape to 2D for MinMaxScaler
    sims_reshaped = sims.reshape(-1, 1)

    # Scale similarities to [0, 1] across this meal
    scaler = MinMaxScaler(feature_range=(0.0, 1.0))
    sims_scaled = scaler.fit_transform(sims_reshaped).flatten()

    return sims_scaled

def compute_cluster_novelty(cluster_ids: np.ndarray) -> np.ndarray:

    # Count occurrences of each cluster_id
    unique, counts = np.unique(cluster_ids, return_counts=True)
    freq = dict(zip(unique, counts))

    # Inverse frequency: rarer clusters get higher values
    inv_freq = np.array([1.0 / freq[c] for c in cluster_ids], dtype=np.float32)

    # Scale to [0, 1] so it behaves like a bonus term
    scaler = MinMaxScaler(feature_range=(0.0, 1.0))
    novelty_scaled = scaler.fit_transform(inv_freq.reshape(-1, 1)).flatten()

    return novelty_scaled

def apply_diversity_quota(df: pd.DataFrame, pool_size: int) -> pd.DataFrame:

    max_per_cluster = int(MAX_CLUSTER_FRACTION * pool_size)
    if max_per_cluster < 1:
        max_per_cluster = 1  # at least 1 per cluster if pool_size is tiny

    counts: dict[int, int] = {}
    selected_rows = []

    # Iterate rows in score order
    for _, row in df.iterrows():
        cid = int(row["cluster_id"])
        current = counts.get(cid, 0)

        # Skip if this cluster already hit its quota
        if current >= max_per_cluster:
            continue

        # Otherwise, select this row
        selected_rows.append(row)
        counts[cid] = current + 1

        # Stop once we have enough candidates
        if len(selected_rows) >= pool_size:
            break

    # Fallback: if nothing selected (shouldn't happen), just take top pool_size
    if not selected_rows:
        return df.head(pool_size).reset_index(drop=True)

    # Build new DataFrame from selected rows
    result = pd.DataFrame(selected_rows).reset_index(drop=True)
    return result

def score_and_select_for_meal(df_all: pd.DataFrame, meal_type: str,
                              per_meal_targets: dict[str, dict[str, float]],
) -> pd.DataFrame:

    #  Filter to this meal_type
    df_meal = df_all[df_all["meal_type"] == meal_type].copy()
    if df_meal.empty:
        raise ValueError(f"No rows found for meal_type={meal_type}")

    # Extract embeddings for this meal
    emb_cols = [c for c in df_meal.columns if c.startswith("emb_")]
    X_emb = df_meal[emb_cols].values.astype(np.float32)

    # Build user vector (cold-start for now) + preference_score
    user_vec = build_cold_start_user_vector(X_emb)
    pref_scores = compute_preference_scores(X_emb, user_vec)
    df_meal["preference_score"] = pref_scores

    # Get macro-driven scoring targets for this meal
    targets = get_meal_scoring_targets(
        meal_type=meal_type,
        per_meal_targets=per_meal_targets,
    )

    # Compute nutrition_fit for each recipe
    df_meal["nutrition_fit"] = df_meal.apply(
        lambda row: nutrition_fit(
            row,
            kcal_low=targets["kcal_low"],
            kcal_high=targets["kcal_high"],
            window_low=targets["window_low"],
            window_high=targets["window_high"],
            protein_target=targets["protein_target"],
        ),
        axis=1,
    )

    # Novelty bonus based on cluster rarity
    cluster_ids = df_meal["cluster_id"].values.astype(np.int32)
    novelty_scores = compute_cluster_novelty(cluster_ids)
    df_meal["novelty_bonus"] = novelty_scores

    # Combine into final_model_score
    df_meal["model_score"] = (
        ALPHA_PREF * df_meal["preference_score"]
        + BETA_FIT * df_meal["nutrition_fit"]
        + GAMMA_NOV * df_meal["novelty_bonus"]
    )
    df_meal["final_model_score"] = df_meal["model_score"].clip(lower=0.0, upper=1.0)

    # Apply kcal-based recall window (using macro-driven window)
    window_low = targets["window_low"]
    window_high = targets["window_high"]

    df_recall = df_meal[
        (df_meal["per_serving_kcal"] >= window_low)
        & (df_meal["per_serving_kcal"] <= window_high)
    ].copy()

    # If too few items pass the window, fall back to all recipes for this meal
    if len(df_recall) < RECALL_SIZE:
        df_recall = df_meal.copy()

    # Sort by scores and trim to RECALL_SIZE 
    df_recall = df_recall.sort_values(
        by=["final_model_score", "nutrition_fit", "novelty_bonus", "preference_score", "recipe_id"],
        ascending=[False, False, False, False, True],
    ).head(RECALL_SIZE).reset_index(drop=True)

    # Apply diversity quotas to get final pool
    df_pool = apply_diversity_quota(df_recall, POOL_SIZE)

    # Add schema / placeholder fields Greedy expects
    df_pool["meal_slot"] = meal_type
    df_pool["primary_protein"] = "unknown"
    df_pool["cuisine"] = "unknown"

    cols_out = [
        "meal_slot",
        "recipe_id",
        "name",
        "meal_type",
        "per_serving_kcal",
        "protein_g",
        "carbs_g",
        "fat_g",
        "primary_protein",
        "cuisine",
        "cluster_id",
        "preference_score",
        "nutrition_fit",
        "novelty_bonus",
        "model_score",
        "final_model_score",
    ]

    df_pool = df_pool[cols_out].reset_index(drop=True)
    return df_pool

def build_all_candidate_pools(df_all: pd.DataFrame, daily_targets: dict[str, float], output_dir: str | None = None,
) -> dict[str, pd.DataFrame]:
    
    perMeal = mealTargets(daily_targets, SPLITS)

    outputs: dict[str, pd.DataFrame] = {}

    for meal_type in SPLITS.keys():
        print(f"\n=== Building candidates for {meal_type} ===")
        df_pool = score_and_select_for_meal(
            df_all = df_all,
            meal_type = meal_type,
            per_meal_targets = perMeal,
        )
        outputs[meal_type] = df_pool

        # Optionally save to CSV
        if output_dir is not None:
            out_path = f"{output_dir}/candidates_{meal_type}.csv"
            df_pool.to_csv(out_path, index=False)
            print(f"Saved {len(df_pool)} candidates to {out_path}")

    return outputs