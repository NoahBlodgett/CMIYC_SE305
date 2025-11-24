import 'package:flutter/material.dart';

class NutritionRecommendationPage extends StatelessWidget {
  const NutritionRecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Get personalized nutrition recommendations based on your profile and goals.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // TODO: Call your backend API for recommendations here
                // Example: final recommendations = await fetchNutritionRecommendations();
                // Show results or navigate to a details page
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Get Recommendations'),
            ),
          ],
        ),
      ),
    );
  }
}