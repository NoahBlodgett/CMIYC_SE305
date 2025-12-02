import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/services/met_calorie_service.dart';
import 'data/services/user_metrics_service.dart';
import 'data/services/workout_api_service.dart';
import 'data/services/weekly_workout_summary_service.dart';
import 'data/services/workout_feedback_service.dart';

final WorkoutApiService workoutApiService = WorkoutApiService();
final MetCalorieService metCalorieService = MetCalorieService.instance;
final WeeklyWorkoutSummaryService weeklyWorkoutSummaryService =
    WeeklyWorkoutSummaryService(db: FirebaseFirestore.instance);
final UserMetricsService userMetricsService = UserMetricsService(
  db: FirebaseFirestore.instance,
);
final WorkoutFeedbackService workoutFeedbackService = WorkoutFeedbackService(
  db: FirebaseFirestore.instance,
);
