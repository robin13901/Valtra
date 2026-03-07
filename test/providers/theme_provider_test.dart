import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ThemeProvider();
    });

    group('default state', () {
      test('default theme mode is system', () {
        expect(provider.themeMode, ThemeMode.system);
      });
    });

    group('init', () {
      test('loads persisted light mode', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
        final p = ThemeProvider();
        await p.init();
        expect(p.themeMode, ThemeMode.light);
      });

      test('loads persisted dark mode', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final p = ThemeProvider();
        await p.init();
        expect(p.themeMode, ThemeMode.dark);
      });

      test('loads persisted system mode', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
        final p = ThemeProvider();
        await p.init();
        expect(p.themeMode, ThemeMode.system);
      });

      test('handles unknown persisted value gracefully', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
        final p = ThemeProvider();
        await p.init();
        expect(p.themeMode, ThemeMode.system);
      });

      test('handles no persisted value', () async {
        SharedPreferences.setMockInitialValues({});
        final p = ThemeProvider();
        await p.init();
        expect(p.themeMode, ThemeMode.system);
      });

      test('notifies listeners after loading', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final p = ThemeProvider();
        var notified = false;
        p.addListener(() => notified = true);
        await p.init();
        expect(notified, true);
      });

      test('does not notify listeners if no persisted value', () async {
        SharedPreferences.setMockInitialValues({});
        final p = ThemeProvider();
        var notified = false;
        p.addListener(() => notified = true);
        await p.init();
        expect(notified, false);
      });
    });

    group('setThemeMode', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
      });

      test('sets light mode', () async {
        await provider.setThemeMode(ThemeMode.light);
        expect(provider.themeMode, ThemeMode.light);
      });

      test('sets dark mode', () async {
        await provider.setThemeMode(ThemeMode.dark);
        expect(provider.themeMode, ThemeMode.dark);
      });

      test('sets system mode', () async {
        await provider.setThemeMode(ThemeMode.light);
        await provider.setThemeMode(ThemeMode.system);
        expect(provider.themeMode, ThemeMode.system);
      });

      test('notifies listeners on change', () async {
        var notified = false;
        provider.addListener(() => notified = true);
        await provider.setThemeMode(ThemeMode.dark);
        expect(notified, true);
      });

      test('does not notify if same mode', () async {
        await provider.setThemeMode(ThemeMode.light);
        var notified = false;
        provider.addListener(() => notified = true);
        await provider.setThemeMode(ThemeMode.light);
        expect(notified, false);
      });

      test('persists selection across provider instances', () async {
        await provider.setThemeMode(ThemeMode.dark);

        final provider2 = ThemeProvider();
        await provider2.init();
        expect(provider2.themeMode, ThemeMode.dark);
      });
    });

    group('toggleTheme', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
      });

      test('system -> light', () async {
        expect(provider.themeMode, ThemeMode.system);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.light);
      });

      test('light -> dark', () async {
        await provider.setThemeMode(ThemeMode.light);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.dark);
      });

      test('dark -> light', () async {
        await provider.setThemeMode(ThemeMode.dark);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.light);
      });

      test('full cycle: system -> light -> dark -> light', () async {
        expect(provider.themeMode, ThemeMode.system);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.light);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.dark);
        await provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.light);
      });
    });

    group('isDark', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
      });

      testWidgets('returns false in light mode', (tester) async {
        await provider.setThemeMode(ThemeMode.light);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(provider.isDark(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns true in dark mode', (tester) async {
        await provider.setThemeMode(ThemeMode.dark);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(provider.isDark(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });
}
