import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/services/met_calorie_service.dart';
import 'data/services/workout_api_service.dart';
import 'data/services/weekly_workout_summary_service.dart';

// Replace with your deployed backend URL
final WorkoutApiService workoutApiService = WorkoutApiService('https://your-cloud-function-url');
final MetCalorieService metCalorieService = MetCalorieService.instance;
final WeeklyWorkoutSummaryService weeklyWorkoutSummaryService =
    WeeklyWorkoutSummaryService(db: FirebaseFirestore.instance);
