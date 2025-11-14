import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/food_entry.dart';

class DailySummary {
  final int totalCalories;
  final int targetCalories;
  final int entriesCount;
  const DailySummary({
    required this.totalCalories,
    required this.targetCalories,
    required this.entriesCount,
  });
}

class DailySummaryService {
  final FirebaseFirestore _db;
  DailySummaryService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  String formatDay(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Stream<DailySummary> streamFor(String uid, DateTime day) {
    final dayStr = formatDay(day);
    final entries = _db
        .collection('users')
        .doc(uid)
        .collection('nutrition_entries')
        .where('day', isEqualTo: dayStr)
        .snapshots();
    final userDoc = _db.collection('users').doc(uid).snapshots();

    return StreamZip2(entries, userDoc).map((pair) {
      final qs = pair.$1;
      final doc = pair.$2;
      int total = 0;
      for (final d in qs.docs) {
        total += ((d.data()['calories'] as num?)?.toDouble() ?? 0).round();
      }
      final target = (doc.data()?['calorie_target'] as num?)?.toInt() ?? 2500;
      return DailySummary(
        totalCalories: total,
        targetCalories: target,
        entriesCount: qs.docs.length,
      );
    });
  }

  /// Recent nutrition entries across all days for activity feeds.
  Stream<List<FoodEntry>> recentEntries(String uid, {int limit = 5}) {
    final qs = _db
        .collection('users')
        .doc(uid)
        .collection('nutrition_entries')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
    return qs.map(
      (snap) => snap.docs
          .map((d) => FoodEntry.fromMap(d.id, d.data()))
          .toList(growable: false),
    );
  }
}

// Simple helper to zip two streams without external deps.
class StreamZip2<A, B> extends Stream<(A, B)> {
  final Stream<A> _a;
  final Stream<B> _b;
  StreamZip2(this._a, this._b);
  @override
  StreamSubscription<(A, B)> listen(
    void Function((A, B) event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late StreamController<(A, B)> controller;
    A? latestA;
    B? latestB;
    bool hasA = false;
    bool hasB = false;
    bool doneA = false;
    bool doneB = false;
    void tryEmit() {
      if (hasA && hasB) controller.add((latestA as A, latestB as B));
    }

    controller = StreamController<(A, B)>(
      onListen: () {
        final subA = _a.listen(
          (a) {
            latestA = a;
            hasA = true;
            tryEmit();
          },
          onError: controller.addError,
          onDone: () {
            doneA = true;
            if (doneB) controller.close();
          },
        );
        final subB = _b.listen(
          (b) {
            latestB = b;
            hasB = true;
            tryEmit();
          },
          onError: controller.addError,
          onDone: () {
            doneB = true;
            if (doneA) controller.close();
          },
        );
        controller.onCancel = () {
          subA.cancel();
          subB.cancel();
        };
      },
    );
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
