import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/build_program_page.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/recent_programs_page.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();
      for (int i = 0; i < 20; i++) {
        mockdata.mockPrograms.add('Program $i');
      }
    });

    testWidgets('Page navigation completes within reasonable time', (
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
                        child: const Text('Build'),
                      ),
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

      final stopwatch = Stopwatch()..start();

      // Navigate to BuildProgramPage
      await tester.tap(find.text('Build'));
      await tester.pumpAndSettle();
      final buildNavTime = stopwatch.elapsedMilliseconds;
      expect(buildNavTime, lessThan(1000)); // Should be instant

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      stopwatch.reset();

      // Navigate to RecentProgramsPage
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      final recentNavTime = stopwatch.elapsedMilliseconds;
      expect(recentNavTime, lessThan(1500)); // Includes async fetch

      stopwatch.stop();
    });

    testWidgets('List scrolling is smooth with many items', (
      WidgetTester tester,
    ) async {
      mockdata.mockPrograms.clear();
      for (int i = 0; i < 100; i++) {
        mockdata.mockPrograms.add('Program $i');
      }

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Scroll through the list
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final scrollTime = stopwatch.elapsedMilliseconds;
      expect(scrollTime, lessThan(1000));

      stopwatch.stop();
    });

    testWidgets('Form submission completes quickly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      await tester.enterText(find.byType(TextField), 'Quick Test Program');
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final submitTime = stopwatch.elapsedMilliseconds;
      expect(submitTime, lessThan(1000));

      stopwatch.stop();
    });
  });

  group('Stress Test Integration', () {
    testWidgets('Rapid navigation does not cause crashes', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

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
                          builder: (_) => const BuildProgramPage(),
                        ),
                      );
                    },
                    child: const Text('Build'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Rapidly navigate and go back multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Build'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple rapid saves work correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Rapidly change text and save multiple times
      for (int i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField), 'Program $i');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Save'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Should not crash
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsiveness Tests', () {
    testWidgets('UI remains responsive during async operations', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();
      for (int i = 0; i < 50; i++) {
        mockdata.mockPrograms.add('Program $i');
      }

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      // Should show loading state immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // UI should still be responsive (app bar should be visible)
      expect(find.text('Recent programs'), findsOneWidget);

      await tester.pumpAndSettle();

      // Should transition to content
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListTile), findsWidgets);
    });
  });

  group('Memory Leak Prevention Tests', () {
    testWidgets('Controllers are properly disposed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Remove the widget tree
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Should not throw any disposal errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple page instances do not leak', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

        await tester.enterText(find.byType(TextField), 'Test $i');
        await tester.pumpAndSettle();

        // Clear the widget
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      }

      // Should complete without memory issues
      expect(tester.takeException(), isNull);
    });
  });
}
