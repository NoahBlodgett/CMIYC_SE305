import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/services/met_calorie_service.dart';
import 'data/repositories/firestore_workouts_repository.dart';
import 'domain/repositories/workouts_repository.dart';
import 'data/services/weekly_workout_summary_service.dart';

final WorkoutsRepository workoutsRepository = FirestoreWorkoutsRepository(
  db: FirebaseFirestore.instance,
);
final MetCalorieService metCalorieService = MetCalorieService.instance;
final WeeklyWorkoutSummaryService weeklyWorkoutSummaryService =
    WeeklyWorkoutSummaryService(db: FirebaseFirestore.instance);
