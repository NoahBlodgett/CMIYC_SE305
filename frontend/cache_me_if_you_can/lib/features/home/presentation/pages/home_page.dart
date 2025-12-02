import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/home/presentation/widgets/progress_waves.dart';
import 'package:cache_me_if_you_can/features/nutrition/nutrition_dependencies.dart';
import 'package:cache_me_if_you_can/features/nutrition/domain/entities/food_entry.dart';
import 'package:cache_me_if_you_can/features/workouts/workouts_dependencies.dart';

/// Home dashboard summarizing daily activity and calories.
/// Extracted from `main.dart` to align with feature-first structure.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _workoutsFuture;
  int _nutritionRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = _loadWorkouts();
  }

  Future<List<Map<String, dynamic>>> _loadWorkouts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    try {
      return await workoutApiService.getUserWorkouts(uid, limit: 20);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refreshWorkouts() async {
    final next = _loadWorkouts();
    if (mounted) {
      setState(() {
        _workoutsFuture = next;
      });
    }
    await next;
  }

  Future<void> _openWorkouts() async {
    await Navigator.pushNamed(context, Routes.workouts);
    if (!mounted) return;
    await _refreshWorkouts();
  }

  Future<void> _openWorkoutSessions() async {
    await Navigator.pushNamed(context, Routes.workoutSessions);
    if (!mounted) return;
    await _refreshWorkouts();
  }

  Future<void> _openNutrition() async {
    await Navigator.pushNamed(context, Routes.nutrition);
    if (!mounted) return;
    _refreshNutritionIndicators();
  }

  void _refreshNutritionIndicators() {
    if (!mounted) return;
    setState(() {
      _nutritionRefreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableRow = (screenWidth - 32.0) - 1.0;
    final perItem = (availableRow - 16.0) / 2.0;
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
            _RecommendationsRow(
              onOpenWorkout: _openWorkouts,
              onOpenNutrition: _openNutrition,
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _WorkoutsProgress(
                    size: circleSize,
                    workoutsFuture: _workoutsFuture,
                    onLogWorkout: _openWorkouts,
                  ),
                  _CaloriesProgress(
                    size: circleSize,
                    refreshToken: _nutritionRefreshToken,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recent workouts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RecentWorkoutsList(
              workoutsFuture: _workoutsFuture,
              onLogWorkout: _openWorkouts,
              onViewAll: _openWorkoutSessions,
            ),
            const SizedBox(height: 20),
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
                  onPressed: _openWorkouts,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Log meal'),
                  onPressed: _openNutrition,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  onPressed: _openWorkoutSessions,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GoalsRemindersCard(),
            const SizedBox(height: 24),
            _AchievementsRow(streak: _streakCount()),
            const SizedBox(height: 24),
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RecentNutritionList(
              key: ValueKey('recent-nutrition-$_nutritionRefreshToken'),
              onLogMeal: _openNutrition,
            ),
            const SizedBox(height: 24),
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

  int _streakCount() => 3;
  int _level() => 5;
}

class _WorkoutsProgress extends StatelessWidget {
  final double size;
  final Future<List<Map<String, dynamic>>> workoutsFuture;
  final VoidCallback onLogWorkout;

  const _WorkoutsProgress({
    required this.size,
    required this.workoutsFuture,
    required this.onLogWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: workoutsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            width: size,
            child: _WorkoutsMessageCard(
              icon: Icons.error_outline,
              message: 'Could not load workouts right now.',
              actionLabel: 'Retry',
              onAction: onLogWorkout,
            ),
          );
        }
        final sessions = snapshot.data ?? const [];
        if (sessions.isEmpty) {
          return SizedBox(
            width: size,
            child: _WorkoutsMessageCard(
              icon: Icons.self_improvement,
              message: 'Log your first workout to unlock stats.',
              actionLabel: 'Log workout',
              onAction: onLogWorkout,
            ),
          );
        }

        final stats = _WeeklyWorkoutStats.compute(sessions);
        final progress = stats.target == 0
            ? 0.0
            : (stats.completed / stats.target).clamp(0.0, 1.0);
        final theme = Theme.of(context).textTheme;
        final bodySmall = theme.bodySmall;
        final fadedBody = bodySmall?.copyWith(
          color: bodySmall.color?.withValues(alpha: 0.8),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressWidget(
              progress: progress,
              goalLabel: 'workouts',
              value: '${stats.completed} / ${stats.target}',
              color: Colors.tealAccent,
              size: size,
            ),
            const SizedBox(height: 8),
            Text(
              stats.helperText,
              style: bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              stats.lastWorkoutDescription,
              style: fadedBody,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _CaloriesProgress extends StatelessWidget {
  final double size;
  final int refreshToken;
  const _CaloriesProgress({
    required this.size,
    required this.refreshToken,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CaloriesProgressLoader(
          key: ValueKey('calories-$refreshToken'),
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

class _RecentWorkoutsList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> workoutsFuture;
  final VoidCallback onLogWorkout;
  final VoidCallback onViewAll;

  const _RecentWorkoutsList({
    required this.workoutsFuture,
    required this.onLogWorkout,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: workoutsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Loading workouts…'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _WorkoutsMessageCard(
            icon: Icons.error_outline,
            message: 'Could not load recent workouts.',
            actionLabel: 'Try again',
            onAction: onLogWorkout,
          );
        }
        final sessions = snapshot.data ?? const [];
        if (sessions.isEmpty) {
          return _WorkoutsMessageCard(
            icon: Icons.fitness_center,
            message: 'No workouts logged yet. Start one now!',
            actionLabel: 'Log workout',
            onAction: onLogWorkout,
          );
        }
        final topSessions = sessions.take(3).toList();
        return Column(
          children: [
            for (final session in topSessions)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconForWorkout(session)),
                  ),
                  title: Text(_workoutTitle(session)),
                  subtitle: Text(_workoutSubtitle(session)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onViewAll,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.open_in_new),
                label: const Text('View all workouts'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkoutsMessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _WorkoutsMessageCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyWorkoutStats {
  final int completed;
  final int timedMinutes;
  final int strengthSets;
  final String lastWorkoutDescription;
  final int target;

  const _WeeklyWorkoutStats({
    required this.completed,
    required this.timedMinutes,
    required this.strengthSets,
    required this.lastWorkoutDescription,
    required this.target,
  });

  String get helperText {
    final parts = <String>[];
    if (timedMinutes > 0) parts.add('$timedMinutes min cardio');
    if (strengthSets > 0) parts.add('$strengthSets sets logged');
    return parts.isEmpty ? 'Log workouts to build your streak.' : parts.join(' · ');
  }

  static _WeeklyWorkoutStats compute(List<Map<String, dynamic>> sessions) {
    const target = 4;
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 7));

    int completed = 0;
    int timedMinutes = 0;
    int strengthSets = 0;

    for (final session in sessions) {
      final timestamp = _parseWorkoutTimestamp(session);
      if (timestamp == null || timestamp.isBefore(windowStart)) continue;
      completed++;
      final type = (session['type'] as String?) ?? 'strength';
      if (type == 'timed') {
        timedMinutes += (session['durationMinutes'] as num?)?.toInt() ?? 0;
      } else {
        strengthSets += (session['sets'] as List?)?.length ?? 0;
      }
    }

    final latest = sessions.first;
    final calories = (latest['caloriesBurned'] as num?)?.round();
    final lastDescription = calories == null
      ? _workoutTitle(latest)
      : '${_workoutTitle(latest)} · $calories kcal';

    return _WeeklyWorkoutStats(
      completed: completed,
      timedMinutes: timedMinutes,
      strengthSets: strengthSets,
      lastWorkoutDescription: lastDescription,
      target: target,
    );
  }
}

IconData _iconForWorkout(Map<String, dynamic> session) {
  final type = (session['type'] as String?) ?? 'strength';
  return type == 'timed' ? Icons.timer : Icons.fitness_center;
}

String _workoutTitle(Map<String, dynamic> session) {
  final name = (session['name'] as String?)?.trim();
  if (name != null && name.isNotEmpty) return name;
  final type = (session['type'] as String?) ?? 'strength';
  if (type == 'timed') {
    final key = (session['activityKey'] as String?) ?? 'Timed session';
    return key.replaceAll('_', ' ');
  }
  return 'Strength session';
}

String _workoutSubtitle(Map<String, dynamic> session) {
  final date = _parseWorkoutTimestamp(session);
  final dateLabel = date == null
      ? 'Recent'
      : '${date.month}/${date.day}';
  final calories = (session['caloriesBurned'] as num?)?.round() ?? 0;
  final type = (session['type'] as String?) ?? 'strength';
  final detail = type == 'timed'
      ? '${(session['durationMinutes'] as num?)?.toInt() ?? 0} min · $calories kcal'
      : '${(session['sets'] as List?)?.length ?? 0} sets · $calories kcal';
  return '$dateLabel · $detail';
}

DateTime? _parseWorkoutTimestamp(Map<String, dynamic> session) {
  final raw = session['timestamp'];
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  return null;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final cards = [
          _RecommendationCard(
            icon: Icons.fitness_center,
            title: 'Workout of the day',
            subtitle: 'AI-picked based on your goals',
            actionLabel: 'View',
            onAction: onOpenWorkout,
            color: Colors.blue.shade50,
          ),
          _RecommendationCard(
            icon: Icons.restaurant_menu,
            title: 'Meal plan',
            subtitle: 'Smart picks for today',
            actionLabel: 'Review',
            onAction: onOpenNutrition,
            color: Colors.green.shade50,
          ),
        ];
        if (isCompact) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onAction, child: Text(actionLabel)),
            ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(
              icon: Icons.local_fire_department,
              label: '${streak}d Streak',
            ),
            const _Badge(icon: Icons.emoji_events, label: 'First Log'),
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
  final Future<void> Function() onLogMeal;

  const _RecentNutritionList({super.key, required this.onLogMeal});

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
                onPressed: () async => onLogMeal(),
                child: const Text('Log meal'),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final entry in items)
              _ActivityTile(entry: entry, onOpen: onLogMeal),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final FoodEntry entry;
  final Future<void> Function() onOpen;
  const _ActivityTile({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconForMeal(entry.mealType))),
        title: Text(entry.name),
        subtitle: Text('${entry.mealType} • ${entry.calories.round()} kcal'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async => onOpen(),
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
