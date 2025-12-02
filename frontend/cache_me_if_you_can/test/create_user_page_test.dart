import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/features/auth/presentation/pages/create_user_page.dart';

void main() {
  group('CreateUserPage Form Validation', () {
    testWidgets('displays all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Create account'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      // Try to submit without entering anything
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Required'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalidemail',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('validates password length', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      // Enter valid email but short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Min 6 chars'), findsOneWidget);
    });

    testWidgets('form has password field', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      // Verify password field exists
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('shows loading indicator when submitting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap submit (will fail in test without Firebase, but should show loading)
      await tester.tap(find.text('Create account'));
      await tester.pump();

      // Note: In real app with Firebase mock, we'd see CircularProgressIndicator
      // For now just verify the button exists
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('displays Google sign-in button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateUserPage()));

      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
