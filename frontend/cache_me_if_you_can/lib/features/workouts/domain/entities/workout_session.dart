import 'strength_set.dart';

enum WorkoutSessionType { timed, strength }

class WorkoutSession {
  final String id; // Firestore id
  final String userId;
  final DateTime timestamp; // start or log time
  final WorkoutSessionType type;
  final String? activityKey; // for timed sessions (MET key)
  final int? durationMinutes; // for timed sessions
  final double? caloriesBurned; // computed
  final List<StrengthSet> sets; // for strength sessions
  final String? name; // optional display name
  final String? notes; // optional session notes
  final List<Map<String, dynamic>> exercises; // optional UI payload

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    this.activityKey,
    this.durationMinutes,
    this.caloriesBurned,
    this.sets = const [],
    this.name,
    this.notes,
    this.exercises = const [],
  });

  WorkoutSession copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    WorkoutSessionType? type,
    String? activityKey,
    int? durationMinutes,
    double? caloriesBurned,
    List<StrengthSet>? sets,
    String? name,
    String? notes,
    List<Map<String, dynamic>>? exercises,
  }) => WorkoutSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    timestamp: timestamp ?? this.timestamp,
    type: type ?? this.type,
    activityKey: activityKey ?? this.activityKey,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    sets: sets ?? this.sets,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    exercises: exercises ?? this.exercises,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'activityKey': activityKey,
    'durationMinutes': durationMinutes,
    'caloriesBurned': caloriesBurned,
    'sets': sets.map((s) => s.toMap()).toList(),
    'name': name,
    'notes': notes,
    'exercises': exercises,
  };

  static WorkoutSession fromMap(String id, Map<String, dynamic> map) {
    final typeStr = (map['type'] as String?) ?? 'timed';
    final t = WorkoutSessionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => WorkoutSessionType.timed,
    );
    final setsRaw = (map['sets'] as List?) ?? const [];
    return WorkoutSession(
      id: id,
      userId: map['userId'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      type: t,
      activityKey: map['activityKey'] as String?,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
      sets: setsRaw
          .map((e) => StrengthSet.fromMap(e as Map<String, dynamic>))
          .toList(),
      name: map['name'] as String?,
      notes: map['notes'] as String?,
      exercises: ((map['exercises'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
