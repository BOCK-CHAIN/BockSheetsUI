import 'package:flutter/material.dart';

class AppTheme {
  // Sunkist Gradient Palette
  static const Color sunkistOrange = Color(0xFFFFA500); // Vibrant orange
  static const Color sunkistYellow = Color(0xFFFFFF00); // Bright yellow
  static const Color sunkistPeach = Color(0xFFFFDAB9); // Soft peach
  static const Color sunkistGold = Color(0xFFFFD700); // Rich gold
  static const Color sunkistAmber = Color(0xFFFFBF00); // Warm amber
  
  // Accent colors
  static const Color accentLime = Color(0xFF32CD32); // Bright lime green
  static const Color accentCoral = Color(0xFFFF7F50); // Coral accent
  
  // Neutral colors
  static const Color backgroundLight = Color(0xFFFFF5E6); // Light peach background
  static const Color backgroundDark = Color(0xFF4A2C2A); // Dark brown background
  static const Color surfaceLight = Color(0xFFFFFFFF); // White surface
  static const Color surfaceDark = Color(0xFF6B4E31); // Dark tan surface
  static const Color cardLight = Color(0xFFFFF0E6); // Light orange card
  static const Color cardDark = Color(0xFF5C4033); // Dark brown card
  
  // Text colors
  static const Color textPrimary = Color(0xFF4A2C2A); // Dark brown text
  static const Color textSecondary = Color(0xFF8B4513); // Saddle brown
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textMuted = Color(0xFFC68E17); // Goldenrod muted
  
  // Grid colors
  static const Color gridLine = Color(0xFFF4A460); // Sandy brown
  static const Color gridHeaderBg = Color(0xFFFFE4B5); // Moccasin
  static const Color cellBorder = Color(0xFFDAA520); // Goldenrod
  static const Color cellSelected = Color(0xFFFFFACD); // Lemon chiffon
  static const Color cellHover = Color(0xFFFFF8DC); // Cornsilk
  
  // Status colors
  static const Color success = Color(0xFF32CD32); // Lime green for success
  static const Color warning = Color(0xFFFFA500); // Sunkist orange for warning
  static const Color error = Color(0xFFFF4500); // Orange red for error
  static const Color info = Color(0xFFFFD700); // Sunkist gold for info

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: sunkistOrange,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: sunkistOrange,
      secondary: sunkistYellow,
      tertiary: sunkistGold,
      surface: surfaceLight,
      background: backgroundLight,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: surfaceLight,
      foregroundColor: textPrimary,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardLight,
      shadowColor: sunkistAmber.withOpacity(0.1),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: sunkistOrange,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: sunkistYellow,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Icon Button Theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSecondary,
        hoverColor: cellHover,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: gridLine, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: gridLine, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: sunkistOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textMuted),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: sunkistYellow,
      foregroundColor: Colors.black,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: gridLine,
      thickness: 1,
      space: 1,
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: sunkistGold,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: sunkistAmber,
      secondary: sunkistPeach,
      tertiary: sunkistYellow,
      surface: surfaceDark,
      background: backgroundDark,
      error: error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textLight,
      onBackground: textLight,
    ),
    
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: surfaceDark,
      foregroundColor: textLight,
      iconTheme: IconThemeData(color: textLight),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardDark,
    ),
  );

  // Gradient Styles
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunkistOrange, sunkistYellow],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunkistGold, sunkistPeach],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, surfaceLight],
  );

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: sunkistAmber.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: sunkistOrange.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}