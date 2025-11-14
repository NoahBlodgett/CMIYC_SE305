import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/home/presentation/widgets/progress_waves.dart';
import 'package:cache_me_if_you_can/features/workouts/workouts_dependencies.dart';
// CaloriesProgressLoader lives in progress_waves.dart (already imported). Removed unused nutrition_dependencies import.

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
            onPressed: () => Navigator.pushNamed(context, Routes.nutritionRecommendation),
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
              _WeeklyWorkoutsCircle(size: circleSize),
              _DailyCaloriesCircle(size: circleSize),
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

class _MetricCircle extends StatelessWidget {
  final double size;
  final double progress;
  final String value;
  final String centerLabel;
  final String subtitle;
  final Color color;
  const _MetricCircle({
    required this.size,
    required this.progress,
    required this.value,
    required this.centerLabel,
    required this.subtitle,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressWidget(
          progress: progress.clamp(0.0, 1.0),
          goalLabel: centerLabel,
          value: value,
          color: color,
          size: size,
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WeeklyWorkoutsCircle extends StatelessWidget {
  final double size;
  const _WeeklyWorkoutsCircle({required this.size});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const target = 4;
    if (uid == null) {
      return _MetricCircle(
        size: size,
        progress: 0,
        value: '0 / $target',
        centerLabel: 'sessions',
        subtitle: 'This week',
        color: Theme.of(context).colorScheme.primaryContainer,
      );
    }
    return StreamBuilder(
      stream: weeklyWorkoutSummaryService.streamFor(uid),
      builder: (context, snapshot) {
        final total = snapshot.data?.totalSessions ?? 0;
        final progress = total / target;
        return _MetricCircle(
          size: size,
          progress: progress,
          value: '$total / $target',
          centerLabel: 'sessions',
          subtitle: 'This week',
          color: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }
}

class _DailyCaloriesCircle extends StatelessWidget {
  final double size;
  const _DailyCaloriesCircle({required this.size});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _MetricCircle(
        size: size,
        progress: 0,
        value: '0 / 2500',
        centerLabel: 'kcal',
        subtitle: 'Today',
        color: Theme.of(context).colorScheme.secondaryContainer,
      );
    }
    return CaloriesProgressLoader(
      userId: uid,
      color: Theme.of(context).colorScheme.secondaryContainer,
      size: size,
      bottomBuilder: (ctx, total, target) => _MetricCircle(
        size: size,
        progress: target == 0 ? 0 : total / target,
        value: '$total / $target',
        centerLabel: 'kcal',
        subtitle: 'Today',
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }
}
