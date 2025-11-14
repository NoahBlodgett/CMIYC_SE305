import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/build_program_page.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/recent_programs_page.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Program Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockCurrentProgramName = 'Default Program';
      mockdata.mockPrograms.clear();
      mockdata.mockPrograms.addAll([
        'Beginner Full Body',
        'Intermediate Split',
        'Advanced Strength',
      ]);
    });

    testWidgets('Create new program and verify it appears in recent programs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BuildProgramPage(),
                            ),
                          );
                        },
                        child: const Text('Build Program'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecentProgramsPage(),
                            ),
                          );
                        },
                        child: const Text('Recent Programs'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Step 1: Create a new program
      await tester.tap(find.text('Build Program'));
      await tester.pumpAndSettle();

      const newProgramName = 'My Custom Workout';
      await tester.enterText(find.byType(TextField), newProgramName);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify it was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), newProgramName);

      // Step 2: Open recent programs and verify the new program appears
      await tester.tap(find.text('Recent Programs'));
      await tester.pumpAndSettle();

      expect(find.text(newProgramName), findsOneWidget);
    });

    testWidgets('Select program from recent programs list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecentProgramsPage(),
                        ),
                      );
                    },
                    child: const Text('Open Recent'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Recent'));
      await tester.pumpAndSettle();

      // Select the first program
      await tester.tap(find.text('Beginner Full Body'));
      await tester.pumpAndSettle();

      // Verify it was set as active
      expect(mockdata.mockCurrentProgramName, 'Beginner Full Body');
    });

    testWidgets('Empty name defaults to "Custom Program"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      await tester.pumpAndSettle();

      // Leave the text field empty and tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify default name was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), 'Custom Program');
      expect(mockdata.mockCurrentProgramName, 'Custom Program');
    });
  });
}
