import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/cost_config_dao.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/electricity_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/electricity_screen.dart';
import 'package:valtra/services/cost_calculation_service.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late ElectricityDao electricityDao;
  late ElectricityProvider electricityProvider;
  late AnalyticsProvider analyticsProvider;
  late CostConfigProvider costConfigProvider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late InterpolationSettingsProvider interpolationSettingsProvider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<ElectricityProvider>.value(
            value: electricityProvider),
        ChangeNotifierProvider<AnalyticsProvider>.value(
            value: analyticsProvider),
        ChangeNotifierProvider<CostConfigProvider>.value(
            value: costConfigProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = createTestDatabase();
    electricityDao = ElectricityDao(database);
    electricityProvider = ElectricityProvider(electricityDao);
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
    interpolationSettingsProvider = InterpolationSettingsProvider();
    await interpolationSettingsProvider.init();

    final costConfigDao = CostConfigDao(database);
    final costCalculationService = CostCalculationService();
    costConfigProvider = CostConfigProvider(
      costConfigDao: costConfigDao,
      costCalculationService: costCalculationService,
    );

    analyticsProvider = AnalyticsProvider(
      electricityDao: electricityDao,
      gasDao: GasDao(database),
      waterDao: WaterDao(database),
      heatingDao: HeatingDao(database),
      interpolationService: InterpolationService(),
      gasConversionService: GasConversionService(),
      settingsProvider: interpolationSettingsProvider,
      costConfigProvider: costConfigProvider,
    );

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    electricityProvider.setHouseholdId(householdId);
    analyticsProvider.setHouseholdId(householdId);
    costConfigProvider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    electricityProvider.dispose();
    analyticsProvider.dispose();
    costConfigProvider.dispose();
    await database.close();
  });

  group('ElectricityScreen - Bottom Navigation', () {
    testWidgets('renders bottom nav with Analysis and List labels',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Check bottom nav items
              expect(find.text('Analysis'), findsOneWidget);
              expect(find.text('List'), findsOneWidget);
              expect(find.byType(LiquidGlassBottomNav), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('default tab is Liste (index 1)',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Liste tab should be active - empty state should show
              // (no readings added yet)
              expect(
                  find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);
              expect(
                  find.byIcon(Icons.electric_meter_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping Analysis switches to analysis content',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Tap on Analysis tab
              await tester.tap(find.text('Analysis'));
              // Allow postFrameCallback and async loading to complete
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, analytics loads empty data with
              // noYearlyData message showing the year
              final year = DateTime.now().year.toString();
              expect(find.textContaining(year), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB visible on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Should find FAB on Liste tab (default)
              expect(find.byKey(const Key('right_fab')), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB hidden on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // FAB should not be present
              expect(find.byKey(const Key('right_fab')), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('visibility toggle only in app bar on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // On Liste tab, visibility toggle should be present
              expect(find.byIcon(Icons.visibility_off), findsOneWidget);

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Visibility toggle should be gone
              expect(find.byIcon(Icons.visibility_off), findsNothing);
              expect(find.byIcon(Icons.visibility), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('cost toggle hidden when no cost config',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // No cost config exists, so euro/bolt toggle should not appear
              expect(find.byIcon(Icons.euro), findsNothing);
              expect(find.byIcon(Icons.electric_bolt), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('cost toggle shown when cost config exists on Analyse tab',
        (tester) => tester.runAsync(() async {
              // Add a cost config for electricity
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.electricity,
                      unitPrice: 0.30,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(2024, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );
              // Wait for stream to propagate
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // On Liste tab, cost toggle should NOT appear
              expect(find.byIcon(Icons.electric_bolt), findsNothing);

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Cost toggle should appear with electric_bolt icon (default: show consumption)
              expect(find.byIcon(Icons.electric_bolt), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });

  group('ElectricityScreen - Liste Tab', () {
    testWidgets('displays empty state when no readings',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              expect(
                  find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);
              expect(
                  find.byIcon(Icons.electric_meter_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays list of readings',
        (tester) => tester.runAsync(() async {
              // Add readings
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueKwh: 1000.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 16, 10, 30),
                valueKwh: 1150.0,
              ));

              // Wait for provider to update
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Should show readings (English format: 1,000.0)
              expect(find.textContaining('1,000.0'), findsOneWidget);
              expect(find.textContaining('1,150.0'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add dialog',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Tap FAB
              await tester.tap(find.byKey(const Key('right_fab')));
              await tester.pumpAndSettle();

              // Dialog should appear
              expect(find.text('Add Reading'), findsOneWidget);
              expect(find.text('Meter Value'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows delta values correctly',
        (tester) => tester.runAsync(() async {
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueKwh: 1000.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 16),
                valueKwh: 1150.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Should show delta for newer reading
              expect(find.textContaining('+150.0'), findsOneWidget);

              // Should show "First reading" for oldest
              expect(find.text('First reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tap opens edit dialog',
        (tester) => tester.runAsync(() async {
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueKwh: 1234.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Tap on the GlassCard
              await tester.tap(find.byType(GlassCard).first);
              await tester.pumpAndSettle();

              // Dialog should appear in edit mode
              expect(find.text('Edit Reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('ElectricityScreen - Analyse Tab', () {
    testWidgets('shows no data message when no readings on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              // Allow postFrameCallback and async loading to complete
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, analytics loads empty monthlyBreakdown
              // which shows noYearlyData message with the year
              final year = DateTime.now().year.toString();
              expect(find.textContaining(year), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'shows year navigation and analytics content with readings',
        (tester) => tester.runAsync(() async {
              // Add readings across two months
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 1, 1),
                valueKwh: 1000.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 2, 1),
                valueKwh: 1300.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 3, 1),
                valueKwh: 1550.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Should show current year in navigation
              expect(find.text(DateTime.now().year.toString()), findsOneWidget);

              // Should show chevron navigation icons
              expect(find.byIcon(Icons.chevron_left), findsOneWidget);
              expect(find.byIcon(Icons.chevron_right), findsOneWidget);

              // Should show monthly breakdown heading
              expect(find.text('Monthly Breakdown'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('ElectricityScreen - Cost Toggle on Analyse Tab', () {
    testWidgets(
        'toggling to EUR shows total cost in summary card',
        (tester) => tester.runAsync(() async {
              // Add readings across months for current year
              final year = DateTime.now().year;
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 1, 1),
                valueKwh: 1000.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 2, 1),
                valueKwh: 1300.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 3, 1),
                valueKwh: 1550.0,
              ));

              // Add cost config for electricity
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.electricity,
                      unitPrice: 0.30,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Verify the default shows kWh consumption
              expect(find.textContaining('kWh'), findsAtLeast(1));

              // Tap the cost toggle (electric_bolt icon toggles to euro)
              await tester.tap(find.byIcon(Icons.electric_bolt).last);
              await tester.pumpAndSettle();

              // Now the summary should show EUR symbol
              expect(find.byIcon(Icons.euro), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'toggling back to kWh reverts to consumption display',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 1, 1),
                valueKwh: 1000.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 2, 1),
                valueKwh: 1300.0,
              ));
              await electricityDao
                  .insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 3, 1),
                valueKwh: 1550.0,
              ));

              // Add cost config
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.electricity,
                      unitPrice: 0.30,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Toggle to EUR
              await tester.tap(find.byIcon(Icons.electric_bolt).last);
              await tester.pumpAndSettle();

              // Verify euro icon is showing (cost mode active)
              expect(find.byIcon(Icons.euro), findsOneWidget);

              // Toggle back to kWh
              await tester.tap(find.byIcon(Icons.euro));
              await tester.pumpAndSettle();

              // Should revert: electric_bolt icon visible again,
              // consumption with kWh shown
              expect(find.textContaining('kWh'), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });

  group('ElectricityScreen - Dark Mode', () {
    testWidgets('renders LiquidGlassBottomNav in dark mode',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(
                MultiProvider(
                  providers: [
                    Provider<AppDatabase>.value(value: database),
                    ChangeNotifierProvider<ElectricityProvider>.value(
                        value: electricityProvider),
                    ChangeNotifierProvider<AnalyticsProvider>.value(
                        value: analyticsProvider),
                    ChangeNotifierProvider<CostConfigProvider>.value(
                        value: costConfigProvider),
                    ChangeNotifierProvider<ThemeProvider>.value(
                        value: themeProvider),
                    ChangeNotifierProvider<LocaleProvider>.value(
                        value: localeProvider),
                  ],
                  child: MaterialApp(
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: const Locale('en'),
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: ThemeMode.dark,
                    home: const ElectricityScreen(),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
              expect(find.text('Analysis'), findsOneWidget);
              expect(find.text('List'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
