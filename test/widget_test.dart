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

    testWidgets('does not render GlassBottomNav', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassBottomNav), findsNothing);
    });

    testWidgets('does not render BottomNavigationBar', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
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

    testWidgets('renders 5 GlassCard navigation items on home hub',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // 5 category GlassCards: Electricity, Smart Plugs, Gas, Heating, Water
      expect(find.byType(GlassCard), findsNWidgets(5));
    });

    testWidgets('GlassCards show correct 5 category labels in order',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // English labels for all 5 categories
      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Smart Plugs'), findsOneWidget);
      expect(find.text('Gas'), findsOneWidget);
      expect(find.text('Heating'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);

      // Analytics tile should NOT be present
      expect(find.text('Analytics'), findsNothing);
    });

    testWidgets('tiles are in correct order: Electricity, Smart Home, Gas, '
        'Heating, Water', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      final glassCards = find.byType(GlassCard);
      expect(glassCards, findsNWidgets(5));

      // Verify order by checking that each label is within its corresponding card
      // We can verify by checking the vertical positions
      final electricityPos = tester.getTopLeft(find.text('Electricity'));
      final smartPlugsPos = tester.getTopLeft(find.text('Smart Plugs'));
      final gasPos = tester.getTopLeft(find.text('Gas'));
      final heatingPos = tester.getTopLeft(find.text('Heating'));
      final waterPos = tester.getTopLeft(find.text('Water'));

      // Row 1: Electricity (left), Smart Plugs (right) -- same vertical
      expect(electricityPos.dy, smartPlugsPos.dy);
      expect(electricityPos.dx, lessThan(smartPlugsPos.dx));

      // Row 2: Gas (left), Heating (right) -- same vertical, below row 1
      expect(gasPos.dy, heatingPos.dy);
      expect(gasPos.dy, greaterThan(electricityPos.dy));
      expect(gasPos.dx, lessThan(heatingPos.dx));

      // Row 3: Water (centered) -- below row 2
      expect(waterPos.dy, greaterThan(gasPos.dy));
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

    testWidgets('does not show Valtra title text in AppBar', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // The Liquid Glass AppBar replaced AppBar — no Material AppBar widget.
      expect(find.byType(AppBar), findsNothing);
      // 'Valtra' still appears as the body heading, not in the bar.
      expect(find.text('Valtra'), findsOneWidget);
    });

    testWidgets('shows category icons', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.electric_bolt), findsWidgets);
      expect(find.byIcon(Icons.power), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
    });

    testWidgets('does not show analytics icon', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.analytics), findsNothing);
    });

    testWidgets('does not show home nav icon (no bottom nav)', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('tapping tile shows snackbar when no household selected',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Tap the Electricity tile
      await tester.tap(find.text('Electricity'));
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
