import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../workouts_dependencies.dart';
import '../../data/services/met_calorie_service.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/strength_set.dart';

class StrengthLogPage extends StatefulWidget {
  const StrengthLogPage({super.key});
  @override
  State<StrengthLogPage> createState() => _StrengthLogPageState();
}

class _StrengthLogPageState extends State<StrengthLogPage> {
  final _nameCtrl = TextEditingController(text: 'Strength Session');
  final _weightCtrl = TextEditingController(
    text: '135',
  ); // default per-set weight lbs
  final List<StrengthSet> _sets = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _addSet() async {
    final reps = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final repsCtrl = TextEditingController(text: '10');
        return AlertDialog(
          title: const Text('Add Set'),
          content: TextField(
            controller: repsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final r = int.tryParse(repsCtrl.text) ?? 0;
                Navigator.pop(ctx, r);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (reps == null || reps <= 0) return;
    final weightLb = double.tryParse(_weightCtrl.text) ?? 0;
    final weightKg = weightLb > 0 ? poundsToKg(weightLb) : null;
    setState(() => _sets.add(StrengthSet(reps: reps, weightKg: weightKg)));
  }

  double _estimateCalories() {
    // Rough approximation: treat as moderate resistance training; 2 min per set.
    final setsMinutes = _sets.length * 2; // average time including rest
    final bodyWeightLb = 180.0; // TODO: fetch from user profile if available
    final bodyWeightKg = poundsToKg(bodyWeightLb);
    final cals = metCalorieService.caloriesBurned(
      activityKey: 'resistance_training_moderate',
      weightKg: bodyWeightKg,
      durationMinutes: setsMinutes,
    );
    return cals;
  }

  Future<void> _onSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final calories = _estimateCalories();
    final session = WorkoutSession(
      id: '',
      userId: uid,
      timestamp: DateTime.now(),
      type: WorkoutSessionType.strength,
      caloriesBurned: calories,
      sets: _sets,
      name: _nameCtrl.text.trim(),
    );
    try {
      await workoutApiService.logWorkout(session);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _sets.isEmpty ? 0 : _estimateCalories();
    return Scaffold(
      appBar: AppBar(title: const Text('Log Strength Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Session Name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Default Set Weight (lbs)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
                onPressed: _addSet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sets.isEmpty)
            const Text('No sets added yet.')
          else
            Column(
              children: [
                for (int i = 0; i < _sets.length; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('#${i + 1}')),
                      title: Text('${_sets[i].reps} reps'),
                      subtitle: Text(
                        _sets[i].weightKg == null
                            ? 'Bodyweight'
                            : '${(_sets[i].weightKg! * 2.20462).toStringAsFixed(0)} lbs',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _sets.removeAt(i)),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated calories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${calories.toStringAsFixed(1)} kcal'),
                  const SizedBox(height: 4),
                  Text(
                    'Approximation assumes moderate intensity, ~2 min per set.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Session'),
            onPressed: _sets.isEmpty ? null : _onSave,
          ),
        ],
      ),
    );
  }
}
