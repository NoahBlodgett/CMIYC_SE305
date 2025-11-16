import pandas as pd
import numpy as np
import sys
from pathlib import Path
from typing import Dict, Tuple, Optional, Union

from sklearn.preprocessing import MinMaxScaler

# Add config and utils to path
config_path = Path(__file__).parent.parent.parent / "config"
utils_path = Path(__file__).parent.parent.parent / "api"
sys.path.append(str(config_path))
sys.path.append(str(utils_path))

from config import SPLITS
from utils import mealTargets


class CandidatePoolBuilder:
    """
    Builds candidate pools for meal planning using ML scoring and filtering.
    
    Handles:
    - Data loading and preprocessing
    - User preference scoring via embeddings
    - Nutrition fit scoring
    - Diversity/novelty scoring
    - Allergen and preference filtering
    - Final candidate pool generation
    """
    
    def __init__(self, 
                 config_splits: Dict[str, float] = None,
                 pool_size: int = 40,
                 recall_size: int = 200,
                 recall_window_pct: float = 0.40,
                 alpha_pref: float = 0.55,
                 beta_fit: float = 0.35, 
                 gamma_nov: float = 0.10,
                 max_cluster_fraction: float = 0.25):
        """
        Initialize the candidate pool builder.
        
        Args:
            config_splits: Meal type splits (defaults to config.SPLITS)
            pool_size: Final number of candidates per meal type
            recall_size: Intermediate recall pool size before diversity filtering
            recall_window_pct: Calorie window percentage for recall
            alpha_pref: Weight for preference scoring
            beta_fit: Weight for nutrition fit scoring
            gamma_nov: Weight for novelty/diversity scoring
            max_cluster_fraction: Max fraction of pool from single cluster
        """
        self.splits = config_splits or SPLITS
        self.pool_size = pool_size
        self.recall_size = recall_size
        self.recall_window_pct = recall_window_pct
        
        # Scoring weights
        self.alpha_pref = alpha_pref
        self.beta_fit = beta_fit
        self.gamma_nov = gamma_nov
        
        # Diversity controls
        self.max_cluster_fraction = max_cluster_fraction
        
        # Compute meal limits from splits
        self.meal_limits = self._compute_meal_limits()
        
        # Will be set when data is loaded
        self.daily_kcal = None
        
    def _compute_meal_limits(self) -> Dict[str, Dict[str, float]]:
        """Create meal calorie limits from config splits."""
        meal_limits = {}
        for meal, split in self.splits.items():
            margin = 0.05  # ±5% around the config split
            meal_limits[meal] = {
                'min': max(0.0, split - margin), 
                'max': split + margin
            }
        return meal_limits
    
    def _get_meal_scoring_targets(self, meal_type: str, per_meal_targets: Dict[str, Dict[str, float]],
                                 kcal_band_width: float = 0.20, kcal_window_extra: float = 0.40) -> Dict[str, float]:
        
        target_info = per_meal_targets[meal_type]
        target_kcal = float(target_info["calories"])
        protein_target = float(target_info["protein_g"])

        # Compute ideal kcal band around target
        half_band_width = target_kcal * (kcal_band_width / 2.0)
        kcal_low = target_kcal - half_band_width
        kcal_high = target_kcal + half_band_width

        # Compute wider recall window
        window_low = kcal_low * (1.0 - kcal_window_extra)
        window_high = kcal_high * (1.0 + kcal_window_extra)

        return {
            "kcal_low": kcal_low,
            "kcal_high": kcal_high,
            "window_low": window_low,
            "window_high": window_high,
            "protein_target": protein_target,
        }
    
    def _compute_nutrition_fit(self, row: pd.Series, kcal_low: float, kcal_high: float, window_low: float,
                              window_high: float, protein_target: float, protein_tol: float = 0.20) -> float:
        
        cal = row['per_serving_kcal']
        protein = row['protein_g']

        # Calorie scoring
        if cal < window_low or cal > window_high:
            kcal_score = 0.0
        else:
            if kcal_low <= cal <= kcal_high:
                kcal_score = 1.0
            elif cal < kcal_low:
                denom = max(1e-6, kcal_low - window_low)
                kcal_score = 1.0 - (kcal_low - cal) / denom
            else:  # cal > kcal_high
                denom = max(1e-6, window_high - kcal_high)
                kcal_score = 1.0 - (cal - kcal_high) / denom
            kcal_score = max(0.0, min(1.0, float(kcal_score)))
        
        # Protein scoring
        tol = protein_tol * protein_target
        max_error = 3.0 * tol
        error = abs(protein - protein_target)

        if error <= tol:
            protein_score = 1.0
        elif error >= max_error:
            protein_score = 0.0
        else:
            protein_score = 1.0 - (error - tol) / (max_error - tol)
        protein_score = max(0.0, min(1.0, float(protein_score)))

        # Combined fit score
        fit = 0.7 * kcal_score + 0.3 * protein_score
        return max(0.0, min(1.0, float(fit)))
    
    def _build_cold_start_user_vector(self, emb_matrix: np.ndarray) -> np.ndarray:
        mean_vec = emb_matrix.mean(axis=0)
        norm = np.linalg.norm(mean_vec)
        if norm == 0:
            return mean_vec
        return mean_vec / norm
    
    def _compute_preference_scores(self, emb_matrix: np.ndarray, user_vec: np.ndarray) -> np.ndarray:
        user_vec = np.asarray(user_vec, dtype=np.float32).reshape(-1)
        norm = np.linalg.norm(user_vec)
        if norm > 0:
            user_vec = user_vec / norm

        sims = emb_matrix @ user_vec
        sims_reshaped = sims.reshape(-1, 1)
        scaler = MinMaxScaler(feature_range=(0.0, 1.0))
        sims_scaled = scaler.fit_transform(sims_reshaped).flatten()
        return sims_scaled
    
    def _compute_cluster_novelty(self, cluster_ids: np.ndarray) -> np.ndarray:
        unique, counts = np.unique(cluster_ids, return_counts=True)
        freq = dict(zip(unique, counts))
        inv_freq = np.array([1.0 / freq[c] for c in cluster_ids], dtype=np.float32)
        scaler = MinMaxScaler(feature_range=(0.0, 1.0))
        novelty_scaled = scaler.fit_transform(inv_freq.reshape(-1, 1)).flatten()
        return novelty_scaled
    
    def _apply_diversity_quota(self, df: pd.DataFrame) -> pd.DataFrame:
        max_per_cluster = int(self.max_cluster_fraction * self.pool_size)
        if max_per_cluster < 1:
            max_per_cluster = 1

        counts = {}
        selected_rows = []

        for _, row in df.iterrows():
            cid = int(row["cluster_id"])
            current = counts.get(cid, 0)

            if current >= max_per_cluster:
                continue

            selected_rows.append(row)
            counts[cid] = current + 1

            if len(selected_rows) >= self.pool_size:
                break

        if not selected_rows:
            return df.head(self.pool_size).reset_index(drop=True)

        return pd.DataFrame(selected_rows).reset_index(drop=True)
    
    def _apply_user_filtering(self, df_meal: pd.DataFrame, user_data: Dict) -> pd.DataFrame:
        if not user_data:
            return df_meal
            
        allergies = user_data.get('allergies', [])
        preferences = user_data.get('preferences', [])
        exclude_terms = allergies + preferences
        
        if not exclude_terms:
            return df_meal
            
        pattern = '|'.join([str(term).lower() for term in exclude_terms])
        name_col = 'name' if 'name' in df_meal.columns else 'food_name'
        
        if name_col in df_meal.columns:
            original_count = len(df_meal)
            df_meal = df_meal[~df_meal[name_col].str.lower().str.contains(
                pattern, case=False, na=False, regex=True)]
            removed_count = original_count - len(df_meal)
        
        if df_meal.empty:
            raise ValueError(f"No recipes available after filtering")
            
        return df_meal
    
    def _standardize_columns(self, df: pd.DataFrame) -> pd.DataFrame:
        df = df.copy()
        
        # Calorie column standardization
        if 'calories' in df.columns and 'per_serving_kcal' not in df.columns:
            df['per_serving_kcal'] = df['calories']
        elif 'per_serving_kcal' not in df.columns:
            raise ValueError("Neither 'calories' nor 'per_serving_kcal' column found")
        
        # ID column standardization
        if 'id' in df.columns and 'recipe_id' not in df.columns:
            df['recipe_id'] = df['id']
        elif 'recipe_id' not in df.columns:
            df['recipe_id'] = range(len(df))
            
        # Ensure both formats exist for GetMeals compatibility
        if 'per_serving_kcal' in df.columns:
            df['calories'] = df['per_serving_kcal']
        if 'recipe_id' in df.columns:
            df['id'] = df['recipe_id']
            
        return df
    
    def _load_data(self) -> pd.DataFrame:
        """Load and preprocess the meal data."""
        data_path = Path(__file__).parent.parent.parent / "data" / "processed" / "all_meals_clean.parquet"
        
        if not data_path.exists():
            raise FileNotFoundError(f"Processed data file not found: {data_path}")
        
        df_all = pd.read_parquet(data_path)
        print(f"Loaded {len(df_all)} recipes from {data_path}")
        
        # Add required columns for ML scoring if missing
        if 'cluster_id' not in df_all.columns:
            df_all['cluster_id'] = np.random.randint(0, 10, len(df_all))
            
        # Add dummy embeddings if missing
        emb_cols = [c for c in df_all.columns if c.startswith("emb_")]
        if len(emb_cols) == 0:
            print("Adding synthetic embeddings for ML scoring...")
            for i in range(50):
                df_all[f'emb_{i}'] = np.random.normal(0, 1, len(df_all))
        
        return self._standardize_columns(df_all)
    
    def score_meal_candidates(self, df_all: pd.DataFrame, meal_type: str, per_meal_targets: Dict[str, Dict[str, float]], 
                             user_data: Optional[Dict] = None) -> pd.DataFrame:
        
        # Filter to meal type
        df_meal = df_all[df_all["meal_type"] == meal_type].copy()
        if df_meal.empty:
            raise ValueError(f"No rows found for meal_type={meal_type}")
        
        # Apply user filtering
        df_meal = self._apply_user_filtering(df_meal, user_data or {})
        
        # Extract embeddings
        emb_cols = [c for c in df_meal.columns if c.startswith("emb_")]
        X_emb = df_meal[emb_cols].values.astype(np.float32)

        # Build user vector and preference scores
        user_vec = self._build_cold_start_user_vector(X_emb)
        pref_scores = self._compute_preference_scores(X_emb, user_vec)
        df_meal["preference_score"] = pref_scores

        # Get scoring targets
        targets = self._get_meal_scoring_targets(meal_type, per_meal_targets)

        # Compute nutrition fit
        df_meal["nutrition_fit"] = df_meal.apply(
            lambda row: self._compute_nutrition_fit(
                row,
                kcal_low=targets["kcal_low"],
                kcal_high=targets["kcal_high"], 
                window_low=targets["window_low"],
                window_high=targets["window_high"],
                protein_target=targets["protein_target"],
            ),
            axis=1,
        )

        # Novelty scores
        cluster_ids = df_meal["cluster_id"].values.astype(np.int32)
        novelty_scores = self._compute_cluster_novelty(cluster_ids)
        df_meal["novelty_bonus"] = novelty_scores

        # Final scoring
        df_meal["model_score"] = (
            self.alpha_pref * df_meal["preference_score"]
            + self.beta_fit * df_meal["nutrition_fit"] 
            + self.gamma_nov * df_meal["novelty_bonus"]
        )
        df_meal["final_model_score"] = df_meal["model_score"].clip(lower=0.0, upper=1.0)

        # Apply recall window
        window_low = targets["window_low"]
        window_high = targets["window_high"]
        
        df_recall = df_meal[
            (df_meal["per_serving_kcal"] >= window_low) &
            (df_meal["per_serving_kcal"] <= window_high)
        ].copy()

        if len(df_recall) < self.recall_size:
            df_recall = df_meal.copy()

        # Sort and trim
        df_recall = df_recall.sort_values(
            by=["final_model_score", "nutrition_fit", "novelty_bonus", "preference_score", "recipe_id"],
            ascending=[False, False, False, False, True],
        ).head(self.recall_size).reset_index(drop=True)

        # Apply diversity
        df_pool = self._apply_diversity_quota(df_recall)

        # Add required fields for GetMeals
        df_pool["meal_slot"] = meal_type
        if "primary_protein" not in df_pool.columns:
            df_pool["primary_protein"] = "unknown"
        if "cuisine" not in df_pool.columns:
            df_pool["cuisine"] = "unknown"

        return df_pool.reset_index(drop=True)
    
    def build_pools(self, 
                   daily_targets: Union[Dict[str, float], Tuple[float, float, float, float]], 
                   user_data: Optional[Dict] = None) -> Dict[str, pd.DataFrame]:
        
        # Convert tuple to dict if needed
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
        
        # Load data
        df_all = self._load_data()
        
        # Calculate per-meal targets
        per_meal = mealTargets(daily_targets_dict, self.splits)
        outputs = {}

        for meal_type in self.splits.keys():
            print(f"\n=== Building candidates for {meal_type} ===")
            
            try:
                df_candidates = self.score_meal_candidates(
                    df_all=df_all,
                    meal_type=meal_type, 
                    per_meal_targets=per_meal,
                    user_data=user_data,
                )
                
                outputs[meal_type] = df_candidates
                print(f"Built {len(df_candidates)} candidates for {meal_type}")
                
            except ValueError as e:
                print(f"Warning: {e}")
                # Create empty DataFrame for this meal type
                outputs[meal_type] = pd.DataFrame()

        return outputs