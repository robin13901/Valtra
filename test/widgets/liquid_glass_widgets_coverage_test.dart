import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
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

  group('liquidGlassSettings', () {
    testWidgets('returns LiquidGlassSettings from context', (tester) async {
      late LiquidGlassSettings result;

      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) {
            result = liquidGlassSettings(context);
            return const SizedBox.shrink();
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(result, isA<LiquidGlassSettings>());
      expect(result.thickness, 30);
      expect(result.blur, 1.4);
    });

    testWidgets('returns dark glass color in dark mode', (tester) async {
      late LiquidGlassSettings result;

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                result = liquidGlassSettings(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(result.glassColor, const Color(0x33000000));
    });
  });

  group('buildLiquidCircleButton', () {
    testWidgets('renders circle button with child', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => buildLiquidCircleButton(
            child: const Icon(Icons.star),
            size: 64,
            settings: liquidGlassSettings(context),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => buildLiquidCircleButton(
            child: const Icon(Icons.star),
            size: 64,
            settings: liquidGlassSettings(context),
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star));
      expect(tapped, true);
    });

    testWidgets('renders without onTap (no GestureDetector)', (tester) async {
      await tester.pumpWidget(buildApp(
        child: Builder(
          builder: (context) => buildLiquidCircleButton(
            child: const Icon(Icons.lock),
            size: 64,
            settings: liquidGlassSettings(context),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
      // No GestureDetector wrapping (onTap is null)
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('LiquidGlassBottomNav', () {
    Widget buildNav({
      int currentIndex = 0,
      ValueChanged<int>? onTap,
      VoidCallback? onLeftTap,
      Set<int> leftVisibleForIndices = const {},
      VoidCallback? onRightTap,
      Set<int>? rightVisibleForIndices,
      bool keepLeftPlaceholder = false,
      IconData rightIcon = Icons.more_horiz,
    }) {
      return LiquidGlassBottomNav(
        icons: const [Icons.home, Icons.bolt, Icons.water_drop],
        labels: const ['Home', 'Power', 'Water'],
        keys: const [
          ValueKey('tab0'),
          ValueKey('tab1'),
          ValueKey('tab2'),
        ],
        currentIndex: currentIndex,
        onTap: onTap ?? (_) {},
        onLeftTap: onLeftTap,
        leftVisibleForIndices: leftVisibleForIndices,
        onRightTap: onRightTap,
        rightVisibleForIndices: rightVisibleForIndices,
        keepLeftPlaceholder: keepLeftPlaceholder,
        rightIcon: rightIcon,
      );
    }

    testWidgets('renders icons and labels', (tester) async {
      await tester.pumpWidget(buildApp(child: buildNav()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Power'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('onTap fires for tab items', (tester) async {
      int tapped = -1;

      await tester.pumpWidget(buildApp(
        child: buildNav(onTap: (i) => tapped = i),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab1')));
      expect(tapped, 1);
    });

    testWidgets('right button visible when currentIndex in rightVisibleForIndices',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 0,
          rightVisibleForIndices: {0, 2},
          rightIcon: Icons.add,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('right_fab')), findsOneWidget);
    });

    testWidgets(
        'right button hidden when currentIndex not in rightVisibleForIndices',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 1,
          rightVisibleForIndices: {0, 2},
          rightIcon: Icons.add,
        ),
      ));
      await tester.pumpAndSettle();

      // right_fab key is absent; a SizedBox placeholder is shown instead
      expect(find.byKey(const Key('right_fab')), findsNothing);
    });

    testWidgets('right button always visible when rightVisibleForIndices is null',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 2,
          rightVisibleForIndices: null,
          rightIcon: Icons.menu,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('right_fab')), findsOneWidget);
    });

    testWidgets(
        'left button shown when leftVisibleForIndices matches and onLeftTap provided',
        (tester) async {
      bool leftTapped = false;

      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 1,
          onLeftTap: () => leftTapped = true,
          leftVisibleForIndices: {1},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('left_fab')), findsOneWidget);
      await tester.tap(find.byKey(const Key('left_fab')));
      expect(leftTapped, true);
    });

    testWidgets('left button hidden when index not in leftVisibleForIndices',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 0,
          onLeftTap: () {},
          leftVisibleForIndices: {1},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('left_fab')), findsNothing);
    });

    testWidgets('left placeholder shown when keepLeftPlaceholder is true',
        (tester) async {
      await tester.pumpWidget(buildApp(
        child: buildNav(
          currentIndex: 0,
          keepLeftPlaceholder: true,
          leftVisibleForIndices: {1}, // left button hidden for index 0
        ),
      ));
      await tester.pumpAndSettle();

      // The nav still renders (placeholder occupies space but no key)
      expect(find.byKey(const Key('left_fab')), findsNothing);
      // The pill and right button are present
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: buildNav()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Power'), findsOneWidget);
    });
  });
}
