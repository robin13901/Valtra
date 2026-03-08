import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_locale_provider.dart';

void main() {
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
  });

  Widget buildApp({required Widget child, Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('GlassCard', () {
    testWidgets('renders child with default padding', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const GlassCard(child: Text('Hello')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders with custom padding and margin', (tester) async {
      await tester.pumpWidget(buildApp(
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          child: const Text('Custom'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(buildApp(
        child: GlassCard(
          color: Colors.red.withValues(alpha: 0.5),
          child: const Text('Colored'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Colored'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await themeProvider.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: GlassCard(child: Text('Dark')),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
    });
  });

  group('GlassBottomNav', () {
    testWidgets('renders with items', (tester) async {
      await tester.pumpWidget(buildApp(
        child: GlassBottomNav(
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.electric_bolt), label: 'Electricity'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Electricity'), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(buildApp(
        child: GlassBottomNav(
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.electric_bolt), label: 'Electricity'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Electricity'));
      expect(tappedIndex, 1);
    });
  });

  group('buildGlassAppBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => Scaffold(
            appBar: buildGlassAppBar(
              context: context,
              title: 'Test Title',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders with actions', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => Scaffold(
            appBar: buildGlassAppBar(
              context: context,
              title: 'Actions',
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders with leading', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => Scaffold(
            appBar: buildGlassAppBar(
              context: context,
              title: 'Leading',
              leading: const Icon(Icons.menu),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });

  group('buildGlassFAB', () {
    testWidgets('renders FAB with icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => Scaffold(
            floatingActionButton: buildGlassFAB(
              context: context,
              icon: Icons.add,
              onPressed: () {},
              tooltip: 'Add item',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('onPressed callback fires', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => Scaffold(
            floatingActionButton: buildGlassFAB(
              context: context,
              icon: Icons.add,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, true);
    });
  });

  group('buildCircleButton', () {
    testWidgets('renders circle button with icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => buildCircleButton(
            context: context,
            icon: Icons.refresh,
            onPressed: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('onPressed callback fires', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => buildCircleButton(
            context: context,
            icon: Icons.refresh,
            onPressed: () => pressed = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      expect(pressed, true);
    });
  });
}
