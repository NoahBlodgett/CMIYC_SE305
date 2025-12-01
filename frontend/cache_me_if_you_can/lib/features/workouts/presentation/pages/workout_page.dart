import 'package:flutter/material.dart';
import '../../../../mock/mock_data.dart';
import '../../../../utils/program_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../workouts/workouts_dependencies.dart';
import '../../domain/entities/workout_session.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String? _currentProgramName;
  List<String> _recentPrograms = const [];

  @override
  void initState() {
    super.initState();
    _loadProgramName();
    _loadRecentPrograms();
  }

  Future<void> _loadProgramName() async {
    try {
      final name = await ProgramState.loadActiveProgramName();
      if (!mounted) return;
      setState(() => _currentProgramName = name);
    } catch (_) {}
  }

  Future<void> _loadRecentPrograms() async {
    try {
      final list = await fetchRecentPrograms(limit: 3);
      if (!mounted) return;
      setState(() => _recentPrograms = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Feedback insights',
            icon: const Icon(Icons.insights_outlined),
            onPressed: _openFeedbackInsights,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ProgramHeroCard(
            programName: _currentProgramName,
            onPrimaryTap: _showQuickStartSheet,
            onSwitchTap: _openProgramSwitcher,
            onCreateAiTap: _onCreateAiProgram,
            onBuildTap: _onBuildProgram,
            hasRecentPrograms: _recentPrograms.isNotEmpty,
          ),
          const SizedBox(height: 20),
          _QuickLogCard(
            onTimed: () => Navigator.pushNamed(context, Routes.workoutLogTimed),
            onStrength: () =>
                Navigator.pushNamed(context, Routes.workoutLogStrength),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.today_outlined,
            title: "Today's plan",
            tint: color.tertiary,
            actionLabel: 'View plan',
            onActionTap: _openPlanOverview,
          ),
          _SectionCard(
            child: Column(
              children: [
                _ExerciseTile(
                  title: 'Warm-up jog',
                  details: '10 min · Easy',
                  icon: Icons.directions_run,
                  tint: color.primary,
                ),
                const Divider(height: 1),
                _ExerciseTile(
                  title: 'Bench press',
                  details: '4 x 8 @ 60%',
                  icon: Icons.fitness_center,
                  tint: color.secondary,
                ),
                const Divider(height: 1),
                _ExerciseTile(
                  title: 'Lat pulldown',
                  details: '3 x 10',
                  icon: Icons.cable,
                  tint: color.tertiary,
                ),
                const Divider(height: 1),
                _ExerciseTile(
                  title: 'Plank',
                  details: '3 x 45s',
                  icon: Icons.crop_square,
                  tint: color.primary,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openPlanOverview,
              child: const Text('View plan details'),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            icon: Icons.history,
            title: 'Recent sessions',
            tint: color.secondary,
            actionLabel: 'See all',
            onActionTap: _openRecentSessionsPage,
          ),
          _RecentSessionsCard(color: color),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openRecentSessionsPage,
              child: const Text('Open recent sessions'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onViewRecentPrograms() async {
    final selected = await Navigator.pushNamed<String>(
      context,
      Routes.workoutRecent,
    );
    if (selected != null && mounted) {
      await _setActiveProgram(selected);
    }
  }

  Future<void> _onCreateAiProgram() async {
    final created = await Navigator.pushNamed<String>(
      context,
      Routes.workoutAi,
    );
    if (created != null && mounted) {
      await _setActiveProgram(created);
    }
  }

  Future<void> _onBuildProgram() async {
    final built = await Navigator.pushNamed<String>(
      context,
      Routes.workoutBuild,
    );
    if (built != null && mounted) {
      await _setActiveProgram(built);
    }
  }

  Future<void> _setActiveProgram(String name) async {
    await ProgramState.saveActiveProgramName(name);
    if (!mounted) return;
    setState(() => _currentProgramName = name);
  }

  Future<void> _openProgramSwitcher() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch program',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_recentPrograms.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.history_toggle_off),
                    title: const Text('No recent programs yet'),
                    subtitle: const Text('Create a plan to see it here.'),
                    dense: true,
                  )
                else
                  ..._recentPrograms.map(
                    (program) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        program,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(ctx, program),
                    ),
                  ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.view_list_outlined),
                  title: const Text('View all programs'),
                  onTap: () => Navigator.pop(ctx, '__view_all__'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Generate with AI'),
                  onTap: () => Navigator.pop(ctx, '__ai__'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.build_outlined),
                  title: const Text('Build manually'),
                  onTap: () => Navigator.pop(ctx, '__build__'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selection == null) return;
    switch (selection) {
      case '__view_all__':
        await _onViewRecentPrograms();
        return;
      case '__ai__':
        await _onCreateAiProgram();
        return;
      case '__build__':
        await _onBuildProgram();
        return;
      default:
        await _setActiveProgram(selection);
    }
  }

  Future<void> _openPlanOverview() async {
    await Navigator.pushNamed(context, Routes.workoutPlan);
  }

  Future<void> _openRecentSessionsPage() async {
    await Navigator.pushNamed(context, Routes.workoutSessions);
  }

  Future<void> _openFeedbackInsights() async {
    await Navigator.pushNamed(context, Routes.workoutFeedback);
  }

  Future<void> _showQuickStartSheet() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Timed activity'),
                subtitle: const Text('Intervals, cardio, conditioning'),
                onTap: () => Navigator.pop(ctx, 'timed'),
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Strength session'),
                subtitle: const Text('Sets, reps, weightlifting'),
                onTap: () => Navigator.pop(ctx, 'strength'),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
    if (!mounted || selection == null) return;
    if (selection == 'timed') {
      Navigator.pushNamed(context, Routes.workoutLogTimed);
    } else {
      Navigator.pushNamed(context, Routes.workoutLogStrength);
    }
  }
}

class _ProgramHeroCard extends StatelessWidget {
  final String? programName;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSwitchTap;
  final VoidCallback onCreateAiTap;
  final VoidCallback onBuildTap;
  final bool hasRecentPrograms;

  const _ProgramHeroCard({
    required this.programName,
    required this.onPrimaryTap,
    required this.onSwitchTap,
    required this.onCreateAiTap,
    required this.onBuildTap,
    required this.hasRecentPrograms,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryLabel = programName == null
        ? 'Start your first activity'
        : 'Start today\'s activity';
    final subtitle = programName == null
        ? 'Pick a focus to unlock a guided weekly plan.'
        : 'Dial in, stay on pace, and log sets as you go.';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active program',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      programName ?? 'No plan selected',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'ai':
                      onCreateAiTap();
                      break;
                    case 'build':
                      onBuildTap();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'ai',
                    child: Text('New AI program'),
                  ),
                  PopupMenuItem<String>(
                    value: 'build',
                    child: Text('Build manually'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onPrimaryTap,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(
                    hasRecentPrograms ? 'Switch plan' : 'Find a plan',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: hasRecentPrograms ? onSwitchTap : onCreateAiTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI coach'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onCreateAiTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  final VoidCallback onTimed;
  final VoidCallback onStrength;

  const _QuickLogCard({required this.onTimed, required this.onStrength});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick log',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTimed,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Timed activity'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStrength,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Strength session'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Popular picks',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickShortcutChip(
                label: 'Intervals',
                icon: Icons.bolt,
                onTap: onTimed,
              ),
              _QuickShortcutChip(
                label: 'Recovery walk',
                icon: Icons.directions_walk,
                onTap: onTimed,
              ),
              _QuickShortcutChip(
                label: 'Push day',
                icon: Icons.monitor_weight,
                onTap: onStrength,
              ),
              _QuickShortcutChip(
                label: 'Supersets',
                icon: Icons.all_inclusive,
                onTap: onStrength,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickShortcutChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final ColorScheme color;
  const _RecentSessionsCard({required this.color});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _SectionCard(child: Text('Sign in to view sessions'));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: workoutApiService.getUserWorkouts(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionCard(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        final data = snapshot.data ?? const [];
        if (data.isEmpty) {
          return _SectionCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('No sessions logged'),
              subtitle: const Text('Log your first workout to see it here.'),
              trailing: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.workoutLogTimed),
                child: const Text('Log'),
              ),
            ),
          );
        }
        return _SectionCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = data[i];
              final type = s['type'] == 'timed'
                  ? WorkoutSessionType.timed
                  : WorkoutSessionType.strength;
              final title =
                  s['name'] ??
                  (type == WorkoutSessionType.timed
                      ? (s['activityKey'] ?? 'Timed session')
                      : 'Strength session');
              final meta = type == WorkoutSessionType.timed
                  ? '${s['durationMinutes'] ?? 0} min · ${(s['caloriesBurned'] ?? 0).round()} kcal'
                  : '${(s['sets'] as List?)?.length ?? 0} sets · ${(s['sets'] as List?)?.fold<int>(0, (sum, set) => sum + ((set['reps'] ?? 0) as int)) ?? 0} reps · ${(s['caloriesBurned'] ?? 0).round()} kcal';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.primary.withAlpha(38),
                  child: Icon(
                    type == WorkoutSessionType.timed
                        ? Icons.timer
                        : Icons.fitness_center,
                    color: color.primary,
                  ),
                ),
                title: Text(title),
                subtitle: Text(meta),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, Routes.workoutSessions),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color tint;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.tint,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: tint.withAlpha(31),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: tint),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String title;
  final String details;
  final IconData icon;
  final Color tint;
  const _ExerciseTile({
    required this.title,
    required this.details,
    required this.icon,
    required this.tint,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        backgroundColor: tint.withAlpha(28),
        child: Icon(icon, color: tint),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(details),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {},
      ),
      onTap: () {},
    );
  }
}
