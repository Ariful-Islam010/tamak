import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors (Keeping variable names to avoid breaking changes, but changing colors)
  static const Color primaryBlue = Color(0xFF00A36C); // Vibrant Green
  static const Color primaryGreen = Color(0xFF00A36C); // Vibrant Green
  static const Color primaryPurple = Color(0xFF34D399); // Lighter Green
  static const Color white = Colors.white;
  
  // Accent Colors
  static const Color accentYellow = Color(0xFFFBBF24); // Gold for badges
  static const Color accentOrange = Color(0xFFF97316); // Orange
  static const Color accentPink = Color(0xFF10B981); // Emerald Green instead of pink

  // General Colors
  static const Color backgroundColor = Color(0xFFF8F9FA); // Clean light grey/white background
  static const Color cardBackgroundColor = Colors.white; // Pure white for card backgrounds
  static const Color loginBackgroundColor = Color(0xFFE8F5E9); // Light mint/green for login/onboarding
  static const Color textColor = Color(0xFF111827); // Dark grey/black for readability on white
  static const Color textLight = Color(0xFF4B5563); // Soft light grey for secondary text
  static const Color errorColor = Color(0xFFEF4444);

  // Gradient for backgrounds (Light soft blue/green gradient)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2FE), // Light sky blue
      Color(0xFFF0FDF4), // Light mint green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper to get background BoxDecoration
  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        gradient: backgroundGradient,
      );


  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryGreen,
        tertiary: accentYellow,
        error: errorColor,
        surface: white,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.notoSansBengali(color: textColor, fontSize: 16),
        bodyMedium: GoogleFonts.notoSansBengali(color: textColor, fontSize: 14),
        labelLarge: GoogleFonts.notoSansBengali(color: white, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansBengali(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        titleTextStyle: GoogleFonts.notoSansBengali(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.notoSansBengali(
          color: textLight,
          fontSize: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        ),
        // Added margin for consistent spacing
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.notoSansBengali(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPink,
        foregroundColor: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textLight),
        hintStyle: const TextStyle(color: textLight),
      ),
    );
  }
}
