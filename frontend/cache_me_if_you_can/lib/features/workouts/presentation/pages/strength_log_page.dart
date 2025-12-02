import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../workouts_dependencies.dart';
import '../../data/services/met_calorie_service.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/strength_set.dart';
import '../widgets/feedback_prompt_card.dart';

class StrengthLogPage extends StatefulWidget {
  const StrengthLogPage({super.key});
  @override
  State<StrengthLogPage> createState() => _StrengthLogPageState();
}

class _StrengthLogPageState extends State<StrengthLogPage> {
  final _nameCtrl = TextEditingController(text: 'Strength Session');
  final List<StrengthSet> _sets = [];
  int _pendingReps = 10;
  int _pendingWeightLbs = 135;
  bool _pendingBodyweight = false;
  double? _userWeightKg;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    final weight = await userMetricsService.loadUserWeightKg(uid: uid);
    if (!mounted) return;
    setState(() {
      _userWeightKg = weight;
      _loadingProfile = false;
    });
  }

  void _adjustReps(int delta) {
    setState(() {
      _pendingReps = (_pendingReps + delta).clamp(1, 50);
    });
  }

  void _adjustWeight(int delta) {
    setState(() {
      _pendingBodyweight = false;
      _pendingWeightLbs = (_pendingWeightLbs + delta).clamp(0, 600);
    });
  }

  void _toggleBodyweight(bool selected) {
    setState(() {
      _pendingBodyweight = selected;
      if (selected) _pendingWeightLbs = 0;
    });
  }

  void _applyShortcut({required int reps, required int deltaWeight}) {
    setState(() {
      _pendingReps = reps;
      _pendingBodyweight = false;
      _pendingWeightLbs = (_pendingWeightLbs + deltaWeight).clamp(0, 600);
    });
  }

  void _addPendingSet() {
    if (_pendingReps <= 0) {
      _showSnack('Reps must be greater than zero.');
      return;
    }
    final weightKg = _pendingBodyweight || _pendingWeightLbs <= 0
        ? null
        : poundsToKg(_pendingWeightLbs.toDouble());
    setState(() {
      _sets.add(StrengthSet(reps: _pendingReps, weightKg: weightKg));
    });
  }

  void _removeSet(int index) {
    setState(() => _sets.removeAt(index));
  }

  void _duplicateSet(int index) {
    final set = _sets[index];
    setState(
      () => _sets.add(StrengthSet(reps: set.reps, weightKg: set.weightKg)),
    );
  }

  double _estimateCalories() {
    if (_userWeightKg == null || _sets.isEmpty) return 0;
    final setsMinutes = _sets.length * 2;
    return metCalorieService.caloriesBurned(
      activityKey: 'resistance_training_moderate',
      weightKg: _userWeightKg!,
      durationMinutes: setsMinutes,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _promptFeedback({
    required String featureKey,
    required String headline,
  }) async {
    final payload = await _showFeedbackSheet(headline: headline);
    if (!mounted || payload == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      await workoutFeedbackService.submitFeedback(
        featureKey: featureKey,
        rating: payload.rating,
        comment: payload.note,
        userId: uid,
      );
      _showSnack('Appreciate the feedback!');
    } catch (_) {
      _showSnack('Could not send feedback right now.');
    }
  }

  Future<_ComposerFeedback?> _showFeedbackSheet({
    required String headline,
  }) async {
    final noteCtrl = TextEditingController();
    int rating = 4;
    final result = await showModalBottomSheet<_ComposerFeedback>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Slider(
                  value: rating.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$rating',
                  onChanged: (value) =>
                      setModalState(() => rating = value.round()),
                ),
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'What would smooth it out?',
                    hintText: 'Need different increments? Better shortcuts?',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    ctx,
                    _ComposerFeedback(
                      rating: rating,
                      note: noteCtrl.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Submit feedback'),
                ),
              ],
            ),
          ),
        );
      },
    );
    noteCtrl.dispose();
    return result;
  }

  Future<void> _onSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_sets.isEmpty) {
      _showSnack('Add at least one set.');
      return;
    }
    final calories = _userWeightKg == null ? null : _estimateCalories();
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
      _showSnack('Failed to save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calories = _estimateCalories();
    final hasWeight = _userWeightKg != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Strength Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Session name',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_graph),
                      const SizedBox(width: 8),
                      Text(
                        'Compose next set',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CounterTile(
                          label: 'Reps',
                          value: _pendingReps.toString(),
                          onIncrement: () => _adjustReps(1),
                          onDecrement: () => _adjustReps(-1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CounterTile(
                          label: _pendingBodyweight ? 'Bodyweight' : 'Weight',
                          value: _pendingBodyweight
                              ? 'Body only'
                              : _pendingWeightLbs.toString(),
                          suffix: _pendingBodyweight ? null : 'lbs',
                          onIncrement: () => _adjustWeight(5),
                          onDecrement: () => _adjustWeight(-5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Bodyweight'),
                        selected: _pendingBodyweight,
                        onSelected: _toggleBodyweight,
                      ),
                      ActionChip(
                        label: const Text('Power 5x5'),
                        onPressed: () =>
                            _applyShortcut(reps: 5, deltaWeight: 10),
                      ),
                      ActionChip(
                        label: const Text('Volume 12'),
                        onPressed: () =>
                            _applyShortcut(reps: 12, deltaWeight: -10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addPendingSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add set'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_sets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No sets yet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text('Use the composer above to log your first set.'),
                  ],
                ),
              ),
            )
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
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'dup') {
                            _duplicateSet(i);
                          } else {
                            _removeSet(i);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'dup',
                            child: Text('Duplicate set'),
                          ),
                          PopupMenuItem(
                            value: 'del',
                            child: Text('Remove set'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          Card(
            color: _loadingProfile
                ? Colors.blueGrey.shade50
                : hasWeight
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated calories',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingProfile
                        ? 'Loading…'
                        : (_sets.isNotEmpty && hasWeight
                              ? '${calories.toStringAsFixed(0)} kcal'
                              : '--'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _loadingProfile
                          ? theme.colorScheme.primary
                          : hasWeight
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadingProfile
                        ? 'Fetching profile weight…'
                        : hasWeight
                        ? 'Assumes moderate intensity (~2 min per set).'
                        : 'Add your body weight in Settings to unlock calorie estimates.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FeedbackPromptCard(
            title: 'How is the set composer?',
            subtitle:
                'We are tuning the shortcuts + counters. Every note helps.',
            buttonLabel: 'Leave quick feedback',
            onPressed: () => _promptFeedback(
              featureKey: 'composer_v1',
              headline: 'Rate the set composer experience',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sets.isEmpty ? null : _onSave,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save session'),
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterTile({
    required this.label,
    required this.value,
    this.suffix,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = IconButton.styleFrom(
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
    );
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_circle_outline),
                style: buttonStyle,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: suffix == null
                      ? Text(
                          value,
                          style: valueStyle,
                          maxLines: 1,
                          softWrap: false,
                        )
                      : RichText(
                          text: TextSpan(
                            style: valueStyle,
                            children: [
                              TextSpan(text: value),
                              const WidgetSpan(
                                child: SizedBox(width: 6),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: suffix,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_circle_outline),
                style: buttonStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerFeedback {
  final int rating;
  final String note;
  const _ComposerFeedback({required this.rating, required this.note});
}
