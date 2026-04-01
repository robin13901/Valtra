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
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/providers/water_provider.dart';
import 'package:valtra/screens/water_screen.dart';
import 'package:valtra/services/cost_calculation_service.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/widgets/charts/month_selector.dart';
import 'package:valtra/widgets/charts/monthly_bar_chart.dart';
import 'package:valtra/widgets/charts/monthly_summary_card.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late WaterDao dao;
  late WaterProvider provider;
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
        ChangeNotifierProvider<WaterProvider>.value(value: provider),
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
    dao = WaterDao(database);
    provider = WaterProvider(dao);
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
      electricityDao: ElectricityDao(database),
      gasDao: GasDao(database),
      waterDao: dao,
      heatingDao: HeatingDao(database),
      householdDao: HouseholdDao(database),
      interpolationService: InterpolationService(),
      gasConversionService: GasConversionService(),
      settingsProvider: interpolationSettingsProvider,
      costConfigProvider: costConfigProvider,
    );

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));

    provider.setHouseholdId(householdId);
    analyticsProvider.setHouseholdId(householdId);
    costConfigProvider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    // Allow async operations from initState (setSelectedMonth + setSelectedYear)
    // to complete before disposing providers to prevent "used after disposed" errors.
    await Future.delayed(const Duration(milliseconds: 300));
    provider.dispose();
    analyticsProvider.dispose();
    costConfigProvider.dispose();
    await database.close();
  });

  group('WaterScreen - Bottom Navigation', () {
    testWidgets('renders bottom nav with Analysis and List labels',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Analysis'), findsOneWidget);
              expect(find.text('List'), findsOneWidget);
              expect(find.byType(LiquidGlassBottomNav), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('default tab is Liste (index 1)',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Liste tab should be active - empty state should show
              expect(
                  find.text(
                      'No water meters yet. Add one to start tracking water consumption!'),
                  findsOneWidget);
              expect(find.byIcon(Icons.water_drop), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping Analysis switches to analysis content',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Tap on Analysis tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, analytics shows the year
              final year = DateTime.now().year.toString();
              expect(find.textContaining(year), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB visible on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              expect(find.byKey(const Key('right_fab')), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB hidden on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              expect(find.byKey(const Key('right_fab')), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('visibility toggle only in app bar on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
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
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // No cost config exists, so euro/water_drop toggle should not appear
              expect(find.byIcon(Icons.euro), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });

  group('WaterScreen - Liste Tab', () {
    testWidgets('displays empty state when no meters',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              expect(
                  find.text(
                      'No water meters yet. Add one to start tracking water consumption!'),
                  findsOneWidget);
              expect(find.byIcon(Icons.water_drop), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays list of meters',
        (tester) => tester.runAsync(() async {
              // Add meters
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water Main',
                type: WaterMeterType.cold,
              ));
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Hot Water Heater',
                type: WaterMeterType.hot,
              ));

              // Wait for provider to update
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Should show meters
              expect(find.text('Cold Water Main'), findsOneWidget);
              expect(find.text('Hot Water Heater'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add meter dialog',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Tap FAB
              await tester.tap(find.byKey(const Key('right_fab')));
              await tester.pumpAndSettle();

              // Dialog should appear
              expect(find.text('Add Water Meter'), findsOneWidget);
              expect(find.text('Meter Name'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows type badges correctly',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Hot Water',
                type: WaterMeterType.hot,
              ));
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Other Water',
                type: WaterMeterType.other,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Should show type badges
              expect(find.text('Cold Water'), findsAtLeastNWidgets(1));
              expect(find.text('Hot Water'), findsAtLeastNWidgets(1));
              expect(find.text('Other'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter card expands to show readings',
        (tester) => tester.runAsync(() async {
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Test Meter',
                type: WaterMeterType.cold,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueCubicMeters: 100.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Initially readings are not visible
              expect(find.text('Water Readings'), findsNothing);

              // Tap to expand
              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              // Now readings should be visible
              expect(find.text('Water Readings'), findsOneWidget);
              // Value appears in card header and in reading list
              expect(find.textContaining('100.500'), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows delta values correctly',
        (tester) => tester.runAsync(() async {
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Test Meter',
                type: WaterMeterType.cold,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(2024, 3, 15),
                valueCubicMeters: 100.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(2024, 3, 16),
                valueCubicMeters: 125.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Expand the card
              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              // Should show delta
              expect(find.textContaining('+25.500'), findsOneWidget);

              // Should show "First reading" for oldest
              expect(find.text('First reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter popup menu shows edit and delete options',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Test Meter',
                type: WaterMeterType.cold,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Find and tap the popup menu button
              final popupMenuFinder = find.byType(PopupMenuButton<String>);
              expect(popupMenuFinder, findsOneWidget);
              await tester.tap(popupMenuFinder);
              await tester.pumpAndSettle();

              // Should show Edit and Delete options
              expect(find.text('Edit'), findsOneWidget);
              expect(find.text('Delete'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('add reading button opens dialog',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Test Meter',
                type: WaterMeterType.cold,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Expand the card
              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              // Tap add reading button
              await tester.tap(find.text('Add Reading'));
              await tester.pumpAndSettle();

              // Dialog should appear
              expect(find.byType(AlertDialog), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows no readings message when meter has no readings',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Empty Meter',
                type: WaterMeterType.cold,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Expand the card
              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              // Should show empty readings message
              expect(find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('WaterScreen - Analyse Tab', () {
    testWidgets('shows no data message when no readings on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, analytics shows no data or month with year
              final year = DateTime.now().year.toString();
              expect(find.textContaining(year), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });

  group('WaterScreen - Analyse Tab (month-based)', () {
    testWidgets('Analyse tab shows MonthSelector when data exists',
        (tester) => tester.runAsync(() async {
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));

              final year = DateTime.now().year;
              // Previous month reading
              final prevMonth = DateTime.now().month == 1 ? 12 : DateTime.now().month - 1;
              final prevYear = DateTime.now().month == 1 ? year - 1 : year;
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(prevYear, prevMonth, 1),
                valueCubicMeters: 100.0,
              ));
              // Current month reading
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, DateTime.now().month, 1),
                valueCubicMeters: 130.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show MonthSelector
              expect(find.byType(MonthSelector), findsOneWidget);

              // Should show MonthlySummaryCard
              expect(find.byType(MonthlySummaryCard), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('Analyse tab shows MonthlyBarChart',
        (tester) => tester.runAsync(() async {
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));

              final year = DateTime.now().year;
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 100.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 130.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show MonthlyBarChart
              expect(find.byType(MonthlyBarChart), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('Analyse tab shows no data when no readings',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // No readings → no monthly data → shows noData text
              expect(find.text('No data available'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'shows MonthSelector and analytics content with readings',
        (tester) => tester.runAsync(() async {
              // Add a water meter first
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));

              // Add readings across months for current year
              final year = DateTime.now().year;
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 100.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 130.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 3, 1),
                valueCubicMeters: 155.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show MonthSelector (new month-based navigation)
              expect(find.byType(MonthSelector), findsOneWidget);

              // Should show chevron navigation icons
              expect(find.byIcon(Icons.chevron_left), findsOneWidget);
              expect(find.byIcon(Icons.chevron_right), findsOneWidget);

              // Should show monthly breakdown heading
              expect(find.text('Monthly Breakdown'), findsOneWidget);

              // Should show MonthlySummaryCard
              expect(find.byType(MonthlySummaryCard), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('WaterScreen - Cost Toggle on Analyse Tab', () {
    testWidgets('cost toggle shown when water cost config exists on Analyse tab',
        (tester) => tester.runAsync(() async {
              // Add a cost config for water
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.water,
                      unitPrice: 2.50,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(2024, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Cost toggle should appear with water_drop icon (default: consumption)
              expect(find.byIcon(Icons.water_drop), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling to EUR shows euro icon',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;

              // Add a water meter with readings
              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 100.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 130.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 3, 1),
                valueCubicMeters: 155.0,
              ));

              // Add cost config for water
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.water,
                      unitPrice: 2.50,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Tap the cost toggle (water_drop icon toggles to euro)
              await tester.tap(find.byIcon(Icons.water_drop).last);
              await tester.pumpAndSettle();

              // Now euro icon should be visible
              expect(find.byIcon(Icons.euro), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling back to m³ reverts to consumption display',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;

              final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
                householdId: householdId,
                name: 'Cold Water',
                type: WaterMeterType.cold,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 100.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 130.0,
              ));
              await dao.insertReading(WaterReadingsCompanion.insert(
                waterMeterId: meterId,
                timestamp: DateTime(year, 3, 1),
                valueCubicMeters: 155.0,
              ));

              // Add cost config
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.water,
                      unitPrice: 2.50,
                      standingCharge: const Value(120.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const WaterScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Toggle to EUR
              await tester.tap(find.byIcon(Icons.water_drop).last);
              await tester.pumpAndSettle();

              // Verify euro icon is showing
              expect(find.byIcon(Icons.euro), findsOneWidget);

              // Toggle back to m³
              await tester.tap(find.byIcon(Icons.euro));
              await tester.pumpAndSettle();

              // Should revert to consumption with m³
              expect(find.textContaining('m³'), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });
}
