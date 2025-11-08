import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/nutrition_repository.dart';

class FirestoreNutritionRepository implements NutritionRepository {
  final FirebaseFirestore _db;
  FirestoreNutritionRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('nutrition_entries');

  @override
  Stream<List<FoodEntry>> entriesForDay(String uid, String day) {
    return _col(uid)
        .where('day', isEqualTo: day)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FoodEntry.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<FoodEntry> addEntry(String uid, FoodEntry entry) async {
    final data = entry.toMap();
    final ref = await _col(uid).add(data);
    return entry.copyWith(id: ref.id);
  }

  @override
  Future<void> deleteEntry(String uid, String entryId) =>
      _col(uid).doc(entryId).delete();

  @override
  Future<void> updateEntry(String uid, FoodEntry entry) =>
      _col(uid).doc(entry.id).update(entry.toMap());
}
