import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/home/presentation/widgets/progress_waves.dart';
import 'package:cache_me_if_you_can/features/nutrition/nutrition_dependencies.dart';
import 'package:cache_me_if_you_can/features/nutrition/domain/entities/food_entry.dart';

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
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Streak: ${_streakCount()} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.military_tech, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'Level ${_level()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
        toolbarHeight: 64,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's AI recommendations (workout + meal)
            _RecommendationsRow(
              onOpenWorkout: () =>
                  Navigator.pushNamed(context, Routes.workouts),
              onOpenNutrition: () =>
                  Navigator.pushNamed(context, Routes.nutrition),
            ),
            const SizedBox(height: 16),

            // Progress visualization: workouts this week + calories today
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  // Workouts this week (placeholder values for now)
                  _WorkoutsProgress(size: circleSize),
                  // Calories circle from live DailySummaryService
                  _CaloriesProgress(size: circleSize),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick log buttons
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Log workout'),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.workouts),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Log meal'),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.nutrition),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.nutrition),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Goals & reminders (placeholder)
            _GoalsRemindersCard(),

            const SizedBox(height: 24),

            // Achievements & streaks
            _AchievementsRow(streak: _streakCount()),

            const SizedBox(height: 24),

            // Recent activity feed (nutrition entries)
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RecentNutritionList(),

            const SizedBox(height: 24),

            // Tips / insights
            _TipsCard(),
          ],
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

  // Placeholder streak/level until real data is wired.
  int _streakCount() => 3;
  int _level() => 5;
}

class _WorkoutsProgress extends StatelessWidget {
  final double size;
  const _WorkoutsProgress({required this.size});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real weekly aggregation once workouts repository exists.
    const completed = 2;
    const target = 4;
    final progress = (completed / target).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressWidget(
          progress: progress,
          goalLabel: 'workouts',
          value: '$completed / $target',
          color: Colors.tealAccent,
          size: size,
        ),
        const SizedBox(height: 8),
        Text('This week', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CaloriesProgress extends StatelessWidget {
  final double size;
  const _CaloriesProgress({required this.size});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CaloriesProgressLoader(
          userId: uid,
          color: Colors.orangeAccent,
          size: size,
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
    );
  }
}

class _RecommendationsRow extends StatelessWidget {
  final VoidCallback onOpenWorkout;
  final VoidCallback onOpenNutrition;
  const _RecommendationsRow({
    required this.onOpenWorkout,
    required this.onOpenNutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RecommendationCard(
            icon: Icons.fitness_center,
            title: 'Workout of the day',
            subtitle: 'AI-picked based on your goals',
            actionLabel: 'View',
            onAction: onOpenWorkout,
            color: Colors.blue.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RecommendationCard(
            icon: Icons.restaurant_menu,
            title: 'Meal plan',
            subtitle: 'Smart picks for today',
            actionLabel: 'Review',
            onAction: onOpenNutrition,
            color: Colors.green.shade50,
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color color;
  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _GoalsRemindersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming goals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _GoalTile(
              icon: Icons.water_drop,
              title: 'Hydration',
              progress: 0.6,
              detail: '6 / 10 glasses',
            ),
            _GoalTile(
              icon: Icons.directions_walk,
              title: 'Daily steps',
              progress: 0.5,
              detail: '5,000 / 10,000',
            ),
            _GoalTile(
              icon: Icons.self_improvement,
              title: 'Mindfulness',
              progress: 0.2,
              detail: '2 / 10 mins',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double progress;
  final String detail;
  const _GoalTile({
    required this.icon,
    required this.title,
    required this.progress,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress, minHeight: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  final int streak;
  const _AchievementsRow({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _Badge(
              icon: Icons.local_fire_department,
              label: '${streak}d Streak',
            ),
            const SizedBox(width: 8),
            const _Badge(icon: Icons.emoji_events, label: 'First Log'),
            const SizedBox(width: 8),
            const _Badge(icon: Icons.star, label: 'Consistency'),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _RecentNutritionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Text('Sign in to see activity');
    }
    return StreamBuilder<List<FoodEntry>>(
      stream: dailySummaryService.recentEntries(uid, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final items = snapshot.data ?? const <FoodEntry>[];
        if (items.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('No recent meals'),
              subtitle: const Text('Log your first meal to see it here.'),
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.nutrition),
                child: const Text('Log meal'),
              ),
            ),
          );
        }
        return Column(
          children: [for (final e in items) _ActivityTile(entry: e)],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final FoodEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconForMeal(entry.mealType))),
        title: Text(entry.name),
        subtitle: Text('${entry.mealType} • ${entry.calories.round()} kcal'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, Routes.nutrition),
      ),
    );
  }

  IconData _iconForMeal(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.fastfood;
    }
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      'Small wins add up. Keep going! 💪',
      'Hydrate regularly throughout the day.',
      'Prioritize protein to support recovery.',
      'Short on time? Do a 10‑minute HIIT!',
    ];
    final tip = tips[DateTime.now().day % tips.length];
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline),
        title: const Text('Tip of the day'),
        subtitle: Text(tip),
      ),
    );
  }
}
