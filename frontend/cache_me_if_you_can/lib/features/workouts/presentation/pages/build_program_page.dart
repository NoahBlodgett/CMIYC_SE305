import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/features/workouts/domain/entities/program.dart';
import '../../../../utils/program_state.dart';

class BuildProgramPage extends StatefulWidget {
  const BuildProgramPage({super.key});

  @override
  State<BuildProgramPage> createState() => _BuildProgramPageState();
}

class _BuildProgramPageState extends State<BuildProgramPage> {
  final _nameCtrl = TextEditingController();
  int _days = 7; // default one week
  late List<DayPlan> _plans; // dynamic list length _days

  @override
  void initState() {
    super.initState();
    _plans = List.generate(
      _days,
      (i) => DayPlan(dayIndex: i, isRest: i == 6, exercises: const []),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build Program')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Program name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _days,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                    ),
                    items: [7, 8, 9, 10, 11, 12, 13, 14]
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text('$d')),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _days = val;
                        _plans = List.generate(
                          _days,
                          (i) => i < _plans.length
                              ? _plans[i].copyWith(dayIndex: i)
                              : DayPlan(dayIndex: i, isRest: false),
                        );
                        if (_plans.length > _days) {
                          _plans = _plans.take(_days).toList();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                  onPressed: _days >= 14
                      ? null
                      : () {
                          setState(() {
                            _plans.add(
                              DayPlan(dayIndex: _plans.length, isRest: false),
                            );
                            _days = _plans.length;
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, i) {
                  final plan = _plans[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Day ${i + 1}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Switch(
                                value: plan.isRest,
                                onChanged: (v) => setState(
                                  () => _plans[i] = plan.copyWith(
                                    isRest: v,
                                    exercises: v ? const [] : plan.exercises,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(plan.isRest ? 'Rest' : 'Active'),
                            ],
                          ),
                          if (!plan.isRest) ...[
                            const SizedBox(height: 8),
                            for (int ex = 0; ex < plan.exercises.length; ex++)
                              _ExerciseRow(
                                initial: plan.exercises[ex],
                                onChanged: (val) {
                                  final list = [...plan.exercises];
                                  list[ex] = val;
                                  _plans[i] = plan.copyWith(exercises: list);
                                },
                                onDelete: () {
                                  final list = [...plan.exercises];
                                  list.removeAt(ex);
                                  setState(
                                    () => _plans[i] = plan.copyWith(
                                      exercises: list,
                                    ),
                                  );
                                },
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Exercise'),
                                onPressed: () {
                                  setState(
                                    () => _plans[i] = plan.copyWith(
                                      exercises: [...plan.exercises, ''],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save Program'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    // Clean blank exercises
    final cleaned = _plans
        .map(
          (p) => p.isRest
              ? p.copyWith(exercises: const [])
              : p.copyWith(
                  exercises: p.exercises
                      .where((e) => e.trim().isNotEmpty)
                      .toList(),
                ),
        )
        .toList();
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Custom Program'
        : _nameCtrl.text.trim();
    final program = Program(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      days: cleaned,
    );
    await ProgramState.saveProgram(program);
    if (mounted) Navigator.pop(context, name);
  }
}

class _ExerciseRow extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  const _ExerciseRow({
    required this.initial,
    required this.onChanged,
    required this.onDelete,
  });
  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Exercise (e.g. Squat 3x8)',
                border: OutlineInputBorder(),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
