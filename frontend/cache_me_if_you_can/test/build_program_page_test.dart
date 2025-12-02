import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/build_program_page.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  testWidgets('BuildProgramPage saves entered name and updates ProgramState', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    mockdata.mockCurrentProgramName = 'Beginner Full Body (Week 3)';

    // App wrapper with a button to open BuildProgramPage so Navigator.pop works
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
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Open the page
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Enter program name
    const entered = 'Widget Test Program';
    await tester.enterText(find.byType(TextField), entered);
    await tester.pumpAndSettle();

    // Tap Save button (find by text)
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify SharedPreferences and mock backend updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('activeProgramName'), entered);
    expect(mockdata.mockCurrentProgramName, entered);
  });
}
