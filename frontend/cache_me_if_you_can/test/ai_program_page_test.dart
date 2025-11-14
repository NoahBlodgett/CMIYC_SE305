import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/ai_program_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  testWidgets('AiProgramPage displays placeholder text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AiProgramPage()));

    expect(find.text('New AI Program'), findsOneWidget);
    expect(
      find.textContaining('placeholder for AI program generation'),
      findsOneWidget,
    );
    expect(find.text('Generate'), findsOneWidget);
  });

  testWidgets('AiProgramPage generate button saves program', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    mockdata.mockCurrentProgramName = 'Default';

    // Wrap with navigator to test pop behavior
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiProgramPage()),
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

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap generate
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    // Verify program was saved
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('activeProgramName'), 'AI Generated Program');
    expect(mockdata.mockCurrentProgramName, 'AI Generated Program');
  });

  testWidgets('AiProgramPage has correct icon on button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AiProgramPage()));

    // Find ElevatedButton with auto_awesome icon
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
