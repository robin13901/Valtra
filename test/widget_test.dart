import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/providers/theme_provider.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme has correct primary color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, AppColors.ultraViolet);
    });

    test('darkTheme has correct primary color', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.primary, AppColors.ultraViolet);
    });

    test('lightTheme has correct brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme has correct brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('ThemeProvider', () {
    test('default theme mode is system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
    });

    test('can toggle theme', () async {
      final provider = ThemeProvider();
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('can set specific theme mode', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
