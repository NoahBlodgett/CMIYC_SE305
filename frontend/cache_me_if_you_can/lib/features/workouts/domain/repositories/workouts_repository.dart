import '../entities/workout_session.dart';

abstract class WorkoutsRepository {
  Future<WorkoutSession> addSession(String uid, WorkoutSession session);
  Stream<List<WorkoutSession>> recentSessions(String uid, {int limit});
}
