import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'permissions_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightFeetCtrl = TextEditingController();
  final _heightInchesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  String _gender = 'other';
  double _activityLevel = 1.2; // maps from dropdown labels

  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _intValidator(String? v) {
    if (_required(v) != null) return 'Required';
    final n = int.tryParse(v!.trim());
    if (n == null || n <= 0) return 'Must be a positive number';
    return null;
  }

  String? _doubleValidator(String? v) {
    if (_required(v) != null) return 'Required';
    final d = double.tryParse(v!.trim());
    if (d == null || d <= 0) return 'Must be > 0';
    return null;
  }

  String? _inchesValidator(String? v) {
    if (_required(v) != null) return 'Required';
    final n = int.tryParse(v!.trim());
    if (n == null || n < 0 || n > 11) return '0-11 only';
    return null;
  }

  Future<void> _save() async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _errorText = 'Not signed in');
        return;
      }
      final name = _nameCtrl.text.trim();
      final age = int.parse(_ageCtrl.text.trim());
      final feet = int.parse(_heightFeetCtrl.text.trim());
      final inches = int.parse(_heightInchesCtrl.text.trim());
      final height = feet * 12 + inches; // total inches for backend
      final weight = double.parse(_weightCtrl.text.trim());
      final allergies = _allergiesCtrl.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'age': age,
        'gender': _gender,
        'height': height,
        'weight': weight,
        if (allergies.isNotEmpty) 'allergies': allergies, // optional
        'activity_level': _activityLevel,
        'onboarding_completed': true,
      }, SetOptions(merge: true));

      // Keep FirebaseAuth displayName in sync for greetings
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsPage()),
      );
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: _intValidator,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (ft)',
                      ),
                      // Require feet to be a positive integer
                      validator: _intValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Inches (0-11)',
                      ),
                      validator: _inchesValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (e.g., kg)',
                ),
                validator: _doubleValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Allergies (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Activity level'),
                items: const [
                  DropdownMenuItem(
                    value: 1.2,
                    child: Text('Sedentary (little or no exercise)'),
                  ),
                  DropdownMenuItem(
                    value: 1.375,
                    child: Text('Light (1–3 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 1.55,
                    child: Text('Moderate (3–5 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 1.725,
                    child: Text('Very Active (6–7 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 1.9,
                    child: Text('Extreme (very hard exercise & physical job)'),
                  ),
                ],
                onChanged: (v) => setState(() => _activityLevel = v ?? 1.2),
              ),
              const SizedBox(height: 16),
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish onboarding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
