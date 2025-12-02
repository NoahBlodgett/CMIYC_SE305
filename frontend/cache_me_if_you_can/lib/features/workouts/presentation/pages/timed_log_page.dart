import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cache_me_if_you_can/core/navigation/app_router.dart';

import '../../data/services/met_calorie_service.dart';
import '../../domain/entities/workout_session.dart';
import '../../workouts_dependencies.dart';
import '../widgets/feedback_prompt_card.dart';

class TimedLogPage extends StatefulWidget {
  const TimedLogPage({super.key});
  @override
  State<TimedLogPage> createState() => _TimedLogPageState();
}

class _TimedLogPageState extends State<TimedLogPage> {
  final _activityCtrl = TextEditingController();
  MetRangeMode _rangeMode = MetRangeMode.mid;
  List<String> _suggestions = [];
  double? _userWeightKg;
  bool _loadingProfile = true;

  double _durationSliderValue = 30;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _timerRunning = false;

  static const List<_ActivityShortcut> _shortcuts = [
    _ActivityShortcut(
      label: 'Tempo run',
      key: 'running_6_8_mph',
      icon: Icons.directions_run,
    ),
    _ActivityShortcut(
      label: 'Zone 2 ride',
      key: 'bicycling_12_13_9_mph',
      icon: Icons.directions_bike,
    ),
    _ActivityShortcut(
      label: 'Lap swim',
      key: 'swimming_hard',
      icon: Icons.pool,
    ),
    _ActivityShortcut(
      label: 'HIIT circuit',
      key: 'resistance_training_moderate',
      icon: Icons.bolt,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _hydrateProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    final weightKg = await userMetricsService.loadUserWeightKg(uid: uid);
    if (!mounted) return;
    setState(() {
      _userWeightKg = weightKg;
      _loadingProfile = false;
    });
  }

  bool get _usingTimer => _elapsed.inSeconds >= 30;

  int get _effectiveDurationMinutes {
    if (_usingTimer) {
      final minutes = (_elapsed.inSeconds / 60).ceil();
      return minutes.clamp(1, 600);
    }
    return _durationSliderValue.round();
  }

  double? _calculatedCalories() {
    final weightKg = _userWeightKg;
    if (weightKg == null) return null;
    final duration = _effectiveDurationMinutes;
    if (duration <= 0) return null;
    final activityRaw = _activityCtrl.text.trim();
    if (activityRaw.isEmpty) return null;
    final key = activityRaw.toLowerCase().replaceAll(' ', '_');
    final calories = metCalorieService.caloriesBurned(
      activityKey: key,
      weightKg: weightKg,
      durationMinutes: duration,
      rangeMode: _rangeMode,
    );
    return calories > 0 ? calories : null;
  }

  void _updateSuggestions(String value) {
    setState(() {
      _suggestions = value.isEmpty
          ? const []
          : metCalorieService.suggestKeys(value, maxSuggestions: 6);
    });
  }

  void _applySuggestion(String key) {
    _activityCtrl.text = key;
    _updateSuggestions(key);
    FocusScope.of(context).unfocus();
  }

  void _startTimer() {
    if (_timerRunning) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() => _timerRunning = true);
  }

  void _pauseTimer() {
    _ticker?.cancel();
    if (_timerRunning) {
      setState(() => _timerRunning = false);
    }
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _timerRunning = false;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final buffer = StringBuffer();
    if (hours > 0) {
      buffer.write(hours.toString().padLeft(2, '0'));
      buffer.write('·');
    }
    buffer.write(minutes.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(seconds.toString().padLeft(2, '0'));
    return buffer.toString();
  }

  String _humanizeActivityKey(String key) {
    return key
        .split(RegExp(r'[_ ]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _baseActivityKey(String key) {
    final parts = key.split('_');
    final buffer = <String>[];
    for (final part in parts) {
      if (part == 'mph') break;
      if (RegExp(r'^\d').hasMatch(part)) break;
      buffer.add(part);
    }
    return buffer.isEmpty ? key : buffer.join('_');
  }

  List<_SuggestionGroup> _groupSuggestions(List<String> suggestions) {
    final lookup = <String, _SuggestionGroup>{};
    final ordered = <_SuggestionGroup>[];
    for (final key in suggestions) {
      final base = _baseActivityKey(key);
      final group = lookup.putIfAbsent(
        base,
        () {
          final created = _SuggestionGroup(baseKey: base, keys: []);
          ordered.add(created);
          return created;
        },
      );
      group.keys.add(key);
    }
    return ordered;
  }

  Future<void> _showVariantPicker(_SuggestionGroup group) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            children: [
              ListTile(
                leading: const Icon(Icons.north_east),
                title: Text(
                  'Select pace for ${_humanizeActivityKey(group.baseKey)}',
                ),
                subtitle: const Text('Pick the speed that fits your effort'),
              ),
              const Divider(),
              ...group.keys.map(
                (key) => ListTile(
                  leading: const Icon(Icons.speed),
                  title: Text(_humanizeActivityKey(key)),
                  subtitle: Text(key),
                  onTap: () => Navigator.pop(ctx, key),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selection == null) return;
    _applySuggestion(selection);
  }

  void _showSnack(String message) {
    if (!mounted) return;
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
      _showSnack('Thanks for the feedback!');
    } catch (_) {
      _showSnack('Could not send feedback right now.');
    }
  }

  Future<_FeedbackPayload?> _showFeedbackSheet({
    required String headline,
  }) async {
    final noteCtrl = TextEditingController();
    int rating = 4;
    final result = await showModalBottomSheet<_FeedbackPayload>(
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
                Text(
                  rating >= 4
                      ? 'Feels great'
                      : rating >= 2
                      ? 'Needs work'
                      : 'Frustrating',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'What stood out?',
                    hintText: 'Shortcut ideas, confusing flows, missing cues…',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    ctx,
                    _FeedbackPayload(
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
    final weightKg = _userWeightKg;
    if (weightKg == null) {
      _showSnack(
        'Add your body weight in Settings to log calories accurately.',
      );
      return;
    }
    final activityRaw = _activityCtrl.text.trim();
    if (activityRaw.isEmpty) {
      _showSnack('Choose an activity to log.');
      return;
    }
    final duration = _effectiveDurationMinutes;
    if (duration <= 0) {
      _showSnack('Duration must be at least 1 minute.');
      return;
    }
    final activityKey = activityRaw.toLowerCase().replaceAll(' ', '_');
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
      await workoutApiService.logWorkout(session);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _calculatedCalories();
    final durationMinutes = _effectiveDurationMinutes;
    final theme = Theme.of(context);

    final groupedSuggestions = _suggestions.isEmpty
        ? const <_SuggestionGroup>[]
        : _groupSuggestions(_suggestions);
    return Scaffold(
      appBar: AppBar(title: const Text('Log Timed Activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Live timer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(_elapsed),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _timerRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _timerRunning
                                ? Icons.pause
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            _timerRunning
                                ? 'Pause timer'
                                : (_elapsed == Duration.zero
                                      ? 'Start timer'
                                      : 'Resume timer'),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _elapsed == Duration.zero
                              ? null
                              : _pauseTimer,
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Mark finish'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _elapsed == Duration.zero ? null : _resetTimer,
                      child: const Text('Reset timer'),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _usingTimer
                          ? 'Timer duration will be logged ($durationMinutes min).'
                          : 'Using manual duration presets until the timer runs.',
                      key: ValueKey(_usingTimer),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _activityCtrl,
            decoration: const InputDecoration(
              labelText: 'Activity',
              hintText: 'Search running, cycling, rowing…',
              prefixIcon: Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _updateSuggestions,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _shortcuts
                .map(
                  (shortcut) => ActionChip(
                    avatar: Icon(shortcut.icon, size: 18),
                    label: Text(shortcut.label),
                    onPressed: () => _applySuggestion(shortcut.key),
                  ),
                )
                .toList(),
          ),
          if (groupedSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: ListTile.divideTiles(
                  context: context,
                  tiles: groupedSuggestions.map((group) {
                    if (group.keys.length == 1) {
                      final key = group.keys.first;
                      return ListTile(
                        leading: const Icon(Icons.north_east),
                        title: Text(_humanizeActivityKey(key)),
                        subtitle: Text(key),
                        onTap: () => _applySuggestion(key),
                      );
                    }
                    return ListTile(
                      leading: const Icon(Icons.north_east),
                      title: Text(_humanizeActivityKey(group.baseKey)),
                      subtitle: Text('${group.keys.length} speed options'),
                      trailing: const Icon(Icons.unfold_more),
                      onTap: () => _showVariantPicker(group),
                    );
                  }),
                ).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(
                        'Duration presets',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60]
                        .map(
                          (minutes) => ChoiceChip(
                            label: Text('$minutes min'),
                            selected:
                                !_usingTimer &&
                                _durationSliderValue.round() == minutes,
                            onSelected: _usingTimer
                                ? null
                                : (_) => setState(
                                    () => _durationSliderValue = minutes
                                        .toDouble(),
                                  ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _durationSliderValue,
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${_durationSliderValue.round()} min',
                    onChanged: _usingTimer
                        ? null
                        : (value) =>
                              setState(() => _durationSliderValue = value),
                  ),
                  Text(
                    _usingTimer
                        ? 'Timer captured $durationMinutes min'
                        : 'Manual duration: ${_durationSliderValue.round()} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_outlined),
                      const SizedBox(width: 8),
                      Text('Intensity', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: MetRangeMode.values
                        .map(
                          (mode) => ChoiceChip(
                            label: Text(mode.name.toUpperCase()),
                            selected: _rangeMode == mode,
                            onSelected: (_) =>
                                setState(() => _rangeMode = mode),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: _loadingProfile
                  ? const Text('Loading profile weight…')
                  : Text(
                      _userWeightKg == null
                          ? 'Add your body weight'
                          : '${kgToPounds(_userWeightKg!).round()} lbs from profile',
                    ),
              subtitle: Text(
                _userWeightKg == null
                    ? 'Body weight lives in your profile. We use it for calorie precision.'
                    : 'Update your weight in Settings to keep estimates accurate.',
              ),
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.settings),
                child: Text(_userWeightKg == null ? 'Update' : 'Edit'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: calories == null
                ? Colors.orange.shade50
                : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated calories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    calories == null
                        ? 'Enter an activity + duration to see calories.'
                        : '${calories.toStringAsFixed(0)} kcal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: calories == null
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration · $durationMinutes min    •    Intensity · ${_rangeMode.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FeedbackPromptCard(
            title: 'Help shape the live timer',
            subtitle:
                'Does the timer + presets flow feel intuitive? Share a quick thought.',
            buttonLabel: 'Share feedback',
            onPressed: () => _promptFeedback(
              featureKey: 'timer_v2',
              headline: 'Rate the live timer experience',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: calories == null ? null : _onSave,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save session'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityShortcut {
  final String label;
  final String key;
  final IconData icon;
  const _ActivityShortcut({
    required this.label,
    required this.key,
    required this.icon,
  });
}

class _SuggestionGroup {
  final String baseKey;
  final List<String> keys;
  _SuggestionGroup({required this.baseKey, required this.keys});
}

class _FeedbackPayload {
  final int rating;
  final String note;
  const _FeedbackPayload({required this.rating, required this.note});
}
