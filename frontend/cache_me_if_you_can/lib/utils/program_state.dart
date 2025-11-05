import 'package:shared_preferences/shared_preferences.dart';
import '../mock/mock_data.dart';

class ProgramState {
  static const _keyActiveProgram = 'activeProgramName';

  /// Load the active program from local storage. Falls back to mock if missing.
  static Future<String?> loadActiveProgramName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyActiveProgram);
    if (stored != null && stored.isNotEmpty) return stored;
    // Fallback to mock
    final name = await fetchCurrentProgramName();
    if (name.isNotEmpty) {
      await prefs.setString(_keyActiveProgram, name);
      return name;
    }
    return null;
  }

  /// Save the active program to both local storage and mock backend.
  static Future<void> saveActiveProgramName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProgram, name);
    await setCurrentProgramName(name);
  }
}
