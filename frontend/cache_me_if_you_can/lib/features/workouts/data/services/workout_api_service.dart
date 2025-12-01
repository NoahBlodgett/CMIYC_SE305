import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/workout_session.dart';

class WorkoutApiService {
  final String baseUrl; // e.g., 'https://us-central1-yourproject.cloudfunctions.net'
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WorkoutApiService(this.baseUrl);

  Future<Map<String, String>> _authHeaders({bool includeJson = true}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Unable to fetch auth token');
    }
    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> logWorkout(WorkoutSession session) async {
    final headers = await _authHeaders();
    final durationMinutes = _durationValue(session);
    final calories =
        (_ensurePositive(session.caloriesBurned) ?? 1).clamp(1, 5000).toDouble();
    final payload = <String, dynamic>{
      'user_id': session.userId,
      'duration': durationMinutes,
      'cals_burned': calories,
      'date': session.timestamp.toIso8601String(),
      'weight_lifted': _weightLiftedValue(session),
    };
    final movement = _movementPayload(session);
    if (movement != null) {
      payload['movement'] = movement;
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl/workouts'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw Exception('Failed to log workout: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts(String userId) async {
    final headers = await _authHeaders(includeJson: false);
    final response = await http
        .get(
          Uri.parse('$baseUrl/workouts/user/$userId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workouts: ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getWorkout(String id) async {
    final headers = await _authHeaders(includeJson: false);
    final response = await http
        .get(
          Uri.parse('$baseUrl/workouts/$id'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workout: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateWorkout(String id, Map<String, dynamic> updateData) async {
    final headers = await _authHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/workouts/$id'),
          headers: headers,
          body: jsonEncode(updateData),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout: ${response.body}');
    }
  }

  Future<void> deleteWorkout(String id) async {
    final headers = await _authHeaders(includeJson: false);
    final response = await http
        .delete(
          Uri.parse('$baseUrl/workouts/$id'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete workout: ${response.body}');
    }
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
