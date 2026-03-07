import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:valtra/providers/locale_provider.dart';

/// A mock LocaleProvider for tests.
///
/// Defaults to 'en' locale so tests can use English-format expected values.
class MockLocaleProvider extends ChangeNotifier implements LocaleProvider {
  String _localeString;

  MockLocaleProvider({String locale = 'en'}) : _localeString = locale;

  @override
  String get localeString => _localeString;

  @override
  Locale? get locale => Locale(_localeString);

  @override
  Future<void> init() async {}

  @override
  Future<void> setLocale(Locale l) async {
    _localeString = l.languageCode;
    notifyListeners();
  }
}
