import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  final String id;
  final String name;
  final double calories;
  final String mealType;
  final DateTime timestamp;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.timestamp,
  });

  factory FoodEntry.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime ts;
    if (rawTimestamp is DateTime) {
      ts = rawTimestamp;
    } else if (rawTimestamp is Timestamp) {
      ts = rawTimestamp.toDate();
    } else if (rawTimestamp is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else {
      ts = DateTime.now();
    }
    return FoodEntry(
      id: id,
      name: (data['name'] ?? 'Meal').toString(),
      calories: (data['calories'] is num)
          ? (data['calories'] as num).toDouble()
          : double.tryParse(data['calories']?.toString() ?? '') ?? 0,
      mealType: (data['mealType'] ?? 'Meal').toString(),
      timestamp: ts,
    );
  }
}
