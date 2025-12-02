import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/workout_session.dart';
import '../../workouts_dependencies.dart';

class RecentSessionsPage extends StatefulWidget {
  const RecentSessionsPage({super.key});

  @override
  State<RecentSessionsPage> createState() => _RecentSessionsPageState();
}

class _RecentSessionsPageState extends State<RecentSessionsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSessions();
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    try {
      return await workoutApiService.getUserWorkouts(uid, limit: 100);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refresh() async {
    final refresh = _loadSessions();
    setState(() => _future = refresh);
    await refresh;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recent sessions')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? const [];
            if (data.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No sessions yet',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start a timed or strength log to see it appear here.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.workoutLogTimed,
                            ),
                            icon: const Icon(Icons.timer),
                            label: const Text('Log timed activity'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.workoutLogStrength,
                            ),
                            icon: const Icon(Icons.fitness_center),
                            label: const Text('Log strength session'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemBuilder: (context, index) {
                final session = data[index];
                final type = session['type'] == 'timed'
                    ? WorkoutSessionType.timed
                    : WorkoutSessionType.strength;
                final title =
                    session['name'] ??
                    (type == WorkoutSessionType.timed
                        ? (session['activityKey'] ?? 'Timed session')
                        : 'Strength session');
                final subtitle = type == WorkoutSessionType.timed
                    ? '${session['durationMinutes'] ?? 0} min · '
                          '${(session['caloriesBurned'] ?? 0).round()} kcal'
                    : '${(session['sets'] as List?)?.length ?? 0} sets · '
                          '${(session['caloriesBurned'] ?? 0).round()} kcal';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.primary.withAlpha(32),
                      child: Icon(
                        type == WorkoutSessionType.timed
                            ? Icons.timer
                            : Icons.fitness_center,
                        color: color.primary,
                      ),
                    ),
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {},
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: data.length,
            );
          },
        ),
      ),
    );
  }
}
