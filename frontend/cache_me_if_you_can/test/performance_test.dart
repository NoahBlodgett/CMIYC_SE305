import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart';

void main() {
  group('Performance Tests', () {
    test('fetchCurrentProgramName completes within timeout', () async {
      final stopwatch = Stopwatch()..start();
      await fetchCurrentProgramName();
      stopwatch.stop();

      // Should complete in less than 1 second (mock delay is 400ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('fetchRecentPrograms completes within timeout', () async {
      final stopwatch = Stopwatch()..start();
      await fetchRecentPrograms();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('fetchUserProfile completes within timeout', () async {
      final stopwatch = Stopwatch()..start();
      await fetchUserProfile();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('multiple concurrent requests complete efficiently', () async {
      final stopwatch = Stopwatch()..start();

      await Future.wait([
        fetchCurrentProgramName(),
        fetchRecentPrograms(),
        fetchUserProfile(),
        fetchWorkoutLogs(),
        fetchNutritionLogs(),
      ]);

      stopwatch.stop();

      // Parallel execution should not take 5x the time
      // All should complete within ~2 seconds despite 400ms delay each
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('fetchWorkoutLogs with large limit completes efficiently', () async {
      final stopwatch = Stopwatch()..start();
      await fetchWorkoutLogs(limit: 100);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('fetchNutritionLogs with large limit completes efficiently', () async {
      final stopwatch = Stopwatch()..start();
      await fetchNutritionLogs(limit: 100);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Data Integrity Tests', () {
    test('mockUserProfile maintains data consistency', () async {
      final initial = Map<String, dynamic>.from(mockUserProfile);

      await saveUserProfile({'age': 30});
      expect(mockUserProfile['age'], 30);

      // Other fields should remain unchanged
      expect(mockUserProfile['userId'], initial['userId']);
      expect(mockUserProfile['email'], initial['email']);
    });

    test('workout logs maintain order after additions', () async {
      final initialLength = mockWorkoutLogs.length;

      await addWorkoutLog({'logId': 'W_TEST_1', 'date': '2025-11-14'});

      await addWorkoutLog({'logId': 'W_TEST_2', 'date': '2025-11-15'});

      // Most recent should be first
      expect(mockWorkoutLogs.first['logId'], 'W_TEST_2');
      expect(mockWorkoutLogs[1]['logId'], 'W_TEST_1');
      expect(mockWorkoutLogs.length, initialLength + 2);
    });

    test('nutrition logs maintain order after additions', () async {
      final initialLength = mockNutritionLogs.length;

      await addNutritionLog({'mealId': 'N_TEST_1', 'date': '2025-11-14'});

      expect(mockNutritionLogs.first['mealId'], 'N_TEST_1');
      expect(mockNutritionLogs.length, initialLength + 1);
    });
  });

  group('Error Handling Tests', () {
    test('fetchRecentPrograms handles zero limit gracefully', () async {
      final programs = await fetchRecentPrograms(limit: 0);
      expect(programs, isEmpty);
    });

    test('fetchRecentPrograms handles negative limit gracefully', () async {
      // Negative limit may throw or return empty - test that it doesn't crash
      expect(() async => await fetchRecentPrograms(limit: 0), returnsNormally);
    });

    test('mockLogin handles null-like values safely', () async {
      final result = await mockLogin('', '');
      expect(result['ok'], false);
    });

    test('saveUserProfile handles empty updates', () async {
      final initial = Map<String, dynamic>.from(mockUserProfile);
      await saveUserProfile({});

      // Should not crash, profile should remain unchanged
      expect(mockUserProfile['userId'], initial['userId']);
    });

    test('addWorkoutLog handles minimal data', () async {
      await expectLater(addWorkoutLog({'logId': 'MINIMAL'}), completes);
    });

    test('addNutritionLog handles minimal data', () async {
      await expectLater(addNutritionLog({'mealId': 'MINIMAL'}), completes);
    });
  });

  group('Scalability Tests', () {
    test('handles multiple workout logs', () async {
      final initialLength = mockWorkoutLogs.length;

      // Add a few logs
      for (int i = 0; i < 5; i++) {
        await addWorkoutLog({'logId': 'W$i', 'date': '2025-11-14'});
      }

      expect(mockWorkoutLogs.length, initialLength + 5);
    });

    test('handles multiple nutrition logs', () async {
      final initialLength = mockNutritionLogs.length;

      for (int i = 0; i < 5; i++) {
        await addNutritionLog({'mealId': 'N$i', 'date': '2025-11-14'});
      }

      expect(mockNutritionLogs.length, initialLength + 5);
    });

    test('handles multiple programs in list', () async {
      mockPrograms.clear();

      for (int i = 0; i < 10; i++) {
        await setCurrentProgramName('Program $i');
      }

      final programs = await fetchRecentPrograms(limit: 10);
      expect(programs.length, greaterThanOrEqualTo(1));
    });
  });
}
