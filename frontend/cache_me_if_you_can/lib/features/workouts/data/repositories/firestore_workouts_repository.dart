import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workouts_repository.dart';

class FirestoreWorkoutsRepository implements WorkoutsRepository {
  final FirebaseFirestore _db;
  FirestoreWorkoutsRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('workout_sessions');

  @override
  Future<WorkoutSession> addSession(String uid, WorkoutSession session) async {
    final map = session.toMap();
    final doc = await _col(uid).add(map);
    return session.copyWith(id: doc.id);
  }

  @override
  Stream<List<WorkoutSession>> recentSessions(String uid, {int limit = 10}) {
    return _col(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => WorkoutSession.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
