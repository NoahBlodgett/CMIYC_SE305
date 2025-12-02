import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart';

void main() {
  group('Mock Data Functions', () {
    setUp(() {
      // Reset state before each test
      mockCurrentProgramName = 'Beginner Full Body (Week 3)';
    });

    test('fetchCurrentProgramName returns mock program name', () async {
      final name = await fetchCurrentProgramName();
      expect(name, 'Beginner Full Body (Week 3)');
    });

    test('setCurrentProgramName updates mock program', () async {
      await setCurrentProgramName('New Program');
      expect(mockCurrentProgramName, 'New Program');
    });

    test('fetchRecentPrograms returns list of programs', () async {
      final programs = await fetchRecentPrograms();
      expect(programs, isA<List<String>>());
      expect(programs.isNotEmpty, true);
    });

    test('fetchRecentPrograms respects limit parameter', () async {
      final programs = await fetchRecentPrograms(limit: 2);
      expect(programs.length, lessThanOrEqualTo(2));
    });

    test('mockLogin succeeds with valid email', () async {
      final result = await mockLogin('alex.carter@example.com', 'anypass');
      expect(result['ok'], true);
      expect(result['user'], isNotNull);
      expect(result['token'], 'mock-token-123');
    });

    test('mockLogin fails with invalid email', () async {
      final result = await mockLogin('wrong@example.com', 'anypass');
      expect(result['ok'], false);
      expect(result['error'], 'Invalid credentials');
    });

    test('fetchUserProfile returns user data', () async {
      final profile = await fetchUserProfile();
      expect(profile['userId'], 'U12345');
      expect(profile['name'], 'Alex Carter');
      expect(profile['email'], 'alex.carter@example.com');
    });

    test('fetchWorkoutLogs returns workout log list', () async {
      final logs = await fetchWorkoutLogs();
      expect(logs, isA<List<Map<String, dynamic>>>());
      expect(logs.isNotEmpty, true);
      expect(logs.first['logId'], 'W001');
    });

    test('fetchNutritionLogs returns nutrition log list', () async {
      final logs = await fetchNutritionLogs();
      expect(logs, isA<List<Map<String, dynamic>>>());
      expect(logs.isNotEmpty, true);
      expect(logs.first['mealId'], 'N023');
    });

    test('fetchGamification returns gamification data', () async {
      final gamification = await fetchGamification();
      expect(gamification['userId'], 'U12345');
      expect(gamification['streakDays'], 7);
      expect(gamification['level'], 3);
    });

    test('fetchRecommendations returns recommendation data', () async {
      final recommendations = await fetchRecommendations();
      expect(recommendations['userId'], 'U12345');
      expect(recommendations['recommendedWorkouts'], isA<List>());
      expect(recommendations['recommendedMeals'], isA<List>());
    });

    test('saveUserProfile updates mock profile', () async {
      await saveUserProfile({'name': 'Updated Name', 'age': 30});
      expect(mockUserProfile['name'], 'Updated Name');
      expect(mockUserProfile['age'], 30);
    });

    test('addWorkoutLog prepends new log', () async {
      final initialLength = mockWorkoutLogs.length;
      final newLog = {
        'logId': 'W999',
        'userId': 'U12345',
        'date': '2025-11-14',
        'workoutName': 'Test Workout',
      };
      await addWorkoutLog(newLog);
      expect(mockWorkoutLogs.length, initialLength + 1);
      expect(mockWorkoutLogs.first['logId'], 'W999');
    });

    test('addNutritionLog prepends new meal', () async {
      final initialLength = mockNutritionLogs.length;
      final newMeal = {
        'mealId': 'N999',
        'userId': 'U12345',
        'date': '2025-11-14',
        'mealType': 'Snack',
      };
      await addNutritionLog(newMeal);
      expect(mockNutritionLogs.length, initialLength + 1);
      expect(mockNutritionLogs.first['mealId'], 'N999');
    });
  });
}
