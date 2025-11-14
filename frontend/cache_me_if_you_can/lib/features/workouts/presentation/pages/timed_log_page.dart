import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../workouts_dependencies.dart';
import '../../data/services/met_calorie_service.dart';
import '../../domain/entities/workout_session.dart';

class TimedLogPage extends StatefulWidget {
  const TimedLogPage({super.key});
  @override
  State<TimedLogPage> createState() => _TimedLogPageState();
}

class _TimedLogPageState extends State<TimedLogPage> {
  final _activityCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _weightCtrl = TextEditingController(text: '180'); // lbs default
  MetRangeMode _rangeMode = MetRangeMode.mid;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _activityCtrl.dispose();
    _durationCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double? _calculatedCalories() {
    final key = _activityCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final dur = int.tryParse(_durationCtrl.text) ?? 0;
    final weightLb = double.tryParse(_weightCtrl.text) ?? 0;
    final weightKg = poundsToKg(weightLb);
    final metKey = key;
    final calories = metCalorieService.caloriesBurned(
      activityKey: metKey,
      weightKg: weightKg,
      durationMinutes: dur,
      rangeMode: _rangeMode,
    );
    return calories > 0 ? calories : null;
  }

  void _updateSuggestions(String value) {
    setState(() {
      _suggestions = metCalorieService.suggestKeys(value);
    });
  }

  Future<void> _onSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final activityRaw = _activityCtrl.text.trim();
    final activityKey = activityRaw.toLowerCase().replaceAll(' ', '_');
    final duration = int.tryParse(_durationCtrl.text) ?? 0;
    final weightLb = double.tryParse(_weightCtrl.text) ?? 0;
    final weightKg = poundsToKg(weightLb);
    final calories = metCalorieService.caloriesBurned(
      activityKey: activityKey,
      weightKg: weightKg,
      durationMinutes: duration,
      rangeMode: _rangeMode,
    );
    final session = WorkoutSession(
      id: '',
      userId: uid,
      timestamp: DateTime.now(),
      type: WorkoutSessionType.timed,
      activityKey: activityKey,
      durationMinutes: duration,
      caloriesBurned: calories,
      sets: const [],
      name: activityRaw,
    );
    try {
      await workoutsRepository.addSession(uid, session);
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
    final calories = _calculatedCalories();
    return Scaffold(
      appBar: AppBar(title: const Text('Log Timed Activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _activityCtrl,
            decoration: const InputDecoration(
              labelText: 'Activity (e.g. running_6_8_mph)',
            ),
            onChanged: _updateSuggestions,
          ),
          if (_suggestions.isNotEmpty)
            Wrap(
              spacing: 6,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: () {
                      _activityCtrl.text = s;
                      _updateSuggestions(s);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Body Weight (lbs)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MetRangeMode>(
            initialValue: _rangeMode,
            decoration: const InputDecoration(labelText: 'MET range selection'),
            items: MetRangeMode.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (val) =>
                setState(() => _rangeMode = val ?? MetRangeMode.mid),
          ),
          const SizedBox(height: 20),
          if (calories != null)
            Card(
              color: Colors.green.shade50,
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
                  ],
                ),
              ),
            )
          else
            const Text(
              'Enter valid activity, duration, and weight to calculate calories.',
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Session'),
            onPressed: calories == null ? null : _onSave,
          ),
        ],
      ),
    );
  }
}
