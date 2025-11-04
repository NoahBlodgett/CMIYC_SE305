import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/utils/units.dart';

void main() {
  group('units', () {
    test('inchesFromFeetInches', () {
      expect(inchesFromFeetInches(5, 6), 66);
      expect(inchesFromFeetInches(0, 0), 0);
      expect(inchesFromFeetInches(6, 0), 72);
    });

    test('inchesFromCm', () {
      expect(inchesFromCm(170), 67); // 170cm ≈ 66.9in
      expect(inchesFromCm(0), 0);
      expect(inchesFromCm(254), 100);
    });
  });
}
