import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cache_me_if_you_can/features/nutrition/nutrition_dependencies.dart';
import 'package:cache_me_if_you_can/features/nutrition/domain/entities/food_entry.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  DateTime _day = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<FoodEntry> _aiSuggestions = const [];
  bool _loadingAi = false;
  String? _aiError;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final dayStr = FoodEntry.formatDay(_day);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add food',
            onPressed: () => _showAddEntry(context, uid, dayStr),
          ),
        ],
      ),
      body: Column(
        children: [
          _DayNavigator(
            day: _day,
            onPrev: () =>
                setState(() => _day = _day.subtract(const Duration(days: 1))),
            onNext: () =>
                setState(() => _day = _day.add(const Duration(days: 1))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingAi
                        ? null
                        : () => _generateAiPlan(uid, dayStr),
                    icon: const Icon(Icons.auto_awesome),
                    label: _loadingAi
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate AI Plan'),
                  ),
                ),
              ],
            ),
          ),
          if (_aiError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _aiError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<FoodEntry>>(
              stream: nutritionRepository.entriesForDay(uid, dayStr),
              builder: (context, snap) {
                final entries = snap.data ?? const [];
                final totals = _totals(entries);
                if (snap.connectionState == ConnectionState.waiting &&
                    entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MacroSummaryCard(
                      calories: totals['cal']!,
                      protein: totals['pro']!,
                      carbs: totals['car']!,
                      fat: totals['fat']!,
                    ),
                    if (_aiSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Suggested Plan',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _aiSuggestions = const [],
                                    ),
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (final s in _aiSuggestions)
                                ListTile(
                                  dense: true,
                                  title: Text(s.name),
                                  subtitle: Text(
                                    '${s.calories.toStringAsFixed(0)} kcal  ·  P ${s.protein.toStringAsFixed(0)}  C ${s.carbs.toStringAsFixed(0)}  F ${s.fat.toStringAsFixed(0)}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Add to day',
                                    icon: const Icon(Icons.arrow_downward),
                                    onPressed: () async {
                                      await nutritionRepository.addEntry(
                                        uid,
                                        s,
                                      );
                                      setState(
                                        () => _aiSuggestions = _aiSuggestions
                                            .where((e) => e != s)
                                            .toList(),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _MealSection(
                      title: 'Breakfast',
                      entries: entries
                          .where((e) => e.mealType == 'breakfast')
                          .toList(),
                      onDelete: (id) =>
                          nutritionRepository.deleteEntry(uid, id),
                    ),
                    _MealSection(
                      title: 'Lunch',
                      entries: entries
                          .where((e) => e.mealType == 'lunch')
                          .toList(),
                      onDelete: (id) =>
                          nutritionRepository.deleteEntry(uid, id),
                    ),
                    _MealSection(
                      title: 'Dinner',
                      entries: entries
                          .where((e) => e.mealType == 'dinner')
                          .toList(),
                      onDelete: (id) =>
                          nutritionRepository.deleteEntry(uid, id),
                    ),
                    _MealSection(
                      title: 'Snacks',
                      entries: entries
                          .where((e) => e.mealType == 'snack')
                          .toList(),
                      onDelete: (id) =>
                          nutritionRepository.deleteEntry(uid, id),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _totals(List<FoodEntry> entries) {
    double cal = 0, pro = 0, car = 0, fat = 0;
    for (final e in entries) {
      cal += e.calories;
      pro += e.protein;
      car += e.carbs;
      fat += e.fat;
    }
    return {'cal': cal, 'pro': pro, 'car': car, 'fat': fat};
  }

  Future<void> _showAddEntry(
    BuildContext context,
    String uid,
    String day,
  ) async {
    final res = await showModalBottomSheet<_EntryFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _AddEntrySheet(),
      ),
    );
    if (res == null) return;
    final entry = FoodEntry(
      id: '',
      timestamp: DateTime.now(),
      day: day,
      name: res.name,
      mealType: res.mealType,
      calories: res.calories,
      protein: res.protein,
      carbs: res.carbs,
      fat: res.fat,
    );
    await nutritionRepository.addEntry(uid, entry);
  }

  Future<void> _generateAiPlan(String uid, String day) async {
    setState(() {
      _loadingAi = true;
      _aiError = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      double? heightIn = (data['Height_in'] as num?)?.toDouble();
      double? weightLb = (data['Weight_lb'] as num?)?.toDouble();
      int? age = (data['Age'] as num?)?.toInt();
      int? gender = (data['Gender'] as num?)?.toInt();
      int? activityLevel = (data['Activity_Level'] as num?)?.toInt();
      int? goal = (data['Goal'] as num?)?.toInt();
      final List<String> allergies =
          (data['allergies'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      final List<String> preferences =
          (data['preferences'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      if (heightIn == null ||
          weightLb == null ||
          age == null ||
          gender == null ||
          activityLevel == null ||
          goal == null) {
        throw StateError(
          'Missing profile fields. Update profile to use AI planner.',
        );
      }
      final result = await nutritionAiService.generatePlan(
        heightIn: heightIn,
        weightLb: weightLb,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
        allergies: allergies,
        preferences: preferences,
      );
      final calTarget = _extractCalorieTarget(result.nutritionTargets);
      if (calTarget != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'calorie_target': calTarget,
        }, SetOptions(merge: true));
      }
      final previewEntries = nutritionAiService.toEntries(
        result.previewFoods,
        day,
        'lunch',
      );
      setState(() => _aiSuggestions = previewEntries);
    } catch (e) {
      setState(() => _aiError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  double? _extractCalorieTarget(Map<String, double> targets) {
    if (targets.isEmpty) return null;
    double? pick(String key) => targets.entries
        .firstWhere(
          (e) => e.key.toLowerCase() == key,
          orElse: () => const MapEntry('', 0.0),
        )
        .value;
    for (final k in ['calories', 'kcal', 'calorie_target', 'energy']) {
      final v = pick(k);
      if (v != 0.0) return v;
    }
    return targets.values.isEmpty
        ? null
        : targets.values.reduce((a, b) => a > b ? a : b);
  }
}

class _DayNavigator extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _DayNavigator({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label =
        '${w[day.weekday - 1]}, ${m[day.month - 1]} ${day.day}, ${day.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  const _MacroSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's totals",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macro('Calories', calories, suffix: 'kcal'),
                _macro('Protein', protein, suffix: 'g'),
                _macro('Carbs', carbs, suffix: 'g'),
                _macro('Fat', fat, suffix: 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, double value, {String? suffix}) {
    return Column(
      children: [
        Text(value.toStringAsFixed(0) + (suffix ?? '')),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<FoodEntry> entries;
  final Future<void> Function(String id) onDelete;
  const _MealSection({
    required this.title,
    required this.entries,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty) const Text('No items'),
            for (final e in entries)
              ListTile(
                dense: true,
                title: Text(e.name),
                subtitle: Text(
                  '${e.calories.toStringAsFixed(0)} kcal  ·  P ${e.protein.toStringAsFixed(0)}  C ${e.carbs.toStringAsFixed(0)}  F ${e.fat.toStringAsFixed(0)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(e.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();
  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _pro = TextEditingController();
  final _car = TextEditingController();
  final _fat = TextEditingController();
  String _meal = 'breakfast';
  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _pro.dispose();
    _car.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Food name'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _meal,
                items: const [
                  DropdownMenuItem(
                    value: 'breakfast',
                    child: Text('Breakfast'),
                  ),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (v) => setState(() => _meal = v ?? 'breakfast'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pro,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _car,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _name.text.trim();
                final cal = double.tryParse(_cal.text) ?? 0;
                final pro = double.tryParse(_pro.text) ?? 0;
                final car = double.tryParse(_car.text) ?? 0;
                final fat = double.tryParse(_fat.text) ?? 0;
                Navigator.pop(
                  context,
                  _EntryFormResult(
                    name: name,
                    mealType: _meal,
                    calories: cal,
                    protein: pro,
                    carbs: car,
                    fat: fat,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryFormResult {
  final String name;
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  const _EntryFormResult({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
