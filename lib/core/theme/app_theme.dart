import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant Neon Palette
  static const Color darkBackground = Color(0xFF09090B);
  static const Color surfaceDark = Color(0xFF18181B);
  
  static const Color electricBlue = Color(0xFF00D2FF);
  static const Color neonPink = Color(0xFFFE0192);
  static const Color acidGreen = Color(0xFF39FF14);
  static const Color primaryPurple = Color(0xFF7000FF);
  
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFA1A1AA);

  // Gradients for that "High Dimensional" feel
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient viralGradient = LinearGradient(
    colors: [neonPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [acidGreen, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: electricBlue,
      colorScheme: const ColorScheme.dark(
        primary: electricBlue,
        secondary: neonPink,
        surface: surfaceDark,
      ),
    );
  }
}
