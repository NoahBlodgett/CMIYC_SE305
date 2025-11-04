import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../utils/validators.dart';
import '../utils/units.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

// Activity options as constants for readability and reuse
class _ActivityOption {
  const _ActivityOption(this.value, this.label);
  final double value;
  final String label;
}

const List<_ActivityOption> _activityOptions = [
  _ActivityOption(1.2, 'Sedentary (little or no exercise)'),
  _ActivityOption(1.375, 'Light (1–3 days/week)'),
  _ActivityOption(1.55, 'Moderate (3–5 days/week)'),
  _ActivityOption(1.725, 'Very Active (6–7 days/week)'),
  _ActivityOption(1.9, 'Extreme (very hard exercise & physical job)'),
];

class _OnboardingPageState extends State<OnboardingPage> {
  // Form & controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();

  // Height selection state
  int _feet = 5;
  int _inches = 6; // 0–11
  bool _useMetric = false; // cm vs ft/in
  int _cm = 170; // default cm when metric

  // Profile selections
  String _gender = 'male';
  double _activityLevel = 1.2;

  // UI state
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
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
      final height = _useMetric
          ? inchesFromCm(_cm)
          : inchesFromFeetInches(_feet, _inches);
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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
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
              // Username
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: requiredValidator,
              ),
              const SizedBox(height: 12),
              // Age
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: positiveIntValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'male'),
              ),
              const SizedBox(height: 12),
              // Units toggle
              Row(
                children: [
                  const Text('Units:'),
                  const SizedBox(width: 12),
                  ToggleButtons(
                    isSelected: [_useMetric == false, _useMetric == true],
                    onPressed: (index) {
                      setState(() {
                        _useMetric = (index == 1);
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ft/in'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('cm'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Height pickers
              if (!_useMetric)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Height (ft)'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160,
                            child: CupertinoPicker(
                              looping: true,
                              itemExtent: 32,
                              scrollController: FixedExtentScrollController(
                                initialItem: (_feet - 3).clamp(0, 5),
                              ),
                              onSelectedItemChanged: (i) {
                                setState(() => _feet = 3 + i);
                              },
                              children: numberTextChildren(3, 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Inches'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160,
                            child: CupertinoPicker(
                              looping: true,
                              itemExtent: 32,
                              scrollController: FixedExtentScrollController(
                                initialItem: _inches.clamp(0, 11),
                              ),
                              onSelectedItemChanged: (i) {
                                setState(() => _inches = i);
                              },
                              children: numberTextChildren(0, 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Height (cm)'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: CupertinoPicker(
                        looping: true,
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: (_cm - 100).clamp(0, 200),
                        ),
                        onSelectedItemChanged: (i) {
                          setState(() => _cm = 100 + i);
                        },
                        children: numberTextChildren(100, 220),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // Weight
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (e.g., kg)',
                ),
                validator: positiveDoubleValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Allergies (optional)',
                ),
              ),
              const SizedBox(height: 12),
              // Activity level
              DropdownButtonFormField<double>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Activity level'),
                items: _activityOptions
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.value,
                        child: Text(o.label),
                      ),
                    )
                    .toList(),
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
