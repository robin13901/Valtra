import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/settings_screen.dart';
import 'package:valtra/services/interpolation/models.dart';

class MockCostConfigProvider extends Mock implements CostConfigProvider {}

void main() {
  late ThemeProvider themeProvider;
  late InterpolationSettingsProvider settingsProvider;
  late MockCostConfigProvider costConfigProvider;

  setUpAll(() {
    registerFallbackValue(CostMeterType.electricity);
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  Widget buildSettingsScreen({ThemeMode? initialTheme}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<InterpolationSettingsProvider>.value(
          value: settingsProvider,
        ),
        ChangeNotifierProvider<CostConfigProvider>.value(
          value: costConfigProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: initialTheme ?? themeProvider.themeMode,
        home: const SettingsScreen(),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    await themeProvider.init();
    settingsProvider = InterpolationSettingsProvider();
    await settingsProvider.init();
    costConfigProvider = MockCostConfigProvider();
    when(() => costConfigProvider.getActiveConfig(any(), any()))
        .thenReturn(null);
    when(() => costConfigProvider.configs).thenReturn([]);
    when(() => costConfigProvider.hasCostConfigs).thenReturn(false);
    when(() => costConfigProvider.householdId).thenReturn(null);
  });

  group('SettingsScreen', () {
    group('rendering', () {
      testWidgets('shows AppBar with Settings title', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('shows Appearance section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Appearance'), findsOneWidget);
      });

      testWidgets('shows Theme label', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Theme'), findsOneWidget);
      });

      testWidgets('shows 3 theme segments: Light, Dark, System',
          (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
      });

      testWidgets('shows SegmentedButton for theme selection', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(
          find.byType(SegmentedButton<ThemeMode>),
          findsOneWidget,
        );
      });

      testWidgets('shows Meter Settings section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Meter Settings'), findsOneWidget);
      });

      testWidgets('shows gas conversion factor label', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Gas kWh Conversion Factor'), findsOneWidget);
      });

      testWidgets('shows gas conversion hint', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Default: 10.3 kWh/m³'), findsOneWidget);
      });

      testWidgets('shows interpolation method label', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Interpolation Method'), findsOneWidget);
      });

      testWidgets('shows meter type names for interpolation', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Electricity'), findsOneWidget);
        expect(find.text('Gas'), findsOneWidget);
        expect(find.text('Water'), findsOneWidget);
        expect(find.text('Heating'), findsOneWidget);
      });

      testWidgets('shows interpolation dropdowns with Linear default',
          (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // 4 meter types, each with a "Linear" dropdown value
        expect(find.text('Linear'), findsNWidgets(4));
      });

      testWidgets('shows About section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // Scroll down to reveal About section past the new cost config section
        await tester.scrollUntilVisible(
          find.text('About'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('shows Version label', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Version'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Version'), findsOneWidget);
      });

      testWidgets('shows info icon in About section', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byIcon(Icons.info_outline),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('theme toggle', () {
      testWidgets('tapping Light sets theme to light', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeMode, ThemeMode.light);
      });

      testWidgets('tapping Dark sets theme to dark', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeMode, ThemeMode.dark);
      });

      testWidgets('tapping System sets theme to system', (tester) async {
        await themeProvider.setThemeMode(ThemeMode.light);
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('System'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeMode, ThemeMode.system);
      });
    });

    group('gas conversion factor', () {
      testWidgets('shows current gas factor value', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // Default gas factor is 10.3
        expect(find.text('10.3'), findsOneWidget);
      });

      testWidgets('shows kWh/m³ suffix', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('kWh/m³'), findsOneWidget);
      });

      testWidgets('entering valid factor updates provider', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        await tester.enterText(textField, '11.5');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(settingsProvider.gasKwhFactor, 11.5);
      });

      testWidgets('entering invalid text shows error', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'abc');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid number'), findsOneWidget);
      });
    });

    group('interpolation method', () {
      testWidgets('changing electricity method updates provider',
          (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // Find the first dropdown (electricity) and tap it
        final dropdowns = find.byType(DropdownButton<InterpolationMethod>);
        expect(dropdowns, findsNWidgets(4));

        // Tap the first dropdown (electricity)
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();

        // Select "Step" from the dropdown menu
        await tester.tap(find.text('Step').last);
        await tester.pumpAndSettle();

        expect(
          settingsProvider.getMethodForMeterType('electricity'),
          InterpolationMethod.step,
        );
      });
    });
  });

  group('HomeScreen settings navigation', () {
    testWidgets('settings gear icon exists on home screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final tp = ThemeProvider();
      await tp.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: tp),
            ChangeNotifierProvider<InterpolationSettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProvider<CostConfigProvider>.value(
              value: costConfigProvider,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap the gear icon to navigate
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Meter Settings'), findsOneWidget);
    });
  });
}
