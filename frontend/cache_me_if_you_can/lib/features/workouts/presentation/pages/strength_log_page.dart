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
  final _notesCtrl = TextEditingController();
  final List<_ExerciseEntry> _exercises = [];
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
    _notesCtrl.dispose();
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

  int get _totalSets =>
      _exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  int get _completedSets => _exercises.fold(
        0,
        (sum, exercise) => sum + exercise.completedSets,
      );

  int get _bodyweightSets => _exercises.fold(
        0,
        (sum, exercise) => sum + exercise.bodyweightSets,
      );

  double get _totalVolumeLbs => _exercises.fold(
        0,
        (sum, exercise) => sum + exercise.volumeLbs,
      );

  List<StrengthSet> _flattenedSets() {
    return _exercises
        .expand(
          (exercise) => exercise.sets.map(
            (set) => StrengthSet(
              reps: set.reps,
              weightKg: set.weightLbs <= 0
                  ? null
                  : poundsToKg(set.weightLbs.toDouble()),
            ),
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _exercisePayload() => _exercises
      .map(
        (exercise) => {
          'id': exercise.id,
          'name': exercise.name,
          'completedSets': exercise.completedSets,
          'totalVolumeLbs': exercise.volumeLbs,
          'sets': exercise.sets
              .map(
                (set) => {
                  'setNumber': set.setNumber,
                  'weightLbs': set.weightLbs,
                  'reps': set.reps,
                  'completed': set.completed,
                },
              )
              .toList(),
        },
      )
      .toList();

  double _estimateCalories() {
    if (_userWeightKg == null || _totalSets == 0) return 0;
    final setsMinutes = _totalSets * 2;
    return metCalorieService.caloriesBurned(
      activityKey: 'resistance_training_moderate',
      weightKg: _userWeightKg!,
      durationMinutes: setsMinutes,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                    hintText: 'Need templates? Better defaults?',
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

  Future<void> _addExercise() async {
    final entry = await showDialog<_ExerciseEntry>(
      context: context,
      builder: (context) => const _ExerciseEditorDialog(),
    );
    if (entry == null) return;
    setState(() => _exercises.add(entry));
  }

  Future<void> _editExercise(int index) async {
    final entry = await showDialog<_ExerciseEntry>(
      context: context,
      builder: (context) => _ExerciseEditorDialog(initial: _exercises[index]),
    );
    if (entry == null) return;
    setState(() => _exercises[index] = entry);
  }

  void _duplicateExercise(int index) {
    final source = _exercises[index];
    final clone = _ExerciseEntry(
      id: UniqueKey().toString(),
      name: '${source.name} (copy)',
      sets: source.sets.map((set) => set.copy()).toList(),
    );
    setState(() => _exercises.insert(index + 1, clone));
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex, bool value) {
    final entry = _exercises[exerciseIndex];
    final updatedSets = List<_ExerciseSet>.from(entry.sets);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(completed: value);
    setState(() {
      _exercises[exerciseIndex] =
          _ExerciseEntry(id: entry.id, name: entry.name, sets: updatedSets);
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  Future<void> _onSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final sets = _flattenedSets();
    if (sets.isEmpty) {
      _showSnack('Add at least one exercise.');
      return;
    }
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    final calories = _userWeightKg == null ? null : _estimateCalories();
    final session = WorkoutSession(
      id: '',
      userId: uid,
      timestamp: DateTime.now(),
      type: WorkoutSessionType.strength,
      caloriesBurned: calories,
      sets: sets,
      name: _nameCtrl.text.trim().isEmpty
          ? 'Strength Session'
          : _nameCtrl.text.trim(),
      notes: notes,
      exercises: _exercisePayload(),
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
    final hasWeight = _userWeightKg != null;
    final calories = _estimateCalories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Weight Workout'),
        actions: [
          IconButton(
            tooltip: 'Save workout',
            icon: const Icon(Icons.save),
            onPressed: _exercises.isEmpty ? null : _onSave,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        tooltip: 'Add exercise',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Workout name',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildExerciseSection(theme),
          if (_exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(theme),
          ],
          const SizedBox(height: 16),
          _buildCalorieCard(theme, calories, hasWeight),
          const SizedBox(height: 20),
          FeedbackPromptCard(
            title: 'How is the workout builder?',
            subtitle: 'Dialog, list, completion toggles—tell us what to refine.',
            buttonLabel: 'Leave quick feedback',
            onPressed: () => _promptFeedback(
              featureKey: 'strength_builder_v1',
              headline: 'Rate the weight workout builder',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exercises.isEmpty ? null : _onSave,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save session'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(ThemeData theme) {
    if (_exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 40, color: theme.hintColor),
              const SizedBox(height: 12),
              Text(
                'Tap + to add your first exercise',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text('Bench, rows, curls—log each movement with sets.'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Exercises',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Exercise'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _exercises.length; i++)
          _ExerciseCard(
            entry: _exercises[i],
            onEdit: () => _editExercise(i),
            onDuplicate: () => _duplicateExercise(i),
            onDelete: () => _removeExercise(i),
            onToggleSet: (setIndex, value) =>
                _toggleSetCompletion(i, setIndex, value),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final completionPct = _totalSets == 0
        ? 0
        : ((_completedSets / _totalSets) * 100).clamp(0, 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workout summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryStatChip(
                  label: 'Exercises',
                  value: _exercises.length.toString(),
                  helper: 'Movements logged',
                ),
                _SummaryStatChip(
                  label: 'Sets',
                  value: _totalSets.toString(),
                  helper: '$_completedSets completed',
                ),
                _SummaryStatChip(
                  label: 'Volume',
                  value: _totalVolumeLbs <= 0
                      ? 'Bodyweight focus'
                      : '${_totalVolumeLbs.toStringAsFixed(0)} lbs',
                  helper: _bodyweightSets > 0
                      ? '$_bodyweightSets bodyweight sets'
                      : 'Weighted work',
                ),
                _SummaryStatChip(
                  label: 'Completion',
                  value: _totalSets == 0 ? '--' : '$completionPct%',
                  helper: 'Checkbox progress',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard(ThemeData theme, double calories, bool hasWeight) {
    return Card(
      color: _loadingProfile
          ? Colors.blueGrey.shade50
          : hasWeight
              ? Colors.green.shade50
              : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated calories', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _loadingProfile
                  ? 'Loading…'
                  : (_totalSets > 0 && hasWeight
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
                      ? 'Assumes ~2 minutes per set at moderate intensity.'
                      : 'Add body weight in Settings for estimates.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _ExerciseEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final void Function(int index, bool value) onToggleSet;

  const _ExerciseCard({
    required this.entry,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topSetLabel = entry.topSetLbs <= 0
        ? 'Bodyweight focus'
        : 'Top set ${entry.topSetLbs.toStringAsFixed(0)} lbs';
    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.sets.length} sets • $topSetLabel',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Exercise actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'dup':
                      onDuplicate();
                      break;
                    case 'del':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                  PopupMenuItem(value: 'del', child: Text('Remove')),
                ],
              ),
            ],
          ),
          children: [
            for (int i = 0; i < entry.sets.length; i++)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: entry.sets[i].completed,
                onChanged: (value) =>
                    onToggleSet(i, value ?? entry.sets[i].completed),
                title: Text('Set ${entry.sets[i].setNumber}'),
                subtitle: Text(
                  '${_weightLabel(entry.sets[i].weightLbs)} x ${entry.sets[i].reps} reps',
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.timeline, size: 16),
                  label: Text(
                    entry.volumeLbs <= 0
                        ? 'Bodyweight volume'
                        : '${entry.volumeLbs.toStringAsFixed(0)} lbs volume',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    '${entry.completedSets}/${entry.sets.length} sets complete',
                  ),
                ),
                if (entry.bodyweightSets > 0)
                  Chip(
                    avatar: const Icon(Icons.accessibility_new, size: 16),
                    label: Text('${entry.bodyweightSets} bodyweight'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _weightLabel(double weightLbs) =>
      weightLbs <= 0 ? 'Bodyweight' : '${weightLbs.toStringAsFixed(0)} lbs';
}

class _ExerciseEditorDialog extends StatefulWidget {
  final _ExerciseEntry? initial;
  const _ExerciseEditorDialog({this.initial});

  @override
  State<_ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<_ExerciseEditorDialog> {
  late final TextEditingController _nameCtrl;
  late List<_ExerciseSet> _sets;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.initial?.name ?? 'Bench Press',
    );
    _sets = widget.initial?.sets
            .map((set) => set.copy())
            .toList() ??
        [
          _ExerciseSet(setNumber: 1, weightLbs: 135, reps: 8),
        ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addSet() {
    setState(() {
      final nextNumber = _sets.length + 1;
      _sets.add(
        _ExerciseSet(setNumber: nextNumber, weightLbs: 135, reps: 8),
      );
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = _sets[i].copyWith(setNumber: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add exercise' : 'Edit exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Exercise name'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text('Set ${set.setNumber}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: set.weightLbs.toStringAsFixed(
                              set.weightLbs % 1 == 0 ? 0 : 1,
                            ),
                            maxLength: 5,
                            textAlign: TextAlign.center,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Weight (lbs)',
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null) {
                                _sets[index] = set.copyWith(weightLbs: parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: set.reps.toString(),
                            maxLength: 3,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Reps',
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                _sets[index] = set.copyWith(reps: parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove set',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            if (_sets.length == 1) return;
                            _removeSet(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty || _sets.isEmpty) return;
            final entry = _ExerciseEntry(
              id: widget.initial?.id ?? UniqueKey().toString(),
              name: _nameCtrl.text.trim(),
              sets: List<_ExerciseSet>.from(_sets.map((set) => set.copy())),
            );
            Navigator.pop(context, entry);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ExerciseEntry {
  final String id;
  final String name;
  final List<_ExerciseSet> sets;

  _ExerciseEntry({required this.id, required this.name, required this.sets});

  double get volumeLbs => sets.fold<double>(
        0,
        (sum, set) => sum + (set.weightLbs <= 0 ? 0 : set.weightLbs * set.reps),
      );

  double get topSetLbs => sets.fold<double>(
        0,
        (max, set) => set.weightLbs > max ? set.weightLbs : max,
      );

  int get completedSets =>
      sets.where((set) => set.completed).length;

  int get bodyweightSets =>
      sets.where((set) => set.weightLbs <= 0).length;
}

class _ExerciseSet {
  final int setNumber;
  final double weightLbs;
  final int reps;
  final bool completed;

  _ExerciseSet({
    required this.setNumber,
    required this.weightLbs,
    required this.reps,
    this.completed = false,
  });

  _ExerciseSet copy() => copyWith();

  _ExerciseSet copyWith({
    int? setNumber,
    double? weightLbs,
    int? reps,
    bool? completed,
  }) => _ExerciseSet(
        setNumber: setNumber ?? this.setNumber,
        weightLbs: weightLbs ?? this.weightLbs,
        reps: reps ?? this.reps,
        completed: completed ?? this.completed,
      );
}

class _SummaryStatChip extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _SummaryStatChip({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withValues(alpha: 0.5);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
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
