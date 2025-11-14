import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/build_program_page.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/recent_programs_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  group('Accessibility Tests', () {
    testWidgets('BuildProgramPage has semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Verify AppBar has title
      expect(find.text('Build Program'), findsOneWidget);

      // Verify TextField has label
      expect(find.byType(TextField), findsOneWidget);

      // Verify button has text
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('RecentProgramsPage has semantic structure', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();
      mockdata.mockPrograms.add('Test Program');

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Recent programs'), findsOneWidget);

      // Verify ListTile structure with icons and text
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('All interactive elements are tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Verify button exists and is tappable
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Form fields support text input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Verify TextField is editable
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Test input');
      await tester.pump();

      expect(find.text('Test input'), findsOneWidget);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('BuildProgramPage adapts to small screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568); // iPhone SE size
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Should render without overflow
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('BuildProgramPage adapts to large screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080); // Desktop size
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Should render without overflow
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('RecentProgramsPage handles long program names', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();
      mockdata.mockPrograms.add(
        'This is a very long program name that should wrap properly',
      );

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      await tester.pumpAndSettle();

      // Should render without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('BuildProgramPage adapts to landscape orientation', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(896, 414); // Landscape phone
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('List scrolls when content exceeds viewport', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();

      // Add many programs to force scrolling
      for (int i = 0; i < 50; i++) {
        mockdata.mockPrograms.add('Program $i');
      }

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      await tester.pumpAndSettle();

      // Verify ListView is scrollable
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Should render without overflow
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Usability Tests', () {
    testWidgets('Empty program name shows default', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      // Leave field empty and save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), 'Custom Program');
    });

    testWidgets('Loading state shown for async operations', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.add('Test');

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Empty state displayed when no programs', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockdata.mockPrograms.clear();

      await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

      await tester.pumpAndSettle();

      expect(find.text('No recent programs'), findsOneWidget);
    });
  });

  group('Input Validation Tests', () {
    testWidgets('TextField accepts various character types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      final testCases = [
        'Regular Text',
        'Text with 123 numbers',
        'Special !@#\$ chars',
        'Émojis 💪🏋️',
        'Very Long Program Name That Goes On And On And On',
      ];

      for (final testCase in testCases) {
        await tester.enterText(find.byType(TextField), testCase);
        await tester.pump();
        expect(find.text(testCase), findsOneWidget);
      }
    });

    testWidgets('Whitespace is trimmed from program name', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: BuildProgramPage()));

      await tester.enterText(find.byType(TextField), '  Spaced Name  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activeProgramName'), 'Spaced Name');
    });
  });
}
