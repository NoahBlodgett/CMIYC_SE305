import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/services/auth_api.dart';

void main() {
  group('CreateUserRequest', () {
    test('toJson serializes all fields correctly', () {
      final request = CreateUserRequest(
        name: 'John Doe',
        age: 30,
        gender: 'male',
        email: 'john@example.com',
        password: 'password123',
        height: 180.5,
        weight: 75.0,
        allergies: 'peanuts, dairy',
        activityLevel: 3.5,
      );

      final json = request.toJson();

      expect(json['name'], 'John Doe');
      expect(json['age'], 30);
      expect(json['gender'], 'male');
      expect(json['email'], 'john@example.com');
      expect(json['password'], 'password123');
      expect(json['height'], 180.5);
      expect(json['weight'], 75.0);
      expect(json['allergies'], 'peanuts, dairy');
      expect(json['activity_level'], 3.5);
    });

    test('toJson handles null allergies as empty string', () {
      final request = CreateUserRequest(
        name: 'Jane Doe',
        age: 25,
        gender: 'female',
        email: 'jane@example.com',
        password: 'pass456',
        height: 165.0,
        weight: 60.0,
        activityLevel: 2.0,
      );

      final json = request.toJson();

      expect(json['allergies'], '');
    });
  });

  group('CreateUserResponse', () {
    test('constructor initializes all fields', () {
      final response = CreateUserResponse(
        message: 'User created successfully',
        uid: 'uid123',
        user: {'email': 'test@example.com'},
      );

      expect(response.message, 'User created successfully');
      expect(response.uid, 'uid123');
      expect(response.user, {'email': 'test@example.com'});
    });

    test('constructor allows null user data', () {
      final response = CreateUserResponse(message: 'Created', uid: 'uid456');

      expect(response.user, isNull);
    });
  });
}
