import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../mock/mock_data.dart' show fetchUserProfile;
import 'met_calorie_service.dart';

/// Provides lightweight accessors for profile-backed metrics that workouts rely on
/// (currently body weight for calorie math). Falls back to mock data when
/// Firestore is unavailable so the UI keeps working in local builds.
class UserMetricsService {
  UserMetricsService({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  /// Best-effort lookup of the user's body weight in kilograms. Returns null if
  /// nothing is stored yet.
  Future<double?> loadUserWeightKg({required String uid}) async {
    double? weightKg;
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('users').doc(uid).get();
        if (doc.exists) {
          weightKg = _extractWeightKg(doc.data());
        }
      } catch (err, stack) {
        debugPrint('UserMetricsService Firestore read failed: $err\n$stack');
      }
    }

    weightKg ??= await _loadMockWeightKg();
    return weightKg;
  }

  Future<double?> _loadMockWeightKg() async {
    try {
      final mockProfile = await fetchUserProfile();
      return _extractWeightKg(mockProfile);
    } catch (err) {
      debugPrint('UserMetricsService mock weight fallback failed: $err');
      return null;
    }
  }

  double? _extractWeightKg(Map<String, dynamic>? data) {
    if (data == null) return null;
    final maybeKg = data['weightKg'] ?? data['weight_kg'];
    if (maybeKg is num && maybeKg > 0) return maybeKg.toDouble();

    final maybeLbs = data['weightLbs'] ?? data['weight_lbs'];
    if (maybeLbs is num && maybeLbs > 0) {
      return poundsToKg(maybeLbs.toDouble());
    }

    final raw = data['weight'];
    if (raw is num && raw > 0) {
      // Assume entries larger than ~120 are pounds; otherwise treat as kg.
      return raw > 120 ? poundsToKg(raw.toDouble()) : raw.toDouble();
    }

    if (raw is Map) {
      final value = raw['value'];
      final unit = (raw['unit'] as String?)?.toLowerCase();
      if (value is num) {
        if (unit == 'kg' || unit == 'kilograms') return value.toDouble();
        if (unit == 'lb' || unit == 'lbs' || unit == 'pounds') {
          return poundsToKg(value.toDouble());
        }
      }
    }
    return null;
  }
}
