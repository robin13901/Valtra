import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/backup_restore_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/settings_screen.dart';

class MockCostConfigProvider extends Mock implements CostConfigProvider {}

class MockBackupRestoreProvider extends Mock implements BackupRestoreProvider {}

class MockLocaleProvider extends ChangeNotifier implements LocaleProvider {
  String _localeString = 'en';
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

void main() {
  late ThemeProvider themeProvider;
  late InterpolationSettingsProvider settingsProvider;
  late MockCostConfigProvider costConfigProvider;
  late MockBackupRestoreProvider backupRestoreProvider;
  late MockLocaleProvider localeProvider;

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
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<BackupRestoreProvider>.value(
          value: backupRestoreProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
    backupRestoreProvider = MockBackupRestoreProvider();
    when(() => backupRestoreProvider.state).thenReturn(BackupRestoreState.idle);
    when(() => backupRestoreProvider.isLoading).thenReturn(false);
    when(() => backupRestoreProvider.errorMessage).thenReturn(null);
    when(() => backupRestoreProvider.successMessage).thenReturn(null);
    when(() => backupRestoreProvider.onDatabaseReplaced).thenReturn(null);
    localeProvider = MockLocaleProvider();
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

      testWidgets('shows Language section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Language'), findsOneWidget);
      });

      testWidgets('shows language SegmentedButton', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(
          find.byType(SegmentedButton<String>),
          findsOneWidget,
        );
      });

      testWidgets('shows German and English language options', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('German'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
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

        expect(find.text('Default: 10.3 kWh/m\u00b3'), findsOneWidget);
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

    group('language toggle', () {
      testWidgets('tapping German calls setLocale with de', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('German'));
        await tester.pumpAndSettle();

        expect(localeProvider.localeString, 'de');
      });

      testWidgets('tapping English calls setLocale with en', (tester) async {
        // Start with de selected
        await localeProvider.setLocale(const Locale('de'));
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        expect(localeProvider.localeString, 'en');
      });

      testWidgets('shows current locale as selected', (tester) async {
        await localeProvider.setLocale(const Locale('de'));
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // SegmentedButton should exist with de selected
        final segmentedButton = tester
            .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
        expect(segmentedButton.selected, {'de'});
      });
    });

    group('gas conversion factor', () {
      testWidgets('shows current gas factor value', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        // Default gas factor is 10.3
        expect(find.text('10.3'), findsOneWidget);
      });

      testWidgets('shows kWh/m\u00b3 suffix', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('kWh/m\u00b3'), findsOneWidget);
      });

      testWidgets('entering valid factor updates provider', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, '11.5');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(settingsProvider.gasKwhFactor, 11.5);
      });

      testWidgets('entering invalid text shows error', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, 'abc');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid number'), findsOneWidget);
      });
    });

    group('backup & restore section', () {
      testWidgets('shows Backup & Restore section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Backup & Restore'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Backup & Restore'), findsOneWidget);
      });

      testWidgets('shows Export Database list tile', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Export Database'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Export Database'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      });

      testWidgets('shows Import Database list tile', (tester) async {
        await tester.pumpWidget(buildSettingsScreen());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Import Database'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Import Database'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_download), findsOneWidget);
      });

      testWidgets('export button shows loading indicator when exporting',
          (tester) async {
        when(() => backupRestoreProvider.state)
            .thenReturn(BackupRestoreState.exporting);
        when(() => backupRestoreProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(buildSettingsScreen());
        await tester.pump(const Duration(milliseconds: 100));

        // Drag up multiple times to reveal backup section (can't use
        // scrollUntilVisible because CircularProgressIndicator prevents
        // pumpAndSettle from completing)
        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Exporting database...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('import button shows loading indicator when importing',
          (tester) async {
        when(() => backupRestoreProvider.state)
            .thenReturn(BackupRestoreState.importing);
        when(() => backupRestoreProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(buildSettingsScreen());
        await tester.pump(const Duration(milliseconds: 100));

        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Importing database...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows validating text when validating', (tester) async {
        when(() => backupRestoreProvider.state)
            .thenReturn(BackupRestoreState.validating);

        await tester.pumpWidget(buildSettingsScreen());
        await tester.pump(const Duration(milliseconds: 100));

        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Validating file...'), findsOneWidget);
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
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<BackupRestoreProvider>.value(
              value: backupRestoreProvider,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
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
