import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/utils/validators.dart';

void main() {
  group('Email Validator', () {
    String? emailValidator(String? v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!rx.hasMatch(v.trim())) return 'Invalid email';
      return null;
    }

    test('returns error for null input', () {
      expect(emailValidator(null), 'Required');
    });

    test('returns error for empty string', () {
      expect(emailValidator(''), 'Required');
    });

    test('returns error for whitespace only', () {
      expect(emailValidator('   '), 'Required');
    });

    test('returns error for invalid email format - no @', () {
      expect(emailValidator('invalidemail.com'), 'Invalid email');
    });

    test('returns error for invalid email format - no domain', () {
      expect(emailValidator('user@'), 'Invalid email');
    });

    test('returns error for invalid email format - no TLD', () {
      expect(emailValidator('user@domain'), 'Invalid email');
    });

    test('returns null for valid email', () {
      expect(emailValidator('user@example.com'), isNull);
    });

    test('returns null for valid email with subdomain', () {
      expect(emailValidator('user@mail.example.com'), isNull);
    });

    test('returns null for valid email with plus sign', () {
      expect(emailValidator('user+tag@example.com'), isNull);
    });
  });

  group('Password Validator', () {
    String? passwordValidator(String? v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      if (v.length < 6) return 'Min 6 chars';
      return null;
    }

    test('returns error for null input', () {
      expect(passwordValidator(null), 'Required');
    });

    test('returns error for empty string', () {
      expect(passwordValidator(''), 'Required');
    });

    test('returns error for password too short', () {
      expect(passwordValidator('12345'), 'Min 6 chars');
    });

    test('returns null for password exactly 6 chars', () {
      expect(passwordValidator('123456'), isNull);
    });

    test('returns null for password longer than 6 chars', () {
      expect(passwordValidator('password123'), isNull);
    });
  });

  group('Existing Validators', () {
    test('requiredValidator edge cases', () {
      expect(requiredValidator('0'), isNull);
      expect(requiredValidator('false'), isNull);
      expect(requiredValidator('\t\n'), 'Required');
    });

    test('positiveIntValidator edge cases', () {
      expect(positiveIntValidator('1'), isNull);
      expect(positiveIntValidator('999'), isNull);
      expect(positiveIntValidator('1.5'), 'Must be a positive number');
      expect(positiveIntValidator(' 5 '), isNull);
    });

    test('positiveDoubleValidator edge cases', () {
      expect(positiveDoubleValidator('0.1'), isNull);
      expect(positiveDoubleValidator('0.0001'), isNull);
      expect(positiveDoubleValidator('1'), isNull);
      expect(positiveDoubleValidator('999.99'), isNull);
      expect(positiveDoubleValidator('-0.1'), 'Must be > 0');
    });
  });
}
