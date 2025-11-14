import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/features/workouts/data/services/met_calorie_service.dart';

void main() {
  final svc = MetCalorieService.instance;

  group('getMet single value', () {
    test('returns exact MET for sleeping', () {
      expect(svc.getMet('sleeping'), 0.9);
    });

    test('normalizes key casing/spaces', () {
      expect(svc.getMet('Sleeping'), 0.9);
    });
  });

  group('getMet range handling', () {
    test('midpoint default for jump rope', () {
      // jump_rope range 9.8–12.3 => midpoint (9.8+12.3)/2 = 11.05
      expect(svc.getMet('jump_rope')!.toStringAsFixed(2), '11.05');
    });
    test('min for jump rope', () {
      expect(svc.getMet('jump_rope', rangeMode: MetRangeMode.min), 9.8);
    });
    test('max for jump rope', () {
      expect(svc.getMet('jump_rope', rangeMode: MetRangeMode.max), 12.3);
    });
  });

  group('caloriesBurned formula', () {
    test('calculates expected calories for running_6_8_mph', () {
      // MET 11.2, weight 70kg, duration 30min
      // Calories = 11.2 * 3.5 * 70 * 30 / 200
      final expected = 11.2 * 3.5 * 70 * 30 / 200.0;
      final actual = svc.caloriesBurned(
        activityKey: 'running_6_8_mph',
        weightKg: 70,
        durationMinutes: 30,
      );
      expect((actual - expected).abs() < 0.0001, true);
    });

    test('returns 0 for unknown activity', () {
      final cals = svc.caloriesBurned(
        activityKey: 'made_up_activity',
        weightKg: 70,
        durationMinutes: 30,
      );
      expect(cals, 0);
    });

    test('returns 0 for non-positive weight or duration', () {
      expect(svc.caloriesBurned(activityKey: 'sleeping', weightKg: 0, durationMinutes: 30), 0);
      expect(svc.caloriesBurned(activityKey: 'sleeping', weightKg: 70, durationMinutes: 0), 0);
      expect(svc.caloriesBurned(activityKey: 'sleeping', weightKg: -1, durationMinutes: 30), 0);
    });
  });

  group('suggestKeys', () {
    test('suggests matching substring keys', () {
      final suggestions = svc.suggestKeys('run');
      expect(suggestions.any((s) => s.startsWith('running_4_0_mph')), true);
      expect(suggestions.any((s) => s.startsWith('running_6_8_mph')), true);
    });

    test('limits number of suggestions', () {
      final suggestions = svc.suggestKeys('running', maxSuggestions: 2);
      expect(suggestions.length <= 2, true);
    });

    test('returns empty list when no match', () {
      final suggestions = svc.suggestKeys('zzzzzz');
      expect(suggestions, isEmpty);
    });
  });
}
