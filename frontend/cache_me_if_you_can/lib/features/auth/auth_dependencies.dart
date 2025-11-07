import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'domain/repositories/auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';

// Simple composition root for auth. Replace with DI later if needed.
final AuthRepository authRepository = FirebaseAuthRepository(
  auth: fb.FirebaseAuth.instance,
);
