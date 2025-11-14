class DayPlan {
  final int dayIndex; // 0-based
  final bool isRest;
  final List<String> exercises; // simple list for now
  const DayPlan({
    required this.dayIndex,
    required this.isRest,
    this.exercises = const [],
  });

  DayPlan copyWith({int? dayIndex, bool? isRest, List<String>? exercises}) =>
      DayPlan(
        dayIndex: dayIndex ?? this.dayIndex,
        isRest: isRest ?? this.isRest,
        exercises: exercises ?? this.exercises,
      );

  Map<String, dynamic> toMap() => {
    'dayIndex': dayIndex,
    'isRest': isRest,
    'exercises': exercises,
  };
  static DayPlan fromMap(Map<String, dynamic> map) => DayPlan(
    dayIndex: (map['dayIndex'] as num?)?.toInt() ?? 0,
    isRest: (map['isRest'] as bool?) ?? false,
    exercises:
        (map['exercises'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}

class Program {
  final String id; // local or firestore id (future)
  final String name;
  final List<DayPlan> days; // length 1..14
  const Program({required this.id, required this.name, required this.days});

  int get length => days.length;

  Program copyWith({String? id, String? name, List<DayPlan>? days}) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    days: days ?? this.days,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'days': days.map((d) => d.toMap()).toList(),
  };

  static Program fromMap(Map<String, dynamic> map) => Program(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Unnamed',
    days:
        (map['days'] as List?)
            ?.map((e) => DayPlan.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
