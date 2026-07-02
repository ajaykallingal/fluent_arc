import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Custom Harmonized Colors (Indigo, Violet, Rose & Cyan)
  static const Color primaryLight = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryDark = Color(0xFF818CF8); // Neon Indigo

  static const Color secondaryLight = Color(0xFF7C3AED); // Royal Violet
  static const Color secondaryDark = Color(0xFFA78BFA); // Pastel Violet

  static const Color tertiaryLight = Color(0xFF0D9488); // Teal
  static const Color tertiaryDark = Color(0xFF2DD4BF); // Neon Cyan

  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFF87171);

  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: tertiaryLight,
        error: errorLight,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: const Color(0x1F000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorLight, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        tertiary: tertiaryDark,
        error: errorDark,
        surface: surfaceDark,
        onPrimary: Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onTertiary: Color(0xFF0F172A),
        onSurface: Color(0xFFF8FAFC),
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: const Color(0x3D000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryDark,
          foregroundColor: const Color(0xFF0F172A),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155), // Slate 700
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorDark, width: 1.5),
        ),
      ),
    );
  }
}
