import 'package:flutter/widgets.dart';

// Height conversions
int inchesFromFeetInches(int feet, int inches) => feet * 12 + inches;
int inchesFromCm(int cm) => (cm / 2.54).round();

// UI helpers
List<Widget> numberTextChildren(int start, int end) {
  // inclusive range
  return [for (int i = start; i <= end; i++) Text('$i')];
}
