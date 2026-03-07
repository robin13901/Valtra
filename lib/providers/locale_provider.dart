import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale provider for managing in-app language toggle.
///
/// Persists the locale choice to SharedPreferences and provides reactive
/// updates via ChangeNotifier. Null locale means follow device default.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale? _locale;
  SharedPreferences? _prefs;

  /// The current locale, or null to follow device locale.
  Locale? get locale => _locale;

  /// The current locale's language code, defaults to 'de' if null.
  String get localeString => _locale?.languageCode ?? 'de';

  /// Initialize the provider with persisted preferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLocale = _prefs?.getString(_localeKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  /// Set the locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs?.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}
