import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode provider for managing light/dark/system theme preferences.
///
/// Persists the theme choice to SharedPreferences and provides reactive
/// updates via ChangeNotifier.
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  /// Initialize the provider with persisted preferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedMode = _prefs?.getString(_themeModeKey);
    if (savedMode != null) {
      _themeMode = _themeModeFromString(savedMode);
      notifyListeners();
    }
  }

  /// Set the theme mode and persist the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs?.setString(_themeModeKey, _themeModeToString(mode));
    notifyListeners();
  }

  /// Toggle between light and dark mode.
  /// If currently system, switches to light.
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
    }
  }

  /// Check if dark mode is active.
  /// Takes BuildContext to check system theme when in system mode.
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
