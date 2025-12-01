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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[HomePage] currentUser is null at \\${DateTime.now()}');
      // Defensive: show a fallback UI or force logout
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('User not found. Please log in again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              const _WeeklyWorkoutsCircle(),
              const _DailyCaloriesCircle(),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingName() {
    final user = FirebaseAuth.instance.currentUser;
    final base = user?.displayName?.trim();
    final emailName = user?.email?.split('@').first;
    final name = (base != null && base.isNotEmpty)
        ? base
        : (emailName != null && emailName.isNotEmpty ? emailName : 'Friend');
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
  const _WeeklyWorkoutsCircle();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableRow = (screenWidth - 32.0) - 1.0;
    final perItem = (availableRow - 16.0) / 2.0;
    final double size = perItem.clamp(120.0, 160.0);
    const target = 4;
    if (uid == null || uid.isEmpty) {
      debugPrint('[WeeklyWorkoutsCircle] user.uid is empty');
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
  const _DailyCaloriesCircle();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableRow = (screenWidth - 32.0) - 1.0;
    final perItem = (availableRow - 16.0) / 2.0;
    final double size = perItem.clamp(120.0, 160.0);
    if (uid == null || uid.isEmpty) {
      debugPrint('[DailyCaloriesCircle] user.uid is empty');
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
