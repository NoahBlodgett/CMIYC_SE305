import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/workout_session.dart';

class WeeklyWorkoutSummary {
  final DateTime startDate; // inclusive (start of day)
  final DateTime endDate; // inclusive (end of day)
  final int totalSessions;
  final int timedMinutes; // sum of durationMinutes for timed sessions
  final int strengthSets; // total sets across strength sessions
  final double totalCalories; // sum of caloriesBurned
  final Map<String, int> sessionsByDay; // yyyy-MM-dd -> count

  const WeeklyWorkoutSummary({
    required this.startDate,
    required this.endDate,
    required this.totalSessions,
    required this.timedMinutes,
    required this.strengthSets,
    required this.totalCalories,
    required this.sessionsByDay,
  });
}

class WeeklyWorkoutSummaryService {
  final FirebaseFirestore _db;
  WeeklyWorkoutSummaryService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Streams aggregation for the last 7 days (including today).
  Stream<WeeklyWorkoutSummary> streamFor(String uid, {DateTime? anchor}) {
    final now = anchor ?? DateTime.now();
    final end = _startOfDay(now);
    final start = end.subtract(const Duration(days: 6));

    // We stored timestamps as ISO8601 strings; lexical ordering works for date range queries.
    final startIso = start.toIso8601String();

    final col = _db.collection('users').doc(uid).collection('workout_sessions');
    final query = col
        .where('timestamp', isGreaterThanOrEqualTo: startIso)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return query.map((snap) {
      int totalSessions = 0;
      int timedMinutes = 0;
      int strengthSets = 0;
      double totalCalories = 0;
      final sessionsByDay = <String, int>{};

      for (final doc in snap.docs) {
        final session = WorkoutSession.fromMap(doc.id, doc.data());
        final dayKey = _dayKey(session.timestamp);
        sessionsByDay.update(dayKey, (v) => v + 1, ifAbsent: () => 1);
        totalSessions++;
        totalCalories += session.caloriesBurned ?? 0;
        if (session.type == WorkoutSessionType.timed) {
          timedMinutes += session.durationMinutes ?? 0;
        } else {
          strengthSets += session.sets.length;
        }
      }

      return WeeklyWorkoutSummary(
        startDate: start,
        endDate: end,
        totalSessions: totalSessions,
        timedMinutes: timedMinutes,
        strengthSets: strengthSets,
        totalCalories: double.parse(totalCalories.toStringAsFixed(2)),
        sessionsByDay: sessionsByDay,
      );
    });
  }
}
