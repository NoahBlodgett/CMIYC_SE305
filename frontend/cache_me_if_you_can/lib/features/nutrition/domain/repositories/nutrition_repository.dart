import '../entities/food_entry.dart';

abstract class NutritionRepository {
  Stream<List<FoodEntry>> entriesForDay(String uid, String day);
  Future<FoodEntry> addEntry(String uid, FoodEntry entry);
  Future<void> deleteEntry(String uid, String entryId);
  Future<void> updateEntry(String uid, FoodEntry entry);
}
