import 'package:flutter/material.dart';

/// Application theme configuration
/// 
/// This class provides the app's theme configuration, including colors,
/// typography, and Material 3 theming. The app uses a dark theme with
/// a telemagenta primary color for a modern, transit-focused aesthetic.
class AppTheme {
  /// Primary brand color: Telemagenta (#CF3476)
  /// 
  /// This color is used for primary actions, highlights, and brand elements
  /// throughout the app. It provides a vibrant, transit-focused appearance.
  static const Color primaryColor = Color(0xFFCF3476);
  
  /// Dark theme background color
  /// 
  /// This is the main background color for the app, providing a dark base
  /// that reduces eye strain and saves battery on OLED displays.
  static const Color darkBackground = Color(0xFF121212);
  
  /// Dark theme surface color
  /// 
  /// This color is used for elevated surfaces like app bars and bottom sheets,
  /// providing subtle contrast against the background.
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// Dark theme card color
  /// 
  /// This color is used for cards and input fields, providing a slightly
  /// lighter surface for content that needs to stand out.
  static const Color darkCard = Color(0xFF2C2C2C);
  
  /// Gets the dark theme configuration for the app
  /// 
  /// This method returns a complete ThemeData object configured for dark mode
  /// with Material 3 design principles. It includes color schemes, typography,
  /// and component themes for consistent styling throughout the app.
  /// 
  /// Returns: ThemeData configured for dark mode with app-specific styling
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: darkSurface,
        background: darkBackground,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white70),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Custom spacing constants for consistent layout
/// 
/// This class provides standardized spacing values used throughout the app
/// to ensure consistent spacing between UI elements. Using these constants
/// instead of magic numbers makes the code more maintainable and ensures
/// visual consistency.
class AppSpacing {
  /// Extra small spacing (4.0)
  static const double xs = 4.0;
  
  /// Small spacing (8.0)
  static const double sm = 8.0;
  
  /// Medium spacing (16.0) - default spacing for most layouts
  static const double md = 16.0;
  
  /// Large spacing (24.0)
  static const double lg = 24.0;
  
  /// Extra large spacing (32.0)
  static const double xl = 32.0;
  
  /// Extra extra large spacing (48.0)
  static const double xxl = 48.0;
}

/// Custom typography styles for consistent text styling
/// 
/// This class provides predefined text styles used throughout the app
/// to ensure consistent typography. Each style has specific use cases:
/// - Headings for titles and section headers
/// - Body for regular content
/// - Caption for small supporting text
class AppTypography {
  /// Heading 1 style - largest heading (32px, bold)
  /// 
  /// Used for main page titles and primary headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Heading 2 style - secondary heading (24px, bold)
  /// 
  /// Used for section titles and secondary headings
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Heading 3 style - tertiary heading (20px, semi-bold)
  /// 
  /// Used for subsection titles and tertiary headings
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  /// Body text style - regular content (16px, normal)
  /// 
  /// Used for regular paragraph text and body content
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );
  
  /// Small body text style - secondary content (14px, normal, 70% opacity)
  /// 
  /// Used for secondary text, descriptions, and less prominent content
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );
  
  /// Caption style - smallest text (12px, normal, 54% opacity)
  /// 
  /// Used for captions, labels, and very small supporting text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white54,
  );
}

