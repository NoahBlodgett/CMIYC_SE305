import 'package:cloud_firestore/cloud_firestore.dart';
import 'domain/repositories/nutrition_repository.dart';
import 'data/repositories/firestore_nutrition_repository.dart';
import 'data/services/nutrition_ai_service.dart';

final NutritionRepository nutritionRepository = FirestoreNutritionRepository(
  db: FirebaseFirestore.instance,
);

// Configure baseUrl for ML service via --dart-define=ML_API_BASE=http://<LAN-IP>:<port>
const _mlBase = String.fromEnvironment(
  'ML_API_BASE',
  defaultValue: 'http://localhost:8000',
);
final NutritionAiService nutritionAiService = NutritionAiService(
  baseUrl: _mlBase,
);
