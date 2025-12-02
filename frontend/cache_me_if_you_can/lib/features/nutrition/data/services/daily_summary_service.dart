import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food_entry.dart';

class DailyNutritionSummary {
  final int totalCalories;
  final int targetCalories;
  final int entriesCount;

  const DailyNutritionSummary({
    required this.totalCalories,
    required this.targetCalories,
    required this.entriesCount,
  });

  static const empty = DailyNutritionSummary(
    totalCalories: 0,
    targetCalories: 0,
    entriesCount: 0,
  );
}

class DailySummaryService {
  DailySummaryService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<DailyNutritionSummary> streamFor(String uid, DateTime day) async* {
    if (uid.isEmpty) {
      yield DailyNutritionSummary.empty;
      return;
    }
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final target = await _goalFor(uid);
    final query = _db
        .collection('users')
        .doc(uid)
        .collection('nutrition_entries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end));

    await for (final snapshot in query.snapshots()) {
      final totalCalories = snapshot.docs.fold<int>(0, (sum, doc) {
        final raw = doc.data()['calories'];
        return sum + (raw is num ? raw.round() : 0);
      });
      yield DailyNutritionSummary(
        totalCalories: totalCalories,
        targetCalories: target,
        entriesCount: snapshot.size,
      );
    }
  }

  Stream<List<FoodEntry>> recentEntries(String uid, {int limit = 10}) {
    if (uid.isEmpty) {
      return Stream.value(const <FoodEntry>[]);
    }
    final query = _db
        .collection('users')
        .doc(uid)
        .collection('nutrition_entries')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FoodEntry.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<int> _goalFor(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      final target = data?['targetCalories'] ?? data?['calorieTarget'];
      if (target is num) return target.round();
    } catch (_) {}
    return 2000;
  }
}
