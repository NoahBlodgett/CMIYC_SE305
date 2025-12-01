import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'data/services/met_calorie_service.dart';
import 'data/services/user_metrics_service.dart';
import 'data/services/workout_api_service.dart';
import 'data/services/weekly_workout_summary_service.dart';
import 'data/services/workout_feedback_service.dart';

String _workoutApiBase() {
  const override = String.fromEnvironment('WORKOUT_API_BASE');
  if (override.isNotEmpty) return override;

  // Match other network calls (e.g., profile) that default to the local Node API
  if (!kReleaseMode && !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  if (!kReleaseMode) {
    return 'http://localhost:3000';
  }
  return 'https://us-central1-se-305-db.cloudfunctions.net/api';
}

final WorkoutApiService workoutApiService = WorkoutApiService(
  _workoutApiBase(),
);
final MetCalorieService metCalorieService = MetCalorieService.instance;
final WeeklyWorkoutSummaryService weeklyWorkoutSummaryService =
    WeeklyWorkoutSummaryService(db: FirebaseFirestore.instance);
final UserMetricsService userMetricsService = UserMetricsService(
  db: FirebaseFirestore.instance,
);
final WorkoutFeedbackService workoutFeedbackService = WorkoutFeedbackService(
  db: FirebaseFirestore.instance,
);
