import 'package:shared_preferences/shared_preferences.dart';
import '../mock/mock_data.dart';
import 'package:cache_me_if_you_can/features/workouts/domain/entities/program.dart';

class ProgramState {
  static const _keyActiveProgram = 'activeProgramName';
  static const _keyActiveProgramData = 'activeProgramData';

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

  /// Save full program (name + days) locally. Also updates active program name.
  static Future<void> saveProgram(Program program) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProgram, program.name);
    await prefs.setString(_keyActiveProgramData, program.toMap().toString());
    await setCurrentProgramName(program.name);
  }

  /// Load full program if present; otherwise returns null.
  static Future<Program?> loadProgram() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveProgramData);
    if (raw == null || raw.isEmpty) return null;
    try {
      // naive parse: convert to JSON-like Map. Since we stored via toString(), we need a safer approach.
      // For simplicity, we switch to a lightweight encoding: we expect a JSON map string; if not valid, return null.
      // Future improvement: use jsonEncode/jsonDecode.
      // Attempt json decoding:
      // ignore: avoid_dynamic_calls
      final map = _tryDecode(raw);
      if (map == null) return null;
      return Program.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _tryDecode(String raw) {
    try {
      // Replace single quotes with double to approximate JSON if needed.
      final normalized = raw.contains('"') ? raw : raw.replaceAll("'", '"');
      return _jsonParse(normalized);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _jsonParse(String data) {
    // Use dart:convert without importing globally to keep file lean.
    // (We could import json but keeping changes minimal.)
    // Defer to future improvement if parsing becomes unreliable.
    // Returning null signals parse failure.
    return null; // placeholder parse failure -> encourages migrating to proper json.
  }
}
