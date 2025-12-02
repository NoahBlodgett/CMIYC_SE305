import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_summary.dart';

class WorkoutFeedbackService {
  WorkoutFeedbackService({required FirebaseFirestore db}) : _db = db;

  final FirebaseFirestore _db;

  Future<void> submitFeedback({
    required String featureKey,
    required int rating,
    String? comment,
    String? userId,
  }) async {
    final safeRating = rating.clamp(1, 5);
    await _db.collection('workout_feedback').add({
      'feature': featureKey,
      'rating': safeRating,
      'comment': comment?.trim(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FeedbackSummary>> watchSummaries({int sampleComments = 3}) {
    return _db
        .collection('workout_feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final buckets = <String, _FeedbackAggregate>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final feature = (data['feature'] as String?)?.trim();
            if (feature == null || feature.isEmpty) continue;
            final rating = (data['rating'] as num?)?.toDouble();
            if (rating == null) continue;
            final comment = (data['comment'] as String?)?.trim();
            final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
            final agg = buckets.putIfAbsent(
              feature,
              () => _FeedbackAggregate(),
            );
            agg.totalRating += rating;
            agg.count += 1;
            if (timestamp != null) {
              if (agg.lastResponseAt == null ||
                  timestamp.isAfter(agg.lastResponseAt!)) {
                agg.lastResponseAt = timestamp;
              }
            }
            if (comment != null &&
                comment.isNotEmpty &&
                agg.sampleComments.length < sampleComments) {
              agg.sampleComments.add(comment);
            }
          }
          final summaries = buckets.entries.map((entry) {
            final agg = entry.value;
            final double avg = agg.count == 0 ? 0.0 : agg.totalRating / agg.count;
            return FeedbackSummary(
              featureKey: entry.key,
              averageRating: avg,
              responsesCount: agg.count,
              lastResponseAt: agg.lastResponseAt,
              sampleComments: List.unmodifiable(agg.sampleComments),
            );
          }).toList();
          summaries.sort((a, b) {
            final aTime =
                a.lastResponseAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.lastResponseAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return summaries;
        });
  }
}

class _FeedbackAggregate {
  double totalRating = 0;
  int count = 0;
  DateTime? lastResponseAt;
  final List<String> sampleComments = [];
}
