/// MET (Metabolic Equivalent of Task) based calorie calculation service.
///
/// Placement rationale:
/// - Lives under workouts/data/services as it's a pure data/logic helper
///   (no UI) that converts activity metadata + user attributes into
///   calories burned. Presentation layer (pages/widgets) can depend on it.
/// - Future: expose via a WorkoutMetricsRepository if persistence or
///   aggregation is added.
///
/// Calorie formula (standard ACSM approximation):
///   Calories = MET * 3.5 * weight_kg * duration_minutes / 200
/// Alternative (simpler) approximation sometimes used:
///   Calories ≈ MET * weight_kg * duration_hours
/// We use the ACSM version for better granularity at shorter durations.
///
/// Ranges: For MET entries like 6.0–8.0 we store as (min,max) and return
/// midpoint unless caller requests min or max explicitly.
class MetCalorieService {
  MetCalorieService._();
  static final MetCalorieService instance = MetCalorieService._();

  /// Internal MET table. Keys are lowercase simple descriptors. You can map
  /// UI activity labels to these keys. Values: if single value -> exact MET;
  /// if List of two -> range [min,max].
  static final Map<String, Object> _metTable = {
    'sleeping': 0.9,
    'sitting_quietly': 1.0,
    'eating_drinking': 1.5,
    'reading': 1.3,
    'playing_instrument': 2.0,
    'yoga_mild': 2.0,
    'stretching_mild': 2.3,
    'arm_ergometer': 2.8,
    'bowling': [3.0, 3.8],
    'walking_2_0_mph': 2.0,
    'walking_3_0_mph': 3.0,
    'walking_3_5_mph': 4.3,
    'walking_4_0_mph': 5.0,
    'tai_chi': 3.0,
    'table_tennis': 4.0,
    'golf_walking_carry': 4.8,
    'baseball_softball': [5.0, 6.0],
    'gardening_active': 4.0,
    'hiking_cross_country': 6.0,
    'horseback_riding': 5.5,
    'rock_climbing_easy': 5.8,
    'basketball_general': 6.5,
    'bicycling_5_5_mph': 3.5,
    'bicycling_10_11_9_mph': 6.8,
    'bicycling_12_13_9_mph': 8.0,
    'bicycling_14_15_9_mph': 10.0,
    'swimming_leisure': 6.0,
    'swimming_hard': [8.0, 11.0],
    'soccer_casual': 7.0,
    'soccer_competitive': 10.0,
    'tennis_doubles': 5.0,
    'tennis_singles': 8.0,
    'volleyball_noncompetitive': [3.0, 4.0],
    'volleyball_competitive': 8.0,
    'jump_rope': [9.8, 12.3],
    'aerobic_dance_medium': 6.0,
    'racquetball': 7.0,
    'football': 8.0,
    'handball': 12.0,
    'running_4_0_mph': 6.0,
    'running_5_6_mph': 8.8,
    'running_6_8_mph': 11.2,
    'running_8_6_mph': 13.5,
    'running_10_9_mph': 18.0,
    'resistance_training_moderate': 5.0,
    'heavy_weightlifting': [6.0, 8.0],
    'treadmill_desk_1_0_2_0_mph': 2.8,
    'cleaning_sweeping': 3.3,
    'food_shopping': 2.3,
    'gardening_picking': 4.0,
    'leaf_blower_edger': 4.0,
    'mowing_lawn_walk_power': 5.5,
    'scrubbing_floors_vigorous': 6.5,
  };

  /// Get MET for activity key. Returns null if not found.
  /// If range, returns midpoint unless [rangeMode] specified.
  double? getMet(String key, {MetRangeMode rangeMode = MetRangeMode.mid}) {
    final normalized = key.toLowerCase().trim();
    final raw = _metTable[normalized];
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is List) {
      final min = (raw.first as num).toDouble();
      final max = (raw.last as num).toDouble();
      switch (rangeMode) {
        case MetRangeMode.min:
          return min;
        case MetRangeMode.max:
          return max;
        case MetRangeMode.mid:
          return (min + max) / 2.0;
      }
    }
    return null;
  }

  /// Calculate calories burned.
  /// weightKg must be > 0 and durationMinutes > 0 or returns 0.
  double caloriesBurned({
    required String activityKey,
    required double weightKg,
    required int durationMinutes,
    MetRangeMode rangeMode = MetRangeMode.mid,
  }) {
    if (weightKg <= 0 || durationMinutes <= 0) return 0;
    final met = getMet(activityKey, rangeMode: rangeMode);
    if (met == null) return 0;
    return met * 3.5 * weightKg * durationMinutes / 200.0;
  }

  /// Helper to suggest closest activity keys for an arbitrary user label.
  /// Naive substring matching; future improvement: fuzzy matching.
  List<String> suggestKeys(String userLabel, {int maxSuggestions = 5}) {
    final label = userLabel.toLowerCase().trim();
    final scores = <String, int>{};
    for (final k in _metTable.keys) {
      int score = 0;
      if (k.contains(label)) score += 3;
      // Break label into words for partial matches.
      for (final part in label.split(RegExp(r'[_\s]+'))) {
        if (part.isNotEmpty && k.contains(part)) score += 1;
      }
      if (score > 0) scores[k] = score;
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(maxSuggestions).toList();
  }
}

/// Range selection mode for MET values that represent a min-max.
enum MetRangeMode { min, mid, max }

/// Utility to convert pounds to kilograms.
double poundsToKg(double pounds) => pounds * 0.45359237;

/// Utility to convert kilograms to pounds.
double kgToPounds(double kg) => kg / 0.45359237;
