import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/build_program_page.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/recent_programs_page.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/ai_program_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multiple Program Creation Workflows', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockCurrentProgramName = 'Initial Program';
      mockdata.mockPrograms.clear();
      mockdata.mockPrograms.addAll([
        'Initial Program',
        'Existing Program 1',
        'Existing Program 2',
      ]);
    });

    testWidgets('Create manual program, then AI program, verify both in list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Test Home')),
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
                        child: const Text('Manual Program'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiProgramPage(),
                            ),
                          );
                        },
                        child: const Text('AI Program'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecentProgramsPage(),
                            ),
                          );
                        },
                        child: const Text('View Recent'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Step 1: Create manual program
      await tester.tap(find.text('Manual Program'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My Manual Workout');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify manual program saved
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), 'My Manual Workout');

      // Step 2: Create AI program
      await tester.tap(find.text('AI Program'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      // Verify AI program saved
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), 'AI Generated Program');

      // Step 3: Open recent programs and verify both appear
      await tester.tap(find.text('View Recent'));
      await tester.pumpAndSettle();

      expect(find.text('AI Generated Program'), findsOneWidget);
      expect(find.text('My Manual Workout'), findsOneWidget);

      // Ensure no lingering focus changes after test completes
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    });

    testWidgets('Navigate between pages without losing state', (
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
                              builder: (_) => const RecentProgramsPage(),
                            ),
                          );
                        },
                        child: const Text('Recent'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open recent programs
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();

      // Count initial programs
      expect(find.byType(ListTile), findsNWidgets(3));

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open again - should still show same count
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    });
  });
}
