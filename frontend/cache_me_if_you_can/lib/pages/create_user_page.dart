import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/auth_api.dart';
import 'permissions_page.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'male';
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  double _activityLevel = 1.0; // 0.0 - 5.0

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
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

  String? _positiveNum(String? v) {
    if (_required(v) != null) return 'Required';
    final d = double.tryParse(v!.trim());
    if (d == null || d <= 0) return 'Must be > 0';
    return null;
  }

  String? _age(String? v) {
    if (_required(v) != null) return 'Required';
    final n = int.tryParse(v!.trim());
    if (n == null || n <= 0) return 'Invalid age';
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

      final api = AuthApi(functions: FirebaseFunctions.instance);
      final req = CreateUserRequest(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        gender: _gender,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        height: double.parse(_heightCtrl.text.trim()),
        weight: double.parse(_weightCtrl.text.trim()),
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        activityLevel: _activityLevel,
      );

      final res = await api.createUser(req);

      if (!mounted) return;
      // Optionally sign-in the user on success
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: req.email,
          password: req.password,
        );
        // Ensure the profile shows the user's name for greeting
        await FirebaseAuth.instance.currentUser?.updateDisplayName(req.name);
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // If sign-in fails (e.g., emulator not running), ignore for now
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      // After account creation, ask for permissions.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsPage()),
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
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: _age,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'other'),
              ),
              const SizedBox(height: 12),
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
              TextFormField(
                controller: _heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Height'),
                validator: _positiveNum,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Weight'),
                validator: _positiveNum,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Allergies (optional)',
                ),
              ),
              const SizedBox(height: 12),
              Text('Activity level: ${_activityLevel.toStringAsFixed(1)}'),
              Slider(
                value: _activityLevel,
                min: 0,
                max: 5,
                divisions: 50,
                onChanged: (v) => setState(() => _activityLevel = v),
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
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
