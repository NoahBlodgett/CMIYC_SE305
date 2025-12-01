import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/workout_session.dart';

class WorkoutApiService {
  final String baseUrl; // e.g., 'https://us-central1-yourproject.cloudfunctions.net'

  WorkoutApiService(this.baseUrl);

  Future<void> logWorkout(WorkoutSession session) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workouts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': session.userId,
        'duration': session.durationMinutes,
        'cals_burned': session.caloriesBurned,
        'date': session.timestamp.toIso8601String(),
        'weight_lifted': session.sets.isNotEmpty ? session.sets.first.weightKg : 0,
        'movement': session.activityKey,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to log workout: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/workouts/user/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workouts: ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getWorkout(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workout: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateWorkout(String id, Map<String, dynamic> updateData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout: ${response.body}');
    }
  }

  Future<void> deleteWorkout(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete workout: ${response.body}');
    }
  }
}
