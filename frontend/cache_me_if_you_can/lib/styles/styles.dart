import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF181C2C);
  static const Color brightBlue = Color(0xFF23A6D5);
  static const Color highlightYellow = Color(0xFFFFC83D);
  static const Color lightBlue = Color(0xFF53C5F4);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: brightBlue,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme(
        primary: brightBlue,
        secondary: highlightYellow,
        surface: navy,
        // ignore: deprecated_member_use
        background: navy,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: navy,
        onSurface: Colors.white,
        // ignore: deprecated_member_use
        onBackground: Colors.white,
        onError: Colors.white,
        brightness: Brightness.dark, // for contrast on navy bg
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: highlightYellow,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: brightBlue, width: 2)),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: highlightYellow,
          fontSize: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightBlue,
          foregroundColor: navy,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: highlightYellow,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: lightBlue),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brightBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highlightYellow, width: 2),
        ),
      ),
    );
  }
}
