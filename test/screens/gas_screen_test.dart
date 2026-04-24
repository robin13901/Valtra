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
import 'package:valtra/providers/gas_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/gas_screen.dart';
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
  late GasDao dao;
  late GasProvider provider;
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
        ChangeNotifierProvider<GasProvider>.value(value: provider),
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
    dao = GasDao(database);
    provider = GasProvider(dao);
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
      gasDao: dao,
      waterDao: WaterDao(database),
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
    // Allow any outstanding async provider loads to complete before disposal.
    // The new initState fires 2 async operations (setSelectedMonth + setSelectedYear);
    // this delay prevents "used after being disposed" errors from post-test callbacks.
    await Future.delayed(const Duration(milliseconds: 300));
    provider.dispose();
    analyticsProvider.dispose();
    costConfigProvider.dispose();
    await database.close();
  });

  group('GasScreen - Bottom Navigation', () {
    testWidgets('renders bottom nav with Analysis and List labels',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
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
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Liste tab should be active - empty state should show
              expect(
                  find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);
              expect(find.byIcon(Icons.local_fire_department_outlined),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping Analysis switches to analysis content',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Tap on Analysis tab
              await tester.tap(find.text('Analysis'));
              // Allow postFrameCallback and async loading to complete
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, analytics loads null monthlyData -> shows noData
              // OR monthlyData loads empty -> shows MonthSelector with no content
              final hasNoData = tester.any(find.text('No data available'));
              final hasMonthSelector = tester.any(find.byType(MonthSelector));
              expect(hasNoData || hasMonthSelector, isTrue);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB visible on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Should find FAB on Liste tab (default)
              expect(find.byKey(const Key('right_fab')), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB hidden on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
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
                  .pumpWidget(wrapWithProviders(const GasScreen()));
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
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // No cost config exists, so euro/fire toggle should not appear
              expect(find.byIcon(Icons.euro), findsNothing);
              expect(find.byIcon(Icons.local_fire_department), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });

  group('GasScreen - Liste Tab', () {
    testWidgets('displays empty state when no readings',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              expect(
                  find.text(
                      'No readings yet. Add your first meter reading!'),
                  findsOneWidget);
              expect(find.byIcon(Icons.local_fire_department_outlined),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays list of readings',
        (tester) => tester.runAsync(() async {
              // Add readings
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 16, 10, 30),
                valueCubicMeters: 1150.0,
              ));

              // Wait for provider to update
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Should show readings (English format)
              expect(find.textContaining('1,000.0'), findsOneWidget);
              expect(find.textContaining('1,150.0'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add dialog',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
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
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 16),
                valueCubicMeters: 1150.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Should show delta for newer reading
              expect(find.textContaining('+150.0'), findsOneWidget);

              // Should show "First reading" for oldest
              expect(find.text('First reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tap opens edit dialog',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueCubicMeters: 1234.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Tap on the GlassCard
              await tester.tap(find.byType(GlassCard).first);
              await tester.pumpAndSettle();

              // Dialog should appear in edit mode
              expect(find.text('Edit Reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('delete confirmation works',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueCubicMeters: 1000.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Open popup menu
              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              // Tap delete
              await tester.tap(find.text('Delete').last);
              await tester.pumpAndSettle();

              // Confirmation dialog should appear
              expect(find.text('Delete Gas Reading?'), findsOneWidget);
              expect(
                  find.text('This action cannot be undone.'), findsOneWidget);

              // Cancel
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              // Reading should still be there
              expect(find.textContaining('1,000.0'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('GasScreen - Analyse Tab (month-based design)', () {
    testWidgets('shows no data message when no readings on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              // Allow postFrameCallback and async loading to complete
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // With no readings, monthlyData is null -> shows noData
              // OR monthlyData loads empty -> shows MonthSelector with no content
              final hasNoData = tester.any(find.text('No data available'));
              final hasMonthSelector = tester.any(find.byType(MonthSelector));
              expect(hasNoData || hasMonthSelector, isTrue);

              await tester.pumpWidget(Container());
            }));

    testWidgets('Analyse tab shows MonthSelector when data exists',
        (tester) => tester.runAsync(() async {
              // Add readings in previous and current month
              final year = DateTime.now().year;
              final month = DateTime.now().month;
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, month > 1 ? month - 1 : 1, 1),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, month, 15),
                valueCubicMeters: 1300.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show MonthSelector widget
              expect(find.byType(MonthSelector), findsOneWidget);
              // Should show MonthlySummaryCard
              expect(find.byType(MonthlySummaryCard), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('Analyse tab shows MonthlyBarChart when data exists',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;
              final month = DateTime.now().month;
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, month > 1 ? month - 1 : 1, 1),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, month, 15),
                valueCubicMeters: 1300.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show Monthly Breakdown heading and chart
              expect(find.text('Monthly Breakdown'), findsOneWidget);
              expect(find.byType(MonthlyBarChart), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'shows month navigation and analytics content with readings',
        (tester) => tester.runAsync(() async {
              // Add readings across two months
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 1, 1),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 2, 1),
                valueCubicMeters: 1300.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(DateTime.now().year, 3, 1),
                valueCubicMeters: 1550.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 300));
              await tester.pumpAndSettle();

              // Should show monthly breakdown heading
              expect(find.text('Monthly Breakdown'), findsOneWidget);

              // Should show chevron navigation icons (from MonthSelector)
              expect(find.byIcon(Icons.chevron_left), findsOneWidget);
              expect(find.byIcon(Icons.chevron_right), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('GasScreen - Cost Toggle on Analyse Tab', () {
    testWidgets('cost toggle shown when cost config exists on Analyse tab',
        (tester) => tester.runAsync(() async {
              // Add a cost config for gas
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.gas,
                      unitPrice: 0.08,
                      standingCharge: const Value(150.0),
                      validFrom: DateTime(2024, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );
              // Wait for stream to propagate
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // On Liste tab, cost toggle should NOT appear
              // (local_fire_department is used in reading cards, not as toggle)
              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Cost toggle should appear with local_fire_department icon
              // (default: show consumption)
              expect(
                  find.byIcon(Icons.local_fire_department), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling to EUR shows euro icon',
        (tester) => tester.runAsync(() async {
              // Add readings for current year
              final year = DateTime.now().year;
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 1300.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 3, 1),
                valueCubicMeters: 1550.0,
              ));

              // Add cost config for gas
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.gas,
                      unitPrice: 0.08,
                      standingCharge: const Value(150.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Tap the cost toggle (local_fire_department icon toggles to euro)
              await tester
                  .tap(find.byIcon(Icons.local_fire_department).last);
              await tester.pumpAndSettle();

              // Now euro icon should be visible
              expect(find.byIcon(Icons.euro), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling back to m³ reverts to consumption display',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 1, 1),
                valueCubicMeters: 1000.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 2, 1),
                valueCubicMeters: 1300.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(year, 3, 1),
                valueCubicMeters: 1550.0,
              ));

              // Add cost config
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.gas,
                      unitPrice: 0.08,
                      standingCharge: const Value(150.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Toggle to EUR
              await tester
                  .tap(find.byIcon(Icons.local_fire_department).last);
              await tester.pumpAndSettle();

              // Verify euro icon is showing (cost mode active)
              expect(find.byIcon(Icons.euro), findsOneWidget);

              // Toggle back to m³
              await tester.tap(find.byIcon(Icons.euro));
              await tester.pumpAndSettle();

              // Should revert: local_fire_department icon visible again
              expect(find.byIcon(Icons.local_fire_department), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });
}
