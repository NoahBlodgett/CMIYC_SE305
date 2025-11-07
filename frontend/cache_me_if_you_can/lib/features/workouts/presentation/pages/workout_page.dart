import 'package:flutter/material.dart';
import '../../../../mock/mock_data.dart';
import '../../../../utils/program_state.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String? _currentProgramName;
  List<String> _recentPrograms = const [];
  bool _recentOpen = false;
  bool _newOpen = false;

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
      appBar: AppBar(title: const Text('Workouts'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionHeader(
            icon: Icons.calendar_month_sharp,
            title: 'Program',
            tint: color.primary,
          ),
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentProgramName ?? 'No active program',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active program',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Recent programs',
                    onOpened: () => setState(() => _recentOpen = true),
                    onCanceled: () => setState(() => _recentOpen = false),
                    onSelected: (selected) async {
                      setState(() => _recentOpen = false);
                      if (selected == '__view_all__') {
                        await _onViewRecentPrograms();
                        return;
                      }
                      if (selected.isNotEmpty && selected != '__none__') {
                        await ProgramState.saveActiveProgramName(selected);
                        if (mounted) {
                          setState(() => _currentProgramName = selected);
                        }
                      }
                    },
                    itemBuilder: (context) {
                      if (_recentPrograms.isEmpty) {
                        return const [
                          PopupMenuItem<String>(
                            enabled: false,
                            value: '__none__',
                            child: Text('No recent programs'),
                          ),
                        ];
                      }
                      return [
                        ..._recentPrograms.map(
                          (p) => PopupMenuItem<String>(
                            value: p,
                            child: Text(
                              p,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 8),
                        const PopupMenuItem<String>(
                          value: '__view_all__',
                          child: Text('View all'),
                        ),
                      ];
                    },
                    icon: Icon(
                      _recentOpen ? Icons.close : Icons.dehaze,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'New program',
                    onOpened: () => setState(() => _newOpen = true),
                    onCanceled: () => setState(() => _newOpen = false),
                    onSelected: (selected) async {
                      setState(() => _newOpen = false);
                      switch (selected) {
                        case 'ai':
                          await _onCreateAiProgram();
                          break;
                        case 'build':
                          await _onBuildProgram();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'ai',
                        child: Text('New AI Program'),
                      ),
                      PopupMenuItem<String>(
                        value: 'build',
                        child: Text('Build Program'),
                      ),
                    ],
                    icon: Icon(_newOpen ? Icons.close : Icons.add, size: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            icon: Icons.today_outlined,
            title: "Today's plan",
            tint: color.tertiary,
          ),
          _SectionCard(
            child: Column(
              children: [
                _ExerciseTile(title: 'Warm-up jog', details: '10 min · Easy'),
                const Divider(height: 1),
                _ExerciseTile(title: 'Bench press', details: '4 x 8 @ 60%'),
                const Divider(height: 1),
                _ExerciseTile(title: 'Lat pulldown', details: '3 x 10'),
                const Divider(height: 1),
                _ExerciseTile(title: 'Plank', details: '3 x 45s'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            icon: Icons.history,
            title: 'Recent sessions',
            tint: color.secondary,
          ),
          _SectionCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final items = [
                  ('Upper body', '45 min · 520 kcal'),
                  ('Legs & core', '38 min · 430 kcal'),
                  ('HIIT cardio', '22 min · 310 kcal'),
                ];
                final (title, meta) = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.primary.withValues(alpha: 0.15),
                    child: Icon(Icons.check, color: color.primary),
                  ),
                  title: Text(title),
                  subtitle: Text(meta),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                );
              },
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
      setState(() => _currentProgramName = selected);
    }
  }

  Future<void> _onCreateAiProgram() async {
    final created = await Navigator.pushNamed<String>(
      context,
      Routes.workoutAi,
    );
    if (created != null && mounted) {
      setState(() => _currentProgramName = created);
    }
  }

  Future<void> _onBuildProgram() async {
    final built = await Navigator.pushNamed<String>(
      context,
      Routes.workoutBuild,
    );
    if (built != null && mounted) {
      setState(() => _currentProgramName = built);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color tint;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
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
  const _ExerciseTile({required this.title, required this.details});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(details),
      trailing: const Icon(Icons.more_horiz),
      onTap: () {},
    );
  }
}
