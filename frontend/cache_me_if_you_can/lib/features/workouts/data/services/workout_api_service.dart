import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workout_session.dart';

class WorkoutApiService {
  WorkoutApiService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> logWorkout(WorkoutSession session) async {
    final durationMinutes = _durationValue(session);
    final calories =
        (_ensurePositive(session.caloriesBurned) ?? 1).clamp(1, 5000).toDouble();
    final timestampIso = session.timestamp.toIso8601String();
    final payload = <String, dynamic>{
      'user_id': session.userId,
      'userId': session.userId,
      'type': session.type.name,
      'duration': durationMinutes,
      'duration_minutes': durationMinutes,
      'cals_burned': calories,
      'calories_burned': calories,
      'date': Timestamp.fromDate(session.timestamp),
      'timestamp': timestampIso,
      'weight_lifted': _weightLiftedValue(session),
      'sets': session.sets.map((s) => s.toMap()).toList(),
      'name': session.name,
      'notes': session.notes,
    };
    if (session.exercises.isNotEmpty) {
      payload['exercises'] = session.exercises;
    }
    final activityKey = session.activityKey;
    if (activityKey != null && activityKey.isNotEmpty) {
      payload['activity_key'] = activityKey;
      payload['activityKey'] = activityKey;
    }
    final movement = _movementPayload(session);
    if (movement != null) {
      payload['movement'] = movement;
    }

    final workoutsDoc = _db.collection('workouts').doc();
    final userSessionDoc = _db
        .collection('users')
        .doc(session.userId)
        .collection('workout_sessions')
        .doc(workoutsDoc.id);

    final batch = _db.batch();
    batch.set(workoutsDoc, payload);
    batch.set(userSessionDoc, {
      ...payload,
      'sessionId': workoutsDoc.id,
    });
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts(
    String userId, {
    int limit = 50,
  }) async {
    final results = await Future.wait([
      _workoutsByField('user_id', userId, limit),
      _workoutsByField('userId', userId, limit),
      _userSessionsSnapshot(userId, limit),
    ]);

    final deduped = <String, Map<String, dynamic>>{};

    for (final doc in results[0].docs) {
      deduped.putIfAbsent(doc.id, () => _normalizeWorkoutDoc(doc.id, doc.data()));
    }
    for (final doc in results[1].docs) {
      deduped.putIfAbsent(doc.id, () => _normalizeWorkoutDoc(doc.id, doc.data()));
    }
    for (final doc in results[2].docs) {
      final data = doc.data();
      final normalizedId = (data['sessionId'] as String?) ?? doc.id;
      deduped.putIfAbsent(normalizedId, () => _normalizeWorkoutDoc(normalizedId, data));
    }

    final workouts = deduped.values.toList();
    workouts.sort((a, b) {
      final aDate = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    if (workouts.length > limit) {
      return workouts.sublist(0, limit);
    }
    return workouts;
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
    return clamped.toInt();
  }

  double _weightLiftedValue(WorkoutSession session) {
    if (session.sets.isNotEmpty) {
      final total = session.sets.fold<double>(
        0,
        (runningTotal, set) => runningTotal + (set.weightKg ?? 0),
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
    final totalReps = session.sets.fold<int>(
      0,
      (runningTotal, set) => runningTotal + set.reps,
    );
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

  Future<QuerySnapshot<Map<String, dynamic>>> _workoutsByField(
    String field,
    String userId,
    int limit,
  ) async {
    try {
      return await _db
          .collection('workouts')
          .where(field, isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (_) {
      return await _db
          .collection('workouts')
          .where(field, isEqualTo: userId)
          .get();
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _userSessionsSnapshot(
    String userId,
    int limit,
  ) async {
    try {
      return await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (_) {
      return await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .get();
    }
  }

  Map<String, dynamic> _normalizeWorkoutDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    final sets = (data['sets'] as List?) ?? const [];
    final type = (data['type'] as String?) ??
        (sets.isNotEmpty ? 'strength' : 'timed');
    final duration = _asInt(data['duration_minutes']) ??
        _asInt(data['duration']) ??
        _asInt(data['durationMinutes']);
    final calories = _asDouble(data['calories_burned']) ??
        _asDouble(data['cals_burned']) ??
        _asDouble(data['caloriesBurned']);
    return {
      'id': id,
      'type': type,
      'durationMinutes': duration,
      'caloriesBurned': calories,
      'activityKey': data['activity_key'] ?? data['activityKey'],
      'sets': sets,
      'name': data['name'],
      'notes': data['notes'],
      'exercises': (data['exercises'] as List?) ?? const [],
      'timestamp': _timestampIso(data),
    };
  }

  String _timestampIso(Map<String, dynamic> data) {
    DateTime? ts;
    final dateField = data['date'];
    if (dateField is Timestamp) {
      ts = dateField.toDate();
    } else if (dateField is String) {
      ts = DateTime.tryParse(dateField);
    }
    if (ts == null) {
      final timestampField = data['timestamp'];
      if (timestampField is Timestamp) {
        ts = timestampField.toDate();
      } else if (timestampField is String) {
        ts = DateTime.tryParse(timestampField);
      }
    }
    ts ??= DateTime.fromMillisecondsSinceEpoch(0);
    return ts.toIso8601String();
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
