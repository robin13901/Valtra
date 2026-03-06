---
name: flutter-theme-system
domain: ui
tech: [flutter, dart, material3]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context
Use this pattern when creating a comprehensive theme system for Flutter apps with light/dark mode support and domain-specific utility colors.

## Pattern

### AppColors Class (Static Constants)

```dart
class AppColors {
  AppColors._(); // Private constructor, all static

  // Brand colors
  static const primary = Color(0xFF5F4A8B);  // Your primary brand color
  static const accent = Color(0xFFFEFACD);   // Your accent color

  // Light theme colors
  static const lightBackground = Color(0xFFF8F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1A1A2E);
  static const lightError = Color(0xFFB00020);
  static const lightOnError = Color(0xFFFFFFFF);

  // Dark theme colors
  static const darkBackground = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF2D2D44);
  static const darkOnSurface = Color(0xFFF8F7FA);
  static const darkError = Color(0xFFCF6679);
  static const darkOnError = Color(0xFF000000);

  // Utility colors (domain-specific)
  static const electricityColor = Color(0xFFFFD93D);
  static const gasColor = Color(0xFFFF8C42);
  static const waterColor = Color(0xFF6BC5F8);
  static const heatingColor = Color(0xFFFF6B6B);
}
```

### AppTheme Class (ThemeData Factory)

```dart
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.lightOnSurface,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  static ThemeData get darkTheme {
    // Similar structure with dark colors
    // Key difference: accent color for focused elements
  }
}
```

### Theme Provider Pattern

```dart
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    _mode = ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
```

### Key Decisions

1. **Separate AppColors and AppTheme** - Colors are reusable, ThemeData is constructed
2. **Private constructors** - These are utility classes, not instantiable
3. **Static getters for themes** - Creates fresh ThemeData each call
4. **Domain utility colors** - Consistent colors across the app for each category
5. **Material 3** - Use `useMaterial3: true` for modern components

### Common Pitfalls

1. **Using deprecated withOpacity** - Use `withValues(alpha: x)` instead
2. **Missing brightness** - Always set `brightness` in ThemeData
3. **Hard-coded colors in widgets** - Use `Theme.of(context).colorScheme` instead
4. **Not persisting theme choice** - Use SharedPreferences to save preference

### Testing Theme

```dart
testWidgets('lightTheme has correct brightness', (tester) async {
  expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
});

testWidgets('darkTheme has correct brightness', (tester) async {
  expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));
});
```
