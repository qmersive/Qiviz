import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6B48FF);
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color darkBackground = Color(0xFF0F0C29); // Deep dark background
  static const Color surfaceDark = Color(0xFF1E1A3C);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFA0A0B0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: electricBlue,
        surface: surfaceDark,
        error: neonPink,
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textWhite,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textGrey,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textWhite,
          elevation: 8,
          shadowColor: primaryPurple.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: textGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: electricBlue,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
