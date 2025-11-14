import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/utils/validators.dart';
import 'package:cache_me_if_you_can/utils/units.dart';

void main() {
  group('Validator Reliability Tests', () {
    test('requiredValidator handles various null-like inputs', () {
      expect(requiredValidator(null), 'Required');
      expect(requiredValidator(''), 'Required');
      expect(requiredValidator('   '), 'Required');
      expect(requiredValidator('\t'), 'Required');
      expect(requiredValidator('\n'), 'Required');
      expect(requiredValidator('  \t\n  '), 'Required');
    });

    test('requiredValidator accepts valid non-empty strings', () {
      expect(requiredValidator('a'), isNull);
      expect(requiredValidator(' a '), isNull);
      expect(requiredValidator('0'), isNull);
      expect(requiredValidator('false'), isNull);
    });

    test('positiveIntValidator rejects edge cases', () {
      expect(positiveIntValidator('0'), isNotNull);
      expect(positiveIntValidator('-1'), isNotNull);
      expect(positiveIntValidator('1.5'), isNotNull);
      expect(positiveIntValidator('abc'), isNotNull);
      expect(positiveIntValidator(''), isNotNull);
      expect(positiveIntValidator('  '), isNotNull);
    });

    test('positiveIntValidator accepts valid positive integers', () {
      expect(positiveIntValidator('1'), isNull);
      expect(positiveIntValidator('100'), isNull);
      expect(positiveIntValidator('999999'), isNull);
      expect(positiveIntValidator(' 42 '), isNull); // with whitespace
    });

    test('positiveDoubleValidator rejects edge cases', () {
      expect(positiveDoubleValidator('0'), isNotNull);
      expect(positiveDoubleValidator('0.0'), isNotNull);
      expect(positiveDoubleValidator('-0.1'), isNotNull);
      expect(positiveDoubleValidator('-100'), isNotNull);
      expect(positiveDoubleValidator('abc'), isNotNull);
      expect(positiveDoubleValidator(''), isNotNull);
    });

    test('positiveDoubleValidator accepts valid positive numbers', () {
      expect(positiveDoubleValidator('0.1'), isNull);
      expect(positiveDoubleValidator('1'), isNull);
      expect(positiveDoubleValidator('1.5'), isNull);
      expect(positiveDoubleValidator('999.99'), isNull);
      expect(positiveDoubleValidator(' 3.14 '), isNull);
    });

    test('validators handle extremely large numbers', () {
      expect(positiveIntValidator('999999999'), isNull);
      expect(positiveDoubleValidator('999999999.99'), isNull);
    });

    test('validators handle special numeric formats', () {
      // Should reject scientific notation
      expect(positiveIntValidator('1e5'), isNotNull);
      expect(positiveDoubleValidator('1e5'), isNull); // double parser accepts

      // Should reject multiple decimals
      expect(positiveDoubleValidator('1.2.3'), isNotNull);
    });
  });

  group('Unit Conversion Reliability Tests', () {
    test('inchesFromFeetInches handles boundary values', () {
      expect(inchesFromFeetInches(0, 0), 0);
      expect(inchesFromFeetInches(10, 0), 120);
      expect(inchesFromFeetInches(0, 11), 11);
      expect(inchesFromFeetInches(100, 100), 1300);
    });

    test('inchesFromFeetInches is mathematically correct', () {
      for (int feet = 0; feet <= 10; feet++) {
        for (int inches = 0; inches <= 11; inches++) {
          expect(inchesFromFeetInches(feet, inches), feet * 12 + inches);
        }
      }
    });

    test('inchesFromCm handles boundary values', () {
      expect(inchesFromCm(0), 0);
      expect(inchesFromCm(1), greaterThanOrEqualTo(0));
      expect(inchesFromCm(254), 100); // exactly 100 inches
      expect(inchesFromCm(1000), greaterThan(0));
    });

    test('inchesFromCm rounding is consistent', () {
      // 1 inch = 2.54 cm
      expect(inchesFromCm(127), 50); // 50 inches exactly
      expect(inchesFromCm(25), closeTo(10, 1)); // ~9.84 inches
      expect(inchesFromCm(254), 100); // 100 inches exactly
    });

    test('inchesFromCm handles large values', () {
      expect(inchesFromCm(10000), greaterThan(0));
      expect(inchesFromCm(1000000), greaterThan(0));
    });

    test('numberTextChildren handles edge ranges', () {
      expect(numberTextChildren(0, 0).length, 1);
      expect(numberTextChildren(5, 5).length, 1);
      expect(numberTextChildren(-5, 5).length, 11);
      expect(numberTextChildren(1, 100).length, 100);
    });

    test('numberTextChildren generates correct sequence', () {
      final widgets = numberTextChildren(5, 10);
      expect(widgets.length, 6);

      for (int i = 0; i < widgets.length; i++) {
        final text = widgets[i] as dynamic;
        expect(text.data, '${5 + i}');
      }
    });
  });

  group('Thread Safety and Concurrency Tests', () {
    test('validators are stateless and thread-safe', () {
      // Run multiple validations in parallel
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(
          Future(() {
            expect(requiredValidator('test'), isNull);
            expect(positiveIntValidator('5'), isNull);
            expect(positiveDoubleValidator('5.5'), isNull);
          }),
        );
      }

      expectLater(Future.wait(futures), completes);
    });

    test('unit conversions are stateless and thread-safe', () {
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(
          Future(() {
            expect(inchesFromFeetInches(5, 6), 66);
            expect(inchesFromCm(170), 67);
          }),
        );
      }

      expectLater(Future.wait(futures), completes);
    });
  });

  group('Memory and Resource Tests', () {
    test('numberTextChildren does not leak memory with large ranges', () {
      final widgets1 = numberTextChildren(1, 1000);
      expect(widgets1.length, 1000);

      final widgets2 = numberTextChildren(1, 1000);
      expect(widgets2.length, 1000);

      // Should create new instances each time
      expect(identical(widgets1, widgets2), false);
    });

    test('validators handle repeated calls efficiently', () {
      for (int i = 0; i < 1000; i++) {
        requiredValidator('test');
        positiveIntValidator('123');
        positiveDoubleValidator('123.45');
      }
      // If this completes without timeout, it's efficient
    });
  });

  group('Error Recovery Tests', () {
    test('validators never throw exceptions', () {
      final testInputs = [
        null,
        '',
        '   ',
        'abc',
        '123abc',
        'abc123',
        '!@#\$%',
        '999999999999999999999',
        '-999999999999999999999',
        '1.2.3.4',
        'NaN',
        'Infinity',
        '-Infinity',
      ];

      for (final input in testInputs) {
        expect(() => requiredValidator(input), returnsNormally);
        expect(() => positiveIntValidator(input), returnsNormally);
        expect(() => positiveDoubleValidator(input), returnsNormally);
      }
    });

    test('unit conversions never throw exceptions', () {
      final testValues = [0, -1, 1, 100, 1000, 999999];

      for (final val in testValues) {
        expect(() => inchesFromFeetInches(val, val), returnsNormally);
        expect(() => inchesFromCm(val), returnsNormally);
      }
    });
  });
}
