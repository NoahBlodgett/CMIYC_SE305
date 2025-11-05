// Reusable form validators for the app.

String? requiredValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  return null;
}

String? positiveIntValidator(String? v) {
  final r = requiredValidator(v);
  if (r != null) return r;
  final n = int.tryParse(v!.trim());
  if (n == null || n <= 0) return 'Must be a positive number';
  return null;
}

String? positiveDoubleValidator(String? v) {
  final r = requiredValidator(v);
  if (r != null) return r;
  final d = double.tryParse(v!.trim());
  if (d == null || d <= 0) return 'Must be > 0';
  return null;
}
