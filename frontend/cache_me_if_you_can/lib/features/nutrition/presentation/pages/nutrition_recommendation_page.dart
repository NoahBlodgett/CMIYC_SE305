import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// TODO: REMOVE HARDCODED BACKEND URL WHEN DEPLOYING OR USING EMULATOR
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

  // Quick dev sign-in for testing
  @override
  void initState() {
    super.initState();
    _devSignIn();
  }

  // TODO: REMOVE DEV SIGN-IN CODE BELOW WHEN DONE TESTING
  Future<void> _devSignIn() async {
    try {
      // Replace with your test account credentials
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'admin2@admin.com',
        password: 'S2301na*',
      );
      print('Signed in as: \\${userCred.user?.uid}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in as: \\${userCred.user?.email}')),
      );
    } catch (e) {
      print('Sign-in error: \\${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in error: \\${e.toString()}')),
      );
    }
    // Print current user after sign-in attempt
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Current user: \\${currentUser?.uid}, email: \\${currentUser?.email}');
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently logged in.')),
      );
    }
  }
  // END DEV SIGN-IN CODE

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

  List<Widget> _buildDayMeals(String day) {
    final meals = weekPlan[day] ?? {};
    final mealMap = meals['meals'] ?? {};
    final totalNutrition = meals['total_nutrition'] ?? {};
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snacks'];

    // TODO: REMOVE DEBUG PRINTS BELOW WHEN DONE DEBUGGING
    print('Debug: meals for $day: $meals');
    print('Debug: mealMap: $mealMap');
    print('Debug: breakfast: ${mealMap['breakfast']}');
    print('Debug: lunch: ${mealMap['lunch']}');
    print('Debug: dinner: ${mealMap['dinner']}');
    print('Debug: snacks: ${mealMap['snacks']}');
    // END DEBUG PRINTS

    List<Widget> widgets = [];

    // Top: Total Nutrition
    widgets.add(
      Card(
        color: Colors.blue[100], // Changed from blue[50] to blue[100] for better contrast
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Nutrition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Calories: ${totalNutrition['calories'] ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
              Text('Protein: ${totalNutrition['protein_g'] ?? 'N/A'} g', style: const TextStyle(color: Colors.black)),
              Text('Carbs: ${totalNutrition['carbs_g'] ?? 'N/A'} g', style: const TextStyle(color: Colors.black)),
              Text('Fat: ${totalNutrition['fat_g'] ?? 'N/A'} g', style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    );

    // Each meal block
    for (final type in mealTypes) {
      final meal = mealMap[type] ?? {};
      final recipe = meal['recipe'] ?? {};
      final targets = meal['targets'] ?? {};
      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type[0].toUpperCase() + type.substring(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Recipe: ${recipe['name'] ?? 'N/A'}'),
                Text('Calories: ${recipe['calories'] ?? 'N/A'}'),
                Text('Protein: ${recipe['protein_g'] ?? 'N/A'} g'),
                Text('Carbs: ${recipe['carbs_g'] ?? 'N/A'} g'),
                Text('Fat: ${recipe['fat_g'] ?? 'N/A'} g'),
                const SizedBox(height: 4),
                Text('Targets:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Calories: ${targets['calories'] ?? 'N/A'}'),
                Text('Protein: ${targets['protein_g'] ?? 'N/A'} g'),
                Text('Carbs: ${targets['carbs_g'] ?? 'N/A'} g'),
                Text('Fat: ${targets['fat_g'] ?? 'N/A'} g'),
              ],
            ),
          ),
        ),
      );
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