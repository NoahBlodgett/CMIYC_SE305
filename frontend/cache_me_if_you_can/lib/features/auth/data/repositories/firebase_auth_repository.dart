import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  FirebaseAuthRepository({fb.FirebaseAuth? auth})
    : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toDomain);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Sign-in returned no user');
    }
    return _toDomain(user)!;
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Sign-up returned no user');
    }
    return _toDomain(user)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _toDomain(fb.User? u) => u == null
      ? null
      : AuthUser(uid: u.uid, email: u.email, displayName: u.displayName);
}
