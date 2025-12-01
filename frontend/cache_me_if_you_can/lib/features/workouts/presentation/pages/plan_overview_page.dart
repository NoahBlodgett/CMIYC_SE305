import 'package:flutter/material.dart';

import '../../../../utils/program_state.dart';

class PlanOverviewPage extends StatefulWidget {
  const PlanOverviewPage({super.key});

  @override
  State<PlanOverviewPage> createState() => _PlanOverviewPageState();
}

class _PlanOverviewPageState extends State<PlanOverviewPage> {
  String? _programName;
  bool _loading = true;

  static const List<_PlanBlock> _todayPlan = [
    _PlanBlock(
      title: 'Warm-up jog',
      details: '10 min · Easy effort',
      icon: Icons.directions_run,
      badge: 'WU',
    ),
    _PlanBlock(
      title: 'Bench press',
      details: '4 x 8 @ 60% 1RM',
      icon: Icons.fitness_center,
      badge: 'BP',
    ),
    _PlanBlock(
      title: 'Lat pulldown',
      details: '3 x 10 · Controlled tempo',
      icon: Icons.cable,
      badge: 'LP',
    ),
    _PlanBlock(
      title: 'Plank finisher',
      details: '3 x 45s · Focus on breathing',
      icon: Icons.crop_square,
      badge: 'PL',
    ),
  ];

  static const List<_PlanBlock> _upcoming = [
    _PlanBlock(
      title: 'Tempo intervals',
      details: '6 x 3 min on / 2 min off',
      icon: Icons.speed,
      badge: 'TI',
    ),
    _PlanBlock(
      title: 'Pull day',
      details: 'Rows · Pull-ups · Face pulls',
      icon: Icons.sports_gymnastics,
      badge: 'PD',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    final name = await ProgramState.loadActiveProgramName();
    if (!mounted) return;
    setState(() {
      _programName = name;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Plan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl),
            onPressed: () {},
            tooltip: 'Customize plan (coming soon)',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgram,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                    Text(
                      _loading
                          ? 'Loading plan…'
                          : (_programName ?? 'No plan selected'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Focus for today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _FocusChip(label: 'Strength'),
                        _FocusChip(label: 'Upper body'),
                        _FocusChip(label: 'Aerobic primer'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Session breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._todayPlan.map((block) => _PlanTile(block: block)),
            const SizedBox(height: 28),
            Text(
              'Upcoming anchors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._upcoming.map((block) => _PlanTile(block: block, muted: true)),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final _PlanBlock block;
  final bool muted;
  const _PlanTile({required this.block, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: muted
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer,
          child: Text(block.badge),
        ),
        title: Text(block.title),
        subtitle: Text(block.details),
        trailing: Icon(block.icon),
      ),
    );
  }
}

class _PlanBlock {
  final String title;
  final String details;
  final IconData icon;
  final String badge;
  const _PlanBlock({
    required this.title,
    required this.details,
    required this.icon,
    required this.badge,
  });
}

class _FocusChip extends StatelessWidget {
  final String label;
  const _FocusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.check_circle, size: 16),
    );
  }
}
