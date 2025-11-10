import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/auth/auth_dependencies.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _login() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await authRepository.signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goCreate() async {
    await Navigator.pushNamed(context, Routes.signup);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _error = null);
    setState(() => _busy = true);
    try {
      // Trigger the Google authentication flow
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(
        credential,
      ); // TODO: wrap in repository method later
      // Let AuthGate route to HomePage automatically.
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Google sign-in failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      setState(
        () =>
            _error = 'Sign in with Apple is only available on Apple platforms.',
      );
      return;
    }
    setState(() => _error = null);
    setState(() => _busy = true);
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        setState(
          () => _error = 'Sign in with Apple is not available on this device.',
        );
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
      await FirebaseAuth.instance.signInWithCredential(
        oauth,
      ); // TODO: wrap in repository method later
      // Let AuthGate route to HomePage automatically.
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Apple sign-in failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _required,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _goCreate,
                    child: const Text('Create account'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.google),
                      onPressed: _busy ? null : _signInWithGoogle,
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 8),
                SignInWithAppleButton(
                  onPressed: () {
                    if (_busy) return;
                    _signInWithApple();
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
}
