import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/recent_programs_page.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  testWidgets('RecentProgramsPage displays list of programs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    mockdata.mockPrograms.clear();
    mockdata.mockPrograms.addAll(['Program A', 'Program B', 'Program C']);

    await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

    // Should show loading indicator first
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for async data to load
    await tester.pumpAndSettle();

    // Should display all programs
    expect(find.text('Program A'), findsOneWidget);
    expect(find.text('Program B'), findsOneWidget);
    expect(find.text('Program C'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('RecentProgramsPage shows empty state when no programs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    mockdata.mockPrograms.clear();

    await tester.pumpWidget(const MaterialApp(home: RecentProgramsPage()));

    await tester.pumpAndSettle();

    expect(find.text('No recent programs'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('RecentProgramsPage saves selected program and pops', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    mockdata.mockPrograms.clear();
    mockdata.mockPrograms.add('Selected Program');

    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const RecentProgramsPage(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the program
    await tester.tap(find.text('Selected Program'));
    await tester.pumpAndSettle();

    // Verify it saved and returned the name
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('activeProgramName'), 'Selected Program');
    expect(mockdata.mockCurrentProgramName, 'Selected Program');
    expect(result, 'Selected Program');
  });
}
