class StrengthSet {
  final int reps;
  final double? weightKg; // optional if bodyweight
  const StrengthSet({required this.reps, this.weightKg});

  Map<String, dynamic> toMap() => {'reps': reps, 'weightKg': weightKg};

  static StrengthSet fromMap(Map<String, dynamic> map) => StrengthSet(
    reps: (map['reps'] as num?)?.toInt() ?? 0,
    weightKg: (map['weightKg'] as num?)?.toDouble(),
  );
}
