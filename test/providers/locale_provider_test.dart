import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/providers/locale_provider.dart';

void main() {
  group('LocaleProvider', () {
    late LocaleProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = LocaleProvider();
    });

    group('default state', () {
      test('default locale is null (follow device)', () {
        expect(provider.locale, isNull);
      });

      test('default localeString is de', () {
        expect(provider.localeString, 'de');
      });
    });

    group('init', () {
      test('loads persisted de locale', () async {
        SharedPreferences.setMockInitialValues({'app_locale': 'de'});
        final p = LocaleProvider();
        await p.init();
        expect(p.locale, const Locale('de'));
      });

      test('loads persisted en locale', () async {
        SharedPreferences.setMockInitialValues({'app_locale': 'en'});
        final p = LocaleProvider();
        await p.init();
        expect(p.locale, const Locale('en'));
      });

      test('handles no persisted value - locale remains null', () async {
        SharedPreferences.setMockInitialValues({});
        final p = LocaleProvider();
        await p.init();
        expect(p.locale, isNull);
      });

      test('notifies listeners after loading saved locale', () async {
        SharedPreferences.setMockInitialValues({'app_locale': 'en'});
        final p = LocaleProvider();
        var notified = false;
        p.addListener(() => notified = true);
        await p.init();
        expect(notified, true);
      });

      test('does not notify listeners if no persisted value', () async {
        SharedPreferences.setMockInitialValues({});
        final p = LocaleProvider();
        var notified = false;
        p.addListener(() => notified = true);
        await p.init();
        expect(notified, false);
      });
    });

    group('setLocale', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
      });

      test('sets locale to de', () async {
        await provider.setLocale(const Locale('de'));
        expect(provider.locale, const Locale('de'));
      });

      test('sets locale to en', () async {
        await provider.setLocale(const Locale('en'));
        expect(provider.locale, const Locale('en'));
      });

      test('notifies listeners on change', () async {
        var notified = false;
        provider.addListener(() => notified = true);
        await provider.setLocale(const Locale('en'));
        expect(notified, true);
      });

      test('persists selection across provider instances', () async {
        await provider.setLocale(const Locale('en'));

        final provider2 = LocaleProvider();
        await provider2.init();
        expect(provider2.locale, const Locale('en'));
      });

      test('updates localeString after setLocale', () async {
        expect(provider.localeString, 'de');
        await provider.setLocale(const Locale('en'));
        expect(provider.localeString, 'en');
      });
    });

    group('localeString', () {
      test('returns de when locale is null (default)', () {
        expect(provider.localeString, 'de');
      });

      test('returns de when locale is Locale(de)', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        await provider.setLocale(const Locale('de'));
        expect(provider.localeString, 'de');
      });

      test('returns en when locale is Locale(en)', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        await provider.setLocale(const Locale('en'));
        expect(provider.localeString, 'en');
      });
    });
  });
}
