import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:cache_me_if_you_can/mock/mock_data.dart' show fetchUserProfile;

// Direct FastAPI endpoint used for local development
final String mlServiceEndpoint = _resolveMlServiceEndpoint();
const Duration _requestTimeout = Duration(seconds: 20);

String _resolveMlServiceEndpoint() {
  if (kIsWeb) {
    return 'http://localhost:8000/nutrition/generate';
  }
  if (Platform.isAndroid) {
    // Android emulator cannot reach host loopback, use special alias
    return 'http://10.0.2.2:8000/nutrition/generate';
  }
  if (Platform.isIOS) {
    return 'http://localhost:8000/nutrition/generate';
  }
  if (Platform.isWindows) {
    return 'http://localhost:8000/nutrition/generate';
  }
  if (Platform.isMacOS || Platform.isLinux) {
    return 'http://localhost:8000/nutrition/generate';
  }
  return 'http://localhost:8000/nutrition/generate';
}

class NutritionRecommendationPage extends StatefulWidget {
  const NutritionRecommendationPage({super.key});

  @override
  State<NutritionRecommendationPage> createState() => _NutritionRecommendationPageState();
}

class _NutritionRecommendationPageState extends State<NutritionRecommendationPage> {
  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  int selectedDayIndex = 0;
  Map<String, dynamic> weekPlan = {};
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final currentDay = days[selectedDayIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButton<int>(
                value: selectedDayIndex,
                items: List.generate(days.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(days[index]),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDayIndex = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (weekPlan.isNotEmpty)
                ..._buildDayMeals(currentDay)
              else
                const Text('No data yet.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loading ? null : _fetchWeekPlan,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Get Recommendations'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern nutrient chip widget (reusable)
  Widget _nutrientChip(String label, dynamic value, Color? color, {String suffix = ''}) {
    String displayValue;
    if (value == null) {
      displayValue = 'N/A';
    } else if (value is num) {
      displayValue = value.toInt().toString();
    } else {
      displayValue = value.toString();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFB0BEC5), // Matte blue-grey
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$label: $displayValue$suffix',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
      ),
    );
  }

  // Section header for nutrition
  Widget _NutritionSectionHeader({required IconData icon, required String title, required Color tint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // Section card for nutrition
  Widget _NutritionSectionCard({required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }

  // Reusable meal card component
  Widget _mealCard({
    required String mealType,
    required IconData icon,
    required Map recipe,
    required Map targets,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFF90A4AE), // Matte blue-grey, bolder
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(recipe['name'] ?? 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _nutrientChip('Cals', recipe['calories'], const Color(0xFFB0BEC5)),
                  const SizedBox(width: 8),
                  _nutrientChip('P', recipe['protein_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                  const SizedBox(width: 8),
                  _nutrientChip('C', recipe['carbs_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                  const SizedBox(width: 8),
                  _nutrientChip('F', recipe['fat_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                ],
              ),
            ),
            const Divider(height: 18, thickness: 1, color: Colors.white24),
            Text('Targets:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _nutrientChip('Cals', targets['calories'], const Color(0xFFB0BEC5)),
                  const SizedBox(width: 8),
                  _nutrientChip('P', targets['protein_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                  const SizedBox(width: 8),
                  _nutrientChip('C', targets['carbs_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                  const SizedBox(width: 8),
                  _nutrientChip('F', targets['fat_g'], const Color(0xFFB0BEC5), suffix: 'g'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayMeals(String day) {
    final color = Theme.of(context).colorScheme;
    final meals = weekPlan[day] ?? {};
    final mealMap = meals['meals'] ?? {};
    final totalNutrition = meals['total_nutrition'] ?? {};
    final mealTypes = [
      {'key': 'breakfast', 'icon': Icons.wb_sunny, 'label': 'Breakfast'},
      {'key': 'lunch', 'icon': Icons.lunch_dining, 'label': 'Lunch'},
      {'key': 'dinner', 'icon': Icons.nightlife, 'label': 'Dinner'},
      {'key': 'snacks', 'icon': Icons.fastfood, 'label': 'Snacks'},
    ];

    List<Widget> widgets = [];

    // Top: Total Nutrition
    widgets.add(_NutritionSectionHeader(
      icon: Icons.bar_chart,
      title: 'Total Nutrition',
      tint: color.primary,
    ));
    widgets.add(_NutritionSectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _nutrientChip('Calories', totalNutrition['calories'], color.primaryContainer),
          _nutrientChip('Protein', totalNutrition['protein_g'], color.secondaryContainer, suffix: 'g'),
          _nutrientChip('Carbs', totalNutrition['carbs_g'], color.tertiaryContainer, suffix: 'g'),
          _nutrientChip('Fat', totalNutrition['fat_g'], color.errorContainer, suffix: 'g'),
        ],
      ),
    ));

    // Each meal block
    for (final mealType in mealTypes) {
      final type = mealType['key'] as String;
      final recipe = mealMap[type]?['recipe'] ?? {};
      final targets = mealMap[type]?['targets'] ?? {};
      // Remove outside meal section header for each meal block
      // widgets.add(_NutritionSectionHeader(
      //   icon: mealType['icon'] as IconData,
      //   title: mealType['label'] as String,
      //   tint: color.secondary,
      // ));
      widgets.add(_NutritionSectionCard(
        child: Container(
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.primary, width: 2), // Use icon blue for border
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mealType['icon'] as IconData, color: color.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    mealType['label'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  recipe['name'] ?? 'N/A',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _nutrientChip('Cals', recipe['calories'], const Color(0xFFE57373)), // Soft red
                  _nutrientChip('P', recipe['protein_g'], const Color(0xFF81C784), suffix: 'g'), // Soft green
                  _nutrientChip('C', recipe['carbs_g'], const Color(0xFFFFF176), suffix: 'g'), // Soft yellow
                  _nutrientChip('F', recipe['fat_g'], const Color(0xFF64B5F6), suffix: 'g'), // Soft blue
                ],
              ),
              const Divider(height: 18, thickness: 1),
              Text('Targets:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _nutrientChip('Cals', targets['calories'], const Color(0xFFE57373)),
                  _nutrientChip('P', targets['protein_g'], const Color(0xFF81C784), suffix: 'g'),
                  _nutrientChip('C', targets['carbs_g'], const Color(0xFFFFF176), suffix: 'g'),
                  _nutrientChip('F', targets['fat_g'], const Color(0xFF64B5F6), suffix: 'g'),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    return widgets;
  }

  Future<void> _fetchWeekPlan() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      //print('FetchWeekPlan: current user: \${user?.uid}, email: \${user?.email}');
      final userId = user?.uid;
      if (userId == null) {
        setState(() {
          weekPlan = {};
        });
        _showSnack('User not logged in');
        return;
      }
      //print('Calling ML service directly for user $userId');
      final payload = await _buildMlPayload(userId);
      debugPrint('Nutrition payload: $payload');

      final response = await http
          .post(
            Uri.parse(mlServiceEndpoint),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          weekPlan = Map<String, dynamic>.from(
            data['week_plan'] ?? data['weekPlan'] ?? const <String, dynamic>{},
          );
        });
      } else {
        setState(() {
          weekPlan = {};
        });
        _showSnack('Error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown'}');
      }
    } on TimeoutException {
      setState(() {
        weekPlan = {};
      });
      _showSnack('Nutrition service timed out. Is FastAPI running on port 8000?');
    } catch (e) {
      setState(() {
        weekPlan = {};
      });
      _showSnack('Request failed: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<Map<String, dynamic>> _buildMlPayload(String uid) async {
    Map<String, dynamic>? firestoreData;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      firestoreData = snapshot.data();
    } catch (e, stack) {
      debugPrint('Failed to load Firestore profile: $e\n$stack');
    }

    firestoreData ??= await fetchUserProfile();
    return _transformUserData(firestoreData);
  }

  Map<String, dynamic> _transformUserData(Map<String, dynamic> source) {
    final heightIn = _deriveHeightInches(source);
    final weightLb = _deriveWeightPounds(source);
    final age = _deriveAge(source);
    final gender = _deriveGender(source);
    final activity = _deriveActivityLevel(source);
    final goal = _deriveGoal(source);
    final allergies = _stringListFrom(source['allergies']);
    final prefs = _stringListFrom(source['preferences']);

    return {
      'Height_in': heightIn,
      'Weight_lb': weightLb,
      'Age': age,
      'Gender': gender,
      'Activity_Level': activity,
      'Goal': goal,
      'allergies': allergies,
      'preferences': prefs,
    };
  }

  double _deriveHeightInches(Map<String, dynamic> data) {
    final direct = _toDouble(data['Height_in']);
    if (direct != null && direct > 0) return direct;

    final cm = _toDouble(data['height_cm'] ?? data['Height_cm']);
    if (cm != null && cm > 0) return cm / 2.54;

    final fallback = _toDouble(data['height'] ?? data['height_in']);
    if (fallback != null && fallback > 0) return fallback;

    return 68; // reasonable default
  }

  double _deriveWeightPounds(Map<String, dynamic> data) {
    final direct = _toDouble(data['Weight_lb'] ?? data['weight_lb']);
    if (direct != null && direct > 0) return direct;

    final kg = _toDouble(data['Weight_kg'] ?? data['weight_kg']);
    if (kg != null && kg > 0) return kg * 2.20462;

    final raw = _toDouble(data['weight']);
    if (raw != null && raw > 0) {
      final usesMetric = data['units_metric'] == true;
      if (usesMetric || raw < 120) {
        return raw * 2.20462;
      }
      return raw;
    }

    return 180;
  }

  int _deriveAge(Map<String, dynamic> data) {
    final raw = data['Age'] ?? data['age'];
    if (raw is num && raw > 0) return raw.toInt();
    return 25;
  }

  int _deriveGender(Map<String, dynamic> data) {
    final raw = data['Gender'] ?? data['gender'];
    if (raw is int && (raw == 0 || raw == 1)) {
      return raw;
    }
    if (raw is String) {
      final normalized = raw.toLowerCase();
      if (normalized.startsWith('f')) return 0;
      if (normalized.startsWith('m')) return 1;
    }
    return 1; // default to male to match server expectations
  }

  int _deriveActivityLevel(Map<String, dynamic> data) {
    final raw = data['Activity_Level'];
    if (raw is int && raw >= 0 && raw <= 4) return raw;

    final multiplier = _toDouble(data['activity_level'] ?? raw);
    if (multiplier == null) return 2;

    if (multiplier <= 1.2) return 0;
    if (multiplier <= 1.375) return 1;
    if (multiplier <= 1.55) return 2;
    if (multiplier <= 1.725) return 3;
    return 4;
  }

  int _deriveGoal(Map<String, dynamic> data) {
    final raw = data['Goal'] ?? data['goal'] ?? data['weight_objective'];
    if (raw is int && raw >= -1 && raw <= 1) {
      return raw;
    }
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case 'lose':
        case 'weight_loss':
        case 'lose_weight':
          return -1;
        case 'maintain':
        case 'maintain_weight':
          return 0;
        case 'gain':
        case 'gain_weight':
        case 'build_muscle':
          return 1;
      }
    }
    return 0;
  }

  List<String> _stringListFrom(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).cast<String>().toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(RegExp(r'[;,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}