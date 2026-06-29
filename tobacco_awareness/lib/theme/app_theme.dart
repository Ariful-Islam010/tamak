import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === DEMON CARTOON THEME COLORS ===
  // Primary - Electric Purple/Violet (demon energy)
  static const Color primaryBlue = Color(0xFF7C3AED);   // Deep Violet
  static const Color primaryGreen = Color(0xFF8B5CF6);  // Medium Violet
  static const Color primaryPurple = Color(0xFF6D28D9); // Dark Violet

  // Accent - Neon & Vibrant (cartoon pop)
  static const Color accentYellow = Color(0xFFFBBF24);  // Golden Yellow
  static const Color accentOrange = Color(0xFFFF6B35);  // Hot Orange
  static const Color accentPink = Color(0xFFEC4899);    // Hot Pink
  static const Color accentCyan = Color(0xFF06B6D4);    // Cyan
  static const Color accentLime = Color(0xFF84CC16);    // Lime Green

  // Demon Palette
  static const Color demonDark = Color(0xFF1A0533);     // Very dark purple (bg)
  static const Color demonMid = Color(0xFF2D1B69);      // Mid dark purple
  static const Color demonLight = Color(0xFF4C1D95);    // Light purple
  static const Color demonGlow = Color(0xFFDDD6FE);     // Soft glow lavender

  // UI Colors
  static const Color white = Colors.white;
  static const Color backgroundColor = Color(0xFFF5F3FF); // Soft lavender bg
  static const Color loginBackgroundColor = Color(0xFF1A0533); // Dark bg for auth
  static const Color textColor = Color(0xFF1E1B4B);     // Deep indigo text
  static const Color textLight = Color(0xFF6B7280);     // Gray for secondary text
  static const Color errorColor = Color(0xFFEF4444);

  // === GRADIENTS ===
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [demonDark, demonMid, Color(0xFF3B1F8C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF84CC16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper BoxDecoration
  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        gradient: backgroundGradient,
      );

  // Cartoon bubble shadow
  static List<BoxShadow> get cartoonShadow => [
    const BoxShadow(
      color: Color(0x407C3AED),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.5),
      blurRadius: 25,
      offset: const Offset(0, 6),
      spreadRadius: 3,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentPink,
        tertiary: accentYellow,
        error: errorColor,
        surface: white,
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.notoSansBengali(color: textColor, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.notoSansBengali(color: textColor, fontSize: 16),
        bodyMedium: GoogleFonts.notoSansBengali(color: textColor, fontSize: 14),
        labelLarge: GoogleFonts.notoSansBengali(color: white, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: demonDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansBengali(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: primaryBlue.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
