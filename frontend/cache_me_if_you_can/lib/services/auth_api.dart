import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserRequest {
  final String name;
  final int age;
  final String gender; // e.g., 'male' | 'female | 'other'
  final String email;
  final String password;
  final double height; // cm or inches depending on backend
  final double weight; // kg or lbs depending on backend
  final String? allergies; // comma-separated or free text
  final double activityLevel; // numeric as required by backend

  CreateUserRequest({
    required this.name,
    required this.age,
    required this.gender,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
    this.allergies,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'email': email,
    'password': password,
    'height': height,
    'weight': weight,
    'allergies': allergies ?? '',
    'activity_level': activityLevel,
  };
}

class CreateUserResponse {
  final String message;
  final String uid;
  final Map<String, dynamic>? user;

  CreateUserResponse({required this.message, required this.uid, this.user});
}

class AuthApi {
  const AuthApi();

  /// Create user directly via Firebase Auth + Firestore (Spark-plan friendly).
  Future<CreateUserResponse> createUser(CreateUserRequest req) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: req.email,
      password: req.password,
    );
    await cred.user?.updateDisplayName(req.name);
    final uid = cred.user?.uid ?? '';

    // Minimal Firestore user doc for initial creation; onboarding will fill the rest
    final data = <String, dynamic>{
      'email': req.email,
      'onboarding_completed': false,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    return CreateUserResponse(message: 'User created', uid: uid, user: data);
  }
}
