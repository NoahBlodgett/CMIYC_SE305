import 'package:cloud_firestore/cloud_firestore.dart';

class DailyWorkoutCaloriesSummary {
	final double totalCalories;
	final int sessionsCount;

	const DailyWorkoutCaloriesSummary({
		required this.totalCalories,
		required this.sessionsCount,
	});

	static const empty = DailyWorkoutCaloriesSummary(
		totalCalories: 0,
		sessionsCount: 0,
	);
}

class DailyWorkoutCaloriesService {
	DailyWorkoutCaloriesService({FirebaseFirestore? db})
			: _db = db ?? FirebaseFirestore.instance;

	final FirebaseFirestore _db;

	Stream<DailyWorkoutCaloriesSummary> streamFor(String uid, DateTime day) {
		if (uid.isEmpty) {
			return Stream.value(DailyWorkoutCaloriesSummary.empty);
		}
		final start = DateTime(day.year, day.month, day.day);
		final end = start.add(const Duration(days: 1));

		final query = _db
				.collection('users')
				.doc(uid)
				.collection('workout_sessions')
				.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
				.where('date', isLessThan: Timestamp.fromDate(end));

		return query.snapshots().map((snapshot) {
			double total = 0;
			for (final doc in snapshot.docs) {
				final data = doc.data();
				final calories = data['calories_burned'] ?? data['cals_burned'];
				if (calories is num) {
					total += calories.toDouble();
				}
			}
			return DailyWorkoutCaloriesSummary(
				totalCalories: double.parse(total.toStringAsFixed(2)),
				sessionsCount: snapshot.size,
			);
		});
	}
}