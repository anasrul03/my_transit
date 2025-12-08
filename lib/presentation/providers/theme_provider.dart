import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/theme_service.dart';

/// Provider for the ThemeService singleton
/// 
/// This provider gives access to the theme service throughout the app
/// for loading and saving theme preferences.
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Notifier for managing theme mode state
/// 
/// This notifier handles the app's theme mode state and provides methods
/// to change the theme. It persists the user's theme preference to local
/// storage and loads it on initialization.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  /// Reference to the theme service for persistence
  final ThemeService _themeService;
  
  /// Creates a ThemeModeNotifier with initial state
  /// 
  /// The initial state defaults to ThemeMode.system, which will be
  /// overridden by the saved preference when loadThemeMode is called.
  /// 
  /// Parameters:
  ///   - themeService: The service used for loading/saving theme preference
  ThemeModeNotifier(this._themeService) : super(ThemeMode.system) {
    // Load saved theme preference when notifier is created
    _loadThemeMode();
  }
  
  /// Loads the saved theme mode from storage
  /// 
  /// This method is called during initialization to restore the user's
  /// previous theme preference. If no preference is saved, it defaults
  /// to system theme mode.
  Future<void> _loadThemeMode() async {
    // Load theme mode from storage
    final ThemeMode savedMode = await _themeService.loadThemeMode();
    
    // Update state with loaded theme mode
    state = savedMode;
  }
  
  /// Sets the theme mode to light
  /// 
  /// This method changes the current theme to light mode and persists
  /// the preference to storage for future app launches.
  Future<void> setLightMode() async {
    // Update state to light mode
    state = ThemeMode.light;
    
    // Persist the preference
    await _themeService.saveThemeMode(ThemeMode.light);
  }
  
  /// Sets the theme mode to dark
  /// 
  /// This method changes the current theme to dark mode and persists
  /// the preference to storage for future app launches.
  Future<void> setDarkMode() async {
    // Update state to dark mode
    state = ThemeMode.dark;
    
    // Persist the preference
    await _themeService.saveThemeMode(ThemeMode.dark);
  }
  
  /// Sets the theme mode to system (follow device settings)
  /// 
  /// This method changes the current theme to follow the system/device
  /// theme preference and persists this choice to storage.
  Future<void> setSystemMode() async {
    // Update state to system mode
    state = ThemeMode.system;
    
    // Persist the preference
    await _themeService.saveThemeMode(ThemeMode.system);
  }
  
  /// Sets the theme mode to a specific value
  /// 
  /// This is a generic method that can set any ThemeMode and is used
  /// by the UI when the user selects a theme from a list.
  /// 
  /// Parameters:
  ///   - mode: The ThemeMode to set
  Future<void> setThemeMode(ThemeMode mode) async {
    // Update state to the specified mode
    state = mode;
    
    // Persist the preference
    await _themeService.saveThemeMode(mode);
  }
}

/// Provider for the current theme mode
/// 
/// This provider manages the app's theme mode state using the ThemeModeNotifier.
/// It can be watched by the UI to rebuild when the theme changes, and provides
/// methods through the notifier to change the theme.
/// 
/// Usage:
/// - To read current theme: `ref.watch(themeModeProvider)`
/// - To change theme: `ref.read(themeModeProvider.notifier).setLightMode()`
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  // Get theme service from provider
  final themeService = ref.watch(themeServiceProvider);
  
  // Create and return notifier with theme service
  return ThemeModeNotifier(themeService);
});

