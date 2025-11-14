import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:cache_me_if_you_can/utils/units.dart';

void main() {
  group('Height Conversions', () {
    test('inchesFromFeetInches converts correctly', () {
      expect(inchesFromFeetInches(5, 6), 66);
      expect(inchesFromFeetInches(6, 0), 72);
      expect(inchesFromFeetInches(5, 11), 71);
      expect(inchesFromFeetInches(0, 12), 12);
    });

    test('inchesFromFeetInches handles zero values', () {
      expect(inchesFromFeetInches(0, 0), 0);
      expect(inchesFromFeetInches(5, 0), 60);
      expect(inchesFromFeetInches(0, 10), 10);
    });

    test('inchesFromCm converts correctly', () {
      expect(inchesFromCm(170), 67); // ~66.93
      expect(inchesFromCm(180), 71); // ~70.87
      expect(inchesFromCm(254), 100); // exactly 100
    });

    test('inchesFromCm handles edge cases', () {
      expect(inchesFromCm(0), 0);
      expect(inchesFromCm(1), 0); // rounds to 0
      expect(inchesFromCm(2), 1); // ~0.79 rounds to 1
    });

    test('inchesFromCm is consistent with conversion factor', () {
      // 1 inch = 2.54 cm
      const testCm = 127; // 50 inches exactly
      expect(inchesFromCm(testCm), 50);
    });
  });

  group('UI Helpers', () {
    test('numberTextChildren generates correct range', () {
      final widgets = numberTextChildren(1, 5);
      expect(widgets.length, 5);
      expect((widgets[0] as Text).data, '1');
      expect((widgets[4] as Text).data, '5');
    });

    test('numberTextChildren handles single item range', () {
      final widgets = numberTextChildren(7, 7);
      expect(widgets.length, 1);
      expect((widgets[0] as Text).data, '7');
    });

    test('numberTextChildren handles zero to positive range', () {
      final widgets = numberTextChildren(0, 3);
      expect(widgets.length, 4);
      expect((widgets[0] as Text).data, '0');
      expect((widgets[3] as Text).data, '3');
    });

    test('numberTextChildren generates all values in range', () {
      final widgets = numberTextChildren(10, 15);
      expect(widgets.length, 6);
      for (int i = 0; i < 6; i++) {
        expect((widgets[i] as Text).data, '${10 + i}');
      }
    });
  });
}
