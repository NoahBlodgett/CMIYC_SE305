import 'package:flutter/material.dart';
// Removed unused Platform import
// Removed unused firebase_auth and cloud_firestore imports
// Removed unused Google sign-in import
// Removed unused Apple sign-in import
// Removed unused font_awesome_flutter import
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'package:cache_me_if_you_can/features/auth/auth_dependencies.dart';

// NOTE: AuthApi reference removed (not found in workspace). Replace with direct Firebase calls.

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
    });

    try {
      // Use repository for email/password sign-up
      final created = await authRepository.signUpWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      // Do NOT create Firestore doc here. Route directly to onboarding.
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.onboarding);
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
                      : const Text('Create account'),
                ),
              ),
              // Google/Apple sign-in UI removed
            ],
          ),
        ),
      ),
    );
  }

  // Google/Apple sign-in methods removed
}
