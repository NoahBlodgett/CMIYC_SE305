// Removed unused Platform import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unused Google sign-in import
// Removed unused Apple sign-in import
// Removed unused font_awesome_flutter import
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
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[LoginPage] build called at \\${DateTime.now()}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
      ),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_errorText != null)
                Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () async {
                        setState(() => _errorText = null);
                        if (!(_formKey.currentState?.validate() ?? false)) return;
                        setState(() => _submitting = true);
                        try {
                          await authRepository.signInWithEmail(
                            _emailCtrl.text.trim(),
                            _passwordCtrl.text,
                          );
                          if (!mounted) return;
                          // Ensure Firestore user doc exists
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                            if (!doc.exists) {
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                'email': user.email ?? _emailCtrl.text.trim(),
                                'onboarding_completed': false,
                              }, SetOptions(merge: true));
                            }
                            if (!mounted) return;
                            Navigator.of(context).pushReplacementNamed(Routes.home);
                          }
                        } on FirebaseAuthException catch (e) {
                          setState(() => _errorText = e.message ?? 'Login failed');
                        } catch (e) {
                          setState(() => _errorText = e.toString());
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                      child: _submitting
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
                    onPressed: _submitting ? null : () async {
                      await Navigator.pushNamed(context, Routes.signup);
                    },
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
