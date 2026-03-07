import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/main.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/widgets/household_selector.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import 'helpers/test_database.dart';

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

  group('HomeScreen', () {
    late AppDatabase database;
    late ThemeProvider themeProvider;
    late LocaleProvider localeProvider;
    late HouseholdProvider householdProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      database = createTestDatabase();
      themeProvider = ThemeProvider();
      await themeProvider.init();
      localeProvider = LocaleProvider();
      await localeProvider.init();
      householdProvider = HouseholdProvider(HouseholdDao(database));
      await householdProvider.init();
    });

    tearDown(() async {
      householdProvider.dispose();
      await database.close();
    });

    Widget buildHomeScreen() {
      return MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<HouseholdProvider>.value(
            value: householdProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('renders GlassBottomNav', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomNav), findsOneWidget);
    });

    testWidgets('GlassBottomNav has 5 items', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // BottomNavigationBar inside GlassBottomNav should have 5 items
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 5);
    });

    testWidgets('bottom nav shows correct labels', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // English labels (test defaults to en locale)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Electricity'), findsWidgets);
      expect(find.text('Gas'), findsWidgets);
      expect(find.text('Water'), findsWidgets);
      expect(find.text('Analytics'), findsWidgets);
    });

    testWidgets('does not render Divider', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('does not render FloatingActionButton', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders 6 GlassCard navigation items on home hub',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // 6 category GlassCards: Electricity, Smart Plugs, Gas, Water,
      // Heating, Analytics
      expect(find.byType(GlassCard), findsNWidgets(6));
    });

    testWidgets('GlassCards show all 6 category labels', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // English labels for all 6 categories
      expect(find.text('Electricity'), findsWidgets);
      expect(find.text('Smart Plugs'), findsOneWidget);
      expect(find.text('Gas'), findsWidgets);
      expect(find.text('Water'), findsWidgets);
      expect(find.text('Heating'), findsOneWidget);
      expect(find.text('Analytics'), findsWidgets);
    });

    testWidgets('settings gear icon is in AppBar', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('HouseholdSelector is in AppBar', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdSelector), findsOneWidget);
    });

    testWidgets('does not render Chip widgets (replaced by GlassCard)',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows app title in AppBar', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // AppBar title is "Valtra"
      expect(find.text('Valtra'), findsWidgets);
    });

    testWidgets('shows category icons', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.electric_bolt), findsWidgets);
      expect(find.byIcon(Icons.power), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      expect(find.byIcon(Icons.water_drop), findsWidgets);
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsWidgets);
    });

    testWidgets('home nav icon is present', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsWidgets);
    });

    testWidgets('tapping bottom nav item for electricity does not push '
        'when no household selected', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Tap the Electricity bottom nav item (index 1)
      // Find BottomNavigationBar and tap the electricity label
      final electricityLabels = find.text('Electricity');
      // Tap the one in the bottom nav (last one)
      await tester.tap(electricityLabels.last);
      await tester.pumpAndSettle();

      // Should show a snackbar since no household is selected
      expect(find.text('Select Household'), findsOneWidget);
    });
  });

  group('LocaleProvider', () {
    test('default locale is null (follow device)', () {
      final provider = LocaleProvider();
      expect(provider.locale, isNull);
    });

    test('default localeString is de', () {
      final provider = LocaleProvider();
      expect(provider.localeString, 'de');
    });

    test('setLocale updates locale', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      await provider.init();
      await provider.setLocale(const Locale('en'));
      expect(provider.locale, const Locale('en'));
      expect(provider.localeString, 'en');
    });

    test('init loads persisted locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final provider = LocaleProvider();
      await provider.init();
      expect(provider.locale, const Locale('en'));
    });
  });
}
