import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/backup_restore_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/electricity_provider.dart';
import 'package:valtra/providers/gas_provider.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/electricity_screen.dart';
import 'package:valtra/screens/gas_screen.dart';
import 'package:valtra/screens/households_screen.dart';
import 'package:valtra/screens/settings_screen.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

class MockCostConfigProvider extends Mock implements CostConfigProvider {}

class MockBackupRestoreProvider extends Mock implements BackupRestoreProvider {}

/// These tests exercise the app in German locale to cover
/// lib/l10n/app_localizations_de.dart.
void main() {
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;

  setUpAll(() async {
    await initializeDateFormatting('de');
    registerFallbackValue(CostMeterType.electricity);
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider(locale: 'de');
  });

  group('German locale coverage', () {
    testWidgets('SettingsScreen renders in German', (tester) async {
      final settingsProvider = InterpolationSettingsProvider();
      await settingsProvider.init();
      final costConfigProvider = MockCostConfigProvider();
      when(() => costConfigProvider.getActiveConfig(any(), any()))
          .thenReturn(null);
      when(() => costConfigProvider.configs).thenReturn([]);
      when(() => costConfigProvider.hasCostConfigs).thenReturn(false);
      when(() => costConfigProvider.householdId).thenReturn(null);
      final backupRestoreProvider = MockBackupRestoreProvider();
      when(() => backupRestoreProvider.state)
          .thenReturn(BackupRestoreState.idle);
      when(() => backupRestoreProvider.isLoading).thenReturn(false);
      when(() => backupRestoreProvider.errorMessage).thenReturn(null);
      when(() => backupRestoreProvider.successMessage).thenReturn(null);
      when(() => backupRestoreProvider.onDatabaseReplaced).thenReturn(null);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<InterpolationSettingsProvider>.value(
              value: settingsProvider),
          ChangeNotifierProvider<CostConfigProvider>.value(
              value: costConfigProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<BackupRestoreProvider>.value(
              value: backupRestoreProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      // German strings
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Darstellung'), findsOneWidget);
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('Hell'), findsOneWidget);
      expect(find.text('Dunkel'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Sprache'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Englisch'), findsOneWidget);
    });

    testWidgets('HouseholdsScreen renders in German', (tester) async {
      final database = createTestDatabase();
      final dao = HouseholdDao(database);
      final provider = HouseholdProvider(dao);
      await provider.init();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<HouseholdProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          theme: AppTheme.lightTheme,
          home: const HouseholdsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Haushalte'), findsOneWidget);
      // Empty state German text
      expect(
          find.text(
              'Noch keine Haushalte. Erstellen Sie einen, um zu beginnen!'),
          findsOneWidget);

      provider.dispose();
      await database.close();
    });

    testWidgets('ElectricityScreen renders in German',
        (tester) => tester.runAsync(() async {
              final database = createTestDatabase();
              final dao = ElectricityDao(database);
              final provider = ElectricityProvider(dao);

              final householdId = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Haus'));

              provider.setHouseholdId(householdId);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(MultiProvider(
                providers: [
                  Provider<AppDatabase>.value(value: database),
                  ChangeNotifierProvider<ElectricityProvider>.value(
                      value: provider),
                  ChangeNotifierProvider<ThemeProvider>.value(
                      value: themeProvider),
                  ChangeNotifierProvider<LocaleProvider>.value(
                      value: localeProvider),
                ],
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('de'),
                  theme: AppTheme.lightTheme,
                  home: const ElectricityScreen(),
                ),
              ));
              await tester.pumpAndSettle();

              expect(find.text('Strom'), findsOneWidget);
              expect(
                  find.text(
                      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!'),
                  findsOneWidget);

              provider.dispose();
              await database.close();
              await tester.pumpWidget(Container());
            }));

    testWidgets('GasScreen renders in German',
        (tester) => tester.runAsync(() async {
              final database = createTestDatabase();
              final dao = GasDao(database);
              final provider = GasProvider(dao);

              final householdId = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Haus'));

              provider.setHouseholdId(householdId);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(MultiProvider(
                providers: [
                  Provider<AppDatabase>.value(value: database),
                  ChangeNotifierProvider<GasProvider>.value(value: provider),
                  ChangeNotifierProvider<ThemeProvider>.value(
                      value: themeProvider),
                  ChangeNotifierProvider<LocaleProvider>.value(
                      value: localeProvider),
                ],
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('de'),
                  theme: AppTheme.lightTheme,
                  home: const GasScreen(),
                ),
              ));
              await tester.pumpAndSettle();

              expect(find.text('Gas'), findsOneWidget);
              expect(
                  find.text(
                      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!'),
                  findsOneWidget);

              provider.dispose();
              await database.close();
              await tester.pumpWidget(Container());
            }));

    testWidgets('GasScreen with readings in German',
        (tester) => tester.runAsync(() async {
              final database = createTestDatabase();
              final dao = GasDao(database);
              final provider = GasProvider(dao);

              final householdId = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Haus'));

              provider.setHouseholdId(householdId);
              await Future.delayed(const Duration(milliseconds: 50));

              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueCubicMeters: 500.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 4, 15),
                valueCubicMeters: 650.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(MultiProvider(
                providers: [
                  Provider<AppDatabase>.value(value: database),
                  ChangeNotifierProvider<GasProvider>.value(value: provider),
                  ChangeNotifierProvider<ThemeProvider>.value(
                      value: themeProvider),
                  ChangeNotifierProvider<LocaleProvider>.value(
                      value: localeProvider),
                ],
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('de'),
                  theme: AppTheme.lightTheme,
                  home: const GasScreen(),
                ),
              ));
              await tester.pumpAndSettle();

              // German: "Erster Ablesung" or first reading
              expect(find.text('Erste Ablesung'), findsOneWidget);
              // Should show delta for newer reading
              expect(find.textContaining('+150,0'), findsOneWidget);

              provider.dispose();
              await database.close();
              await tester.pumpWidget(Container());
            }));

    testWidgets('ElectricityScreen with readings in German',
        (tester) => tester.runAsync(() async {
              final database = createTestDatabase();
              final dao = ElectricityDao(database);
              final provider = ElectricityProvider(dao);

              final householdId = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Haus'));

              provider.setHouseholdId(householdId);
              await Future.delayed(const Duration(milliseconds: 50));

              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueKwh: 1000.0,
              ));
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 4, 15),
                valueKwh: 1250.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(MultiProvider(
                providers: [
                  Provider<AppDatabase>.value(value: database),
                  ChangeNotifierProvider<ElectricityProvider>.value(
                      value: provider),
                  ChangeNotifierProvider<ThemeProvider>.value(
                      value: themeProvider),
                  ChangeNotifierProvider<LocaleProvider>.value(
                      value: localeProvider),
                ],
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('de'),
                  theme: AppTheme.lightTheme,
                  home: const ElectricityScreen(),
                ),
              ));
              await tester.pumpAndSettle();

              // German "Erste Ablesung" for first reading
              expect(find.text('Erste Ablesung'), findsOneWidget);
              // Should show kWh label
              expect(find.textContaining('kWh'), findsAtLeastNWidgets(1));

              provider.dispose();
              await database.close();
              await tester.pumpWidget(Container());
            }));
  });
}
