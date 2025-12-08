import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing theme preferences
/// 
/// This service handles loading and saving theme preferences to local storage
/// using the shared_preferences package. It provides a clean abstraction over
/// the underlying storage mechanism and includes error handling with fallbacks.
class ThemeService {
  /// Key used to store theme mode preference in shared preferences
  static const String _themeModeKey = 'theme_mode';
  
  /// Loads the saved theme mode preference from local storage
  /// 
  /// This method retrieves the user's theme preference from shared_preferences.
  /// If no preference is saved or an error occurs, it defaults to system theme.
  /// 
  /// Returns: The saved ThemeMode or ThemeMode.system as fallback
  Future<ThemeMode> loadThemeMode() async {
    try {
      // Get SharedPreferences instance
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Retrieve saved theme mode string
      final String? themeModeString = prefs.getString(_themeModeKey);
      
      // If no saved preference, return system default
      if (themeModeString == null) {
        return ThemeMode.system;
      }
      
      // Convert string back to ThemeMode enum
      return _themeModeFromString(themeModeString);
    } catch (e) {
      // On error, fallback to system theme
      debugPrint('Error loading theme mode: $e');
      return ThemeMode.system;
    }
  }
  
  /// Saves the theme mode preference to local storage
  /// 
  /// This method persists the user's theme choice to shared_preferences
  /// so it can be restored when the app is restarted.
  /// 
  /// Parameters:
  ///   - themeMode: The ThemeMode to save
  /// 
  /// Returns: true if save was successful, false otherwise
  Future<bool> saveThemeMode(ThemeMode themeMode) async {
    try {
      // Get SharedPreferences instance
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Convert ThemeMode enum to string and save
      final String themeModeString = _themeModeToString(themeMode);
      return await prefs.setString(_themeModeKey, themeModeString);
    } catch (e) {
      // Log error and return false to indicate failure
      debugPrint('Error saving theme mode: $e');
      return false;
    }
  }
  
  /// Converts ThemeMode enum to string for storage
  /// 
  /// Parameters:
  ///   - themeMode: The ThemeMode to convert
  /// 
  /// Returns: String representation of the theme mode
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  /// Converts string back to ThemeMode enum
  /// 
  /// Parameters:
  ///   - value: The string to convert
  /// 
  /// Returns: ThemeMode enum value, defaults to system if string is unrecognized
  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        // Default to system for any unrecognized value
        return ThemeMode.system;
    }
  }
}

