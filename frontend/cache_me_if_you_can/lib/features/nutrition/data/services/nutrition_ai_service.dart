import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/food_entry.dart';

class NutritionAiService {
  final String baseUrl; // e.g. http://localhost:8000 or device LAN IP
  NutritionAiService({required this.baseUrl});

  /// Calls the FastAPI /nutrition/generate endpoint.
  /// Returns a map with targets and a list of preview foods.
  Future<NutritionPlanResult> generatePlan({
    required double heightIn,
    required double weightLb,
    required int age,
    required int gender,
    required int activityLevel,
    required int goal,
    List<String> allergies = const [],
    List<String> preferences = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/nutrition/generate');
    final body = json.encode({
      'Height_in': heightIn,
      'Weight_lb': weightLb,
      'Age': age,
      'Gender': gender,
      'Activity_Level': activityLevel,
      'Goal': goal,
      'allergies': allergies,
      'preferences': preferences,
    });
    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 6));
    if (resp.statusCode != 200) {
      throw Exception('AI planner failed (${resp.statusCode}): ${resp.body}');
    }
    final decoded = json.decode(resp.body) as Map<String, dynamic>;
    final targets = decoded['nutrition_targets'] as Map<String, dynamic>? ?? {};
    final foodsPreview =
        (decoded['foods_preview'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    return NutritionPlanResult(
      nutritionTargets: targets.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      previewFoods: foodsPreview,
      availableFoodsCount:
          decoded['available_foods_count'] as int? ?? foodsPreview.length,
    );
  }

  /// Convert preview food maps into FoodEntry suggestions for a given day/meal.
  List<FoodEntry> toEntries(
    List<Map<String, dynamic>> preview,
    String day,
    String mealType,
  ) {
    return preview.map((m) {
      final name = (m['Food'] ?? m['name'] ?? 'Food').toString();
      final calories = (m['Calories'] as num?)?.toDouble() ?? 0;
      final protein = (m['Protein'] as num?)?.toDouble() ?? 0;
      final carbs = (m['Carbs'] as num?)?.toDouble() ?? 0;
      final fat = (m['Fat'] as num?)?.toDouble() ?? 0;
      return FoodEntry(
        id: '',
        timestamp: DateTime.now(),
        day: day,
        name: name,
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        aiSuggested: true,
        source: 'ai_plan',
      );
    }).toList();
  }
}

class NutritionPlanResult {
  final Map<String, double> nutritionTargets; // whatever model returns
  final List<Map<String, dynamic>> previewFoods; // raw preview rows
  final int availableFoodsCount;
  NutritionPlanResult({
    required this.nutritionTargets,
    required this.previewFoods,
    required this.availableFoodsCount,
  });
}
