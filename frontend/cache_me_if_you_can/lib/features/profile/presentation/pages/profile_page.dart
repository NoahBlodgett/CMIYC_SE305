import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/features/nutrition/nutrition_dependencies.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final String uid;
  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 16),
              _HeaderCard(data: data),
              _MetricsRow(data: data),
              _GoalsPreferencesCard(data: data),
              _WorkoutSummary(uid: uid),
              _NutritionOverview(uid: uid),
              _BadgesStreaksCard(data: data),
              _HealthDataPlaceholder(),
              _HistorySection(uid: uid),
              _AiRecommendationsSection(uid: uid),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HeaderCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final name = (data['displayName'] ?? data['name'] ?? 'Athlete').toString();
    final level = data['level'] ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ((data['xp'] ?? 0) % 1000) / 1000.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricsRow({required this.data});
  @override
  Widget build(BuildContext context) {
    final age = data['Age'] ?? data['age'];
    final heightIn = (data['Height_in'] ?? data['height'])?.toString();
    final weightLb = (data['Weight_lb'] ?? data['weight'])?.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _metric('Age', age != null ? '$age' : '--')),
          Expanded(
            child: _metric('Height', heightIn != null ? '$heightIn in' : '--'),
          ),
          Expanded(
            child: _metric('Weight', weightLb != null ? '$weightLb lb' : '--'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );
}

class _GoalsPreferencesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _GoalsPreferencesCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final goalCode = data['Goal'] ?? data['goal'];
    final activity = data['Activity_Level'] ?? data['activity_level'];
    final allergies = (data['allergies'] as List?)?.join(', ');
    final prefs = (data['preferences'] as List?)?.join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goals & Preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _chip('Goal: ${_goalLabel(goalCode)}'),
                  if (activity != null) _chip('Activity: $activity'),
                  if (allergies != null && allergies.isNotEmpty)
                    _chip('Allergies: $allergies'),
                  if (prefs != null && prefs.isNotEmpty) _chip('Prefs: $prefs'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _goalLabel(dynamic code) {
    switch (code) {
      case 0:
        return 'Maintain';
      case 1:
        return 'Weight Loss';
      case 2:
        return 'Muscle Gain';
      default:
        return code?.toString() ?? 'Unknown';
    }
  }

  Widget _chip(String label) => Chip(label: Text(label));
}

class _WorkoutSummary extends StatelessWidget {
  final String uid;
  const _WorkoutSummary({required this.uid});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Workout Progress'),
              SizedBox(height: 8),
              Wrap(
                spacing: 24,
                children: [
                  _StatBlock(label: 'Workouts', value: '24'),
                  _StatBlock(label: 'PRs', value: '5'),
                  _StatBlock(label: 'Volume', value: '32k'),
                  _StatBlock(label: 'Streak', value: '7d'),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(value: 0.24, minHeight: 6),
              SizedBox(height: 4),
              Text('Next level in 3 workouts'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}

class _NutritionOverview extends StatelessWidget {
  final String uid;
  const _NutritionOverview({required this.uid});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder(
            stream: dailySummaryService.streamFor(uid, DateTime.now()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final summary = snapshot.data as dynamic;
              final int total = summary.totalCalories as int;
              final int target = summary.targetCalories as int;
              final double pct = target == 0
                  ? 0.0
                  : (total / target).clamp(0.0, 1.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$total / $target kcal'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Entries: ${summary.entriesCount}'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BadgesStreaksCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BadgesStreaksCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final badges =
        (data['badges'] as List?)?.cast<String>() ??
        const ['🔥 Streak Starter', '🏅 First Workout'];
    final streak = data['streak'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Badges & Streaks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final b in badges) Chip(label: Text(b))],
              ),
              const SizedBox(height: 8),
              Text('Current streak: $streak days'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthDataPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Synced Health Data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('Heart Rate: —  |  Steps (today): —  |  Sleep: —'),
              const SizedBox(height: 4),
              const Text(
                'Connect Apple HealthKit / Google Fit (coming soon)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String uid;
  const _HistorySection({required this.uid});
  @override
  Widget build(BuildContext context) {
    final mealsQ = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('nutrition_entries')
        .orderBy('timestamp', descending: true)
        .limit(10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: mealsQ.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No recent nutrition entries.');
                  }
                  return Column(
                    children: [for (final d in docs) _historyRow(d.data())],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> m) {
    final name = m['name']?.toString() ?? 'Food';
    final cal = (m['calories'] as num?)?.toDouble() ?? 0;
    final meal = m['mealType']?.toString() ?? '';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text('$meal · ${cal.toStringAsFixed(0)} kcal'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}

class _AiRecommendationsSection extends StatelessWidget {
  final String uid;
  const _AiRecommendationsSection({required this.uid});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized Recommendations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('AI-generated workout & meal plans will appear here.'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: const [
                  Chip(label: Text('Meal Plan v1')),
                  Chip(label: Text('Workout Split A')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
