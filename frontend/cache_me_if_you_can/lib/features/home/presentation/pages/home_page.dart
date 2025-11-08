import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/home/presentation/widgets/progress_waves.dart';

/// Home dashboard summarizing daily activity and calories.
/// Extracted from `main.dart` to align with feature-first structure.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableRow =
        (screenWidth - 32.0) - 1.0; // horizontal padding & safety
    final perItem = (availableRow - 16.0) / 2.0; // spacing between circles
    final double circleSize = perItem.clamp(120.0, 160.0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greetingName(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Ready to crush your goals today?",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () => Navigator.pushNamed(context, Routes.workouts),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant),
            onPressed: () => Navigator.pushNamed(context, Routes.nutrition),
            tooltip: 'Nutrition',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProgressWidget(
                    progress: 0.72,
                    goalLabel: '',
                    value: '',
                    color: Colors.greenAccent,
                    size: circleSize,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '5,200 steps',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Goal: 7,200',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CaloriesProgressLoader(
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    color: Colors.orangeAccent,
                    size: circleSize,
                    bottomBuilder: (ctx, total, target) => Column(
                      children: [
                        Text(
                          '$total / $target kcal',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          "Today's calories",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingName() {
    final user = FirebaseAuth.instance.currentUser;
    final base = user?.displayName?.trim();
    final name = (base != null && base.isNotEmpty)
        ? base
        : (user?.email != null ? user!.email!.split('@').first : 'Friend');
    return 'Hello, $name';
  }
}
