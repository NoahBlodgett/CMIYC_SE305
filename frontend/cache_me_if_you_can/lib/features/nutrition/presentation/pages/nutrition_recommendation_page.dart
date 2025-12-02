import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// TODO: REMOVE HARDCODED BACKEND URL WHEN DEPLOYING OR USING EMULATOR
const String backendBaseUrl = 'http://localhost:5001/se-305-db/us-central1/api';
// END HARDCODED BACKEND URL

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
      print('FetchWeekPlan: current user: \\${user?.uid}, email: \\${user?.email}');
      final userId = user?.uid;
      if (userId == null) {
        setState(() { weekPlan = {}; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }
  final idToken = await user!.getIdToken();
  print('Firebase ID Token: $idToken');
      final url = '$backendBaseUrl/meals/$userId/generateWeekPlan';
      print('Calling backend URL: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The meal plan is under data['mealPlan']['week_plan']
        setState(() {
          weekPlan = Map<String, dynamic>.from(data['mealPlan']['week_plan'] ?? {});
        });
      } else {
        setState(() { weekPlan = {}; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode} ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      setState(() { weekPlan = {}; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }
}