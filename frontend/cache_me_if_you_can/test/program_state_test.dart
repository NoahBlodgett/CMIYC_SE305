import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cache_me_if_you_can/utils/program_state.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mockdata;

void main() {
  group('ProgramState', () {
    setUp(() async {
      // start each test with clean SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // reset mock backend value
      mockdata.mockCurrentProgramName = 'Beginner Full Body (Week 3)';
    });

    test(
      'saveActiveProgramName writes to SharedPreferences and mock backend',
      () async {
        await ProgramState.saveActiveProgramName('My Test Program');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('activeProgramName'), 'My Test Program');
        expect(mockdata.mockCurrentProgramName, 'My Test Program');
      },
    );

    test('loadActiveProgramName reads stored value when present', () async {
      SharedPreferences.setMockInitialValues({'activeProgramName': 'Saved'});
      final value = await ProgramState.loadActiveProgramName();
      expect(value, 'Saved');
    });

    test(
      'loadActiveProgramName falls back to mock fetch when missing',
      () async {
        // prefs empty, mockCurrentProgramName should be used
        SharedPreferences.setMockInitialValues({});
        mockdata.mockCurrentProgramName = 'Mock Fallback Program';

        final value = await ProgramState.loadActiveProgramName();
        expect(value, 'Mock Fallback Program');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('activeProgramName'), 'Mock Fallback Program');
      },
    );
  });
}
