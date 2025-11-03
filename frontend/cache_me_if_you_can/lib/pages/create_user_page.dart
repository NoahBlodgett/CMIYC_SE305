import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/auth_api.dart';
import 'onboarding_page.dart';
// import 'permissions_page.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _email(String? v) {
    if (_required(v) != null) return 'Required';
    final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!rx.hasMatch(v!.trim())) return 'Invalid email';
    return null;
  }

  String? _password(String? v) {
    if (_required(v) != null) return 'Required';
    if ((v ?? '').length < 6) return 'Min 6 chars';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _errorText = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });

    try {
      // Ensure Firebase initialized
      await Firebase.initializeApp();
      // If using emulators, they'll be configured in main.dart

      final api = AuthApi();
      final res = await api.createUser(
        CreateUserRequest(
          name: '',
          age: 0,
          gender: 'other',
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          height: 0,
          weight: 0,
          allergies: '',
          activityLevel: 0,
        ),
      );

      if (!mounted) return;
      // Optionally sign-in the user on success
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // If sign-in fails (e.g., emulator not running), ignore for now
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      // After account creation, go to onboarding to collect remaining details.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    } catch (e) {
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _password,
              ),
              const SizedBox(height: 12),
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account with email'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata),
                      onPressed: _submitting ? null : _createWithGoogle,
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 8),
                SignInWithAppleButton(
                  onPressed: () {
                    if (_submitting) return;
                    _createWithApple();
                  },
                  style: SignInWithAppleButtonStyle.black,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createWithGoogle() async {
    setState(() => _errorText = null);
    setState(() => _submitting = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // canceled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = cred.user;
      if (user != null) {
        // Ensure minimal user doc exists
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? _emailCtrl.text.trim(),
          'onboarding_completed': false,
        }, SetOptions(merge: true));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message ?? 'Google sign-in failed');
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      setState(() => _errorText = 'Apple sign-in is only available on Apple');
      return;
    }
    setState(() => _errorText = null);
    setState(() => _submitting = true);
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        setState(() => _errorText = 'Sign in with Apple not available');
        return;
      }
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(oauth);
      final user = cred.user;
      if (user != null) {
        final display = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((e) => (e ?? '').isNotEmpty).join(' ');
        if (display.isNotEmpty) {
          await user.updateDisplayName(display);
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'onboarding_completed': false,
        }, SetOptions(merge: true));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message ?? 'Apple sign-in failed');
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
