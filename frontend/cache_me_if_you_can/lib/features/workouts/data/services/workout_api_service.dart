import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workout_session.dart';

class WorkoutApiService {
  WorkoutApiService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> logWorkout(WorkoutSession session) async {
    final durationMinutes = _durationValue(session);
    final calories =
        (_ensurePositive(session.caloriesBurned) ?? 1).clamp(1, 5000).toDouble();
    final payload = <String, dynamic>{
      'user_id': session.userId,
      'duration': durationMinutes,
      'cals_burned': calories,
      'date': Timestamp.fromDate(session.timestamp),
      'weight_lifted': _weightLiftedValue(session),
    };
    final movement = _movementPayload(session);
    if (movement != null) {
      payload['movement'] = movement;
    }
    await _db.collection('workouts').add(payload);
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts(String userId) async {
    final snapshot = await _db
        .collection('workouts')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<Map<String, dynamic>> getWorkout(String id) async {
    final doc = await _db.collection('workouts').doc(id).get();
    if (!doc.exists) {
      throw Exception('Workout not found');
    }
    return {'id': doc.id, ...doc.data()!};
  }

  Future<void> updateWorkout(String id, Map<String, dynamic> updateData) async {
    await _db.collection('workouts').doc(id).update(updateData);
  }

  Future<void> deleteWorkout(String id) async {
    await _db.collection('workouts').doc(id).delete();
  }

  int _durationValue(WorkoutSession session) {
    final base = session.durationMinutes ?? (session.sets.length * 2);
    final clamped = base.clamp(1, 600);
    return clamped is int ? clamped : clamped.round();
  }

  double _weightLiftedValue(WorkoutSession session) {
    if (session.sets.isNotEmpty) {
      final total = session.sets.fold<double>(
        0,
        (sum, set) => sum + (set.weightKg ?? 0),
      );
      if (total > 0) return double.parse(total.toStringAsFixed(2));
      return session.sets.length.toDouble();
    }
    final durationFallback =
        (session.durationMinutes ?? 1).clamp(1, 600).toDouble();
    return durationFallback;
  }

  Map<String, dynamic>? _movementPayload(WorkoutSession session) {
    if (session.type != WorkoutSessionType.strength ||
        session.sets.isEmpty) {
      return null;
    }
    final totalReps = session.sets.fold<int>(0, (sum, set) => sum + set.reps);
    final avgReps = (totalReps / session.sets.length).round();
    final safeReps = avgReps < 1
        ? 1
        : (avgReps > 200 ? 200 : avgReps);
    return {
      'name': session.name ?? 'Strength Session',
      'muscle_group': 'full_body',
      'sets': session.sets.length,
      'reps': safeReps,
    };
  }

  double? _ensurePositive(double? value) {
    if (value == null) return null;
    return value <= 0 ? 1 : value;
  }
}
