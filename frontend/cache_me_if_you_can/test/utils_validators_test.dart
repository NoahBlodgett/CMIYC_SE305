import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/utils/validators.dart';

void main() {
  group('validators', () {
    test('requiredValidator', () {
      expect(requiredValidator(null), 'Required');
      expect(requiredValidator(''), 'Required');
      expect(requiredValidator('  '), 'Required');
      expect(requiredValidator('ok'), isNull);
    });

    test('positiveIntValidator', () {
      expect(positiveIntValidator(''), 'Required');
      expect(positiveIntValidator('0'), 'Must be a positive number');
      expect(positiveIntValidator('-1'), 'Must be a positive number');
      expect(positiveIntValidator('abc'), 'Must be a positive number');
      expect(positiveIntValidator('5'), isNull);
    });

    test('positiveDoubleValidator', () {
      expect(positiveDoubleValidator(''), 'Required');
      expect(positiveDoubleValidator('0'), 'Must be > 0');
      expect(positiveDoubleValidator('-1.2'), 'Must be > 0');
      expect(positiveDoubleValidator('abc'), 'Must be > 0');
      expect(positiveDoubleValidator('1.5'), isNull);
    });
  });
}
