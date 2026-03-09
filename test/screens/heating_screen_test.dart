import 'package:drift/drift.dart' as drift;
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
import 'package:valtra/providers/heating_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/heating_screen.dart';
import 'package:valtra/services/cost_calculation_service.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late HeatingDao dao;
  late HeatingProvider provider;
  late AnalyticsProvider analyticsProvider;
  late CostConfigProvider costConfigProvider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late InterpolationSettingsProvider interpolationSettingsProvider;
  late int householdId;
  late int roomId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<HeatingProvider>.value(value: provider),
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
    dao = HeatingDao(database);
    provider = HeatingProvider(dao);
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
      waterDao: WaterDao(database),
      heatingDao: dao,
      interpolationService: InterpolationService(),
      gasConversionService: GasConversionService(),
      settingsProvider: interpolationSettingsProvider,
      costConfigProvider: costConfigProvider,
    );

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    roomId = await database
        .into(database.rooms)
        .insert(RoomsCompanion.insert(
          householdId: householdId,
          name: 'Living Room',
        ));

    provider.setHouseholdId(householdId);
    analyticsProvider.setHouseholdId(householdId);
    costConfigProvider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    provider.dispose();
    analyticsProvider.dispose();
    costConfigProvider.dispose();
    await database.close();
  });

  group('HeatingScreen', () {
    testWidgets('displays empty state when no meters',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(
                  find.text(
                      'No heating meters yet. Add one to start tracking heating consumption!'),
                  findsOneWidget);
              expect(
                  find.byIcon(Icons.thermostat_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays meters grouped by room',
        (tester) => tester.runAsync(() async {
              // Add meters to different rooms
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Bedroom Radiator',
              ));
              final room2Id = await database
                  .into(database.rooms)
                  .insert(RoomsCompanion.insert(
                    householdId: householdId,
                    name: 'Kitchen',
                  ));
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: room2Id,
                name: 'Kitchen Radiator',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Room headers should be visible
              expect(find.text('Living Room'), findsOneWidget);
              expect(find.text('Kitchen'), findsOneWidget);

              // Room section icons
              expect(find.byIcon(Icons.meeting_room),
                  findsAtLeastNWidgets(2));

              // Meter names
              expect(find.text('Bedroom Radiator'), findsOneWidget);
              expect(find.text('Kitchen Radiator'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows heating type label on meter card',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Own Meter',
                heatingType: const drift.Value(HeatingType.ownMeter),
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Own meter'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('central meter shows ratio badge',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Central Meter',
                heatingType: const drift.Value(HeatingType.centralMeter),
                heatingRatio: const drift.Value(0.25),
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Should show ratio badge
              expect(find.text('25%'), findsOneWidget);

              // Should show central heating type label
              expect(find.text('Central heating'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter card expands to show readings',
        (tester) => tester.runAsync(() async {
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                value: 1234.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Heating Readings'), findsNothing);

              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              expect(find.text('Heating Readings'), findsOneWidget);
              expect(
                  find.textContaining('1,234.5'), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows delta values correctly',
        (tester) => tester.runAsync(() async {
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(2024, 3, 15),
                value: 1000.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(2024, 3, 16),
                value: 1050.5,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              expect(find.textContaining('+50.5'), findsOneWidget);
              expect(find.text('First reading'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter popup menu shows edit and delete options',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              final popupMenuFinder =
                  find.byType(PopupMenuButton<String>);
              expect(popupMenuFinder, findsOneWidget);
              await tester.tap(popupMenuFinder);
              await tester.pumpAndSettle();

              expect(find.text('Edit'), findsOneWidget);
              expect(find.text('Delete'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('add reading button opens dialog',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Add Reading'));
              await tester.pumpAndSettle();

              expect(find.byType(AlertDialog), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows no readings message when meter has no readings',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Empty Meter',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              expect(
                  find.text(
                      'No readings yet. Add your first meter reading!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('has manage rooms button in app bar',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Room management icon in app bar
              expect(find.byIcon(Icons.meeting_room), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('no location/Standort text shown anywhere',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // No location field or label
              expect(find.text('Location'), findsNothing);
              expect(find.text('Standort'), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('two meters in same room grouped under one room header',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Radiator 1',
              ));
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Radiator 2',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Only one room header for "Living Room"
              expect(find.text('Living Room'), findsOneWidget);

              // Both meters visible
              expect(find.text('Radiator 1'), findsOneWidget);
              expect(find.text('Radiator 2'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('HeatingScreen - Bottom Navigation', () {
    testWidgets('renders bottom nav with Analysis and List labels',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Analysis'), findsOneWidget);
              expect(find.text('List'), findsOneWidget);
              expect(find.byType(GlassBottomNav), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('default tab is Liste (index 1)',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Liste tab should be active - empty state should show
              expect(
                  find.text(
                      'No heating meters yet. Add one to start tracking heating consumption!'),
                  findsOneWidget);
              expect(
                  find.byIcon(Icons.thermostat_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping Analysis switches to analysis content',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Tap on Analysis tab
              await tester.tap(find.text('Analysis'));
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
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Should find FAB on Liste tab (default)
              expect(find.byType(FloatingActionButton), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB hidden on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // FAB should not be present
              expect(find.byType(FloatingActionButton), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('visibility toggle only in app bar on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
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

    testWidgets('rooms icon only in app bar on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // On Liste tab (empty state), rooms icon should be present
              expect(find.byIcon(Icons.meeting_room), findsOneWidget);

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Rooms icon should be gone
              expect(find.byIcon(Icons.meeting_room), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('cost toggle hidden when no cost config',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // No cost config exists, so euro/thermostat toggle should not appear
              expect(find.byIcon(Icons.euro), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });

  group('HeatingScreen - Analyse Tab', () {
    testWidgets('shows no data message when no readings on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
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
              // Add a meter and readings across months
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(DateTime.now().year, 1, 1),
                value: 1000.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(DateTime.now().year, 2, 1),
                value: 1300.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(DateTime.now().year, 3, 1),
                value: 1550.0,
              ));
              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Should show current year in navigation
              expect(
                  find.text(DateTime.now().year.toString()), findsOneWidget);

              // Should show chevron navigation icons
              expect(find.byIcon(Icons.chevron_left), findsOneWidget);
              expect(find.byIcon(Icons.chevron_right), findsOneWidget);

              // Should show monthly breakdown heading
              expect(find.text('Monthly Breakdown'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('HeatingScreen - Cost Toggle on Analyse Tab', () {
    testWidgets('cost toggle shown when cost config exists on Analyse tab',
        (tester) => tester.runAsync(() async {
              // Add a cost config for heating
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.heating,
                      unitPrice: 0.12,
                      standingCharge: const drift.Value(200.0),
                      validFrom: DateTime(2024, 1, 1),
                      currencySymbol: const drift.Value('\u20AC'),
                    ),
                  );
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Cost toggle should appear with thermostat icon
              // (default: show consumption)
              expect(find.byIcon(Icons.thermostat), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling to EUR shows euro icon',
        (tester) => tester.runAsync(() async {
              // Add meter and readings for current year
              final year = DateTime.now().year;
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                value: 1000.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                value: 1300.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 3, 1),
                value: 1550.0,
              ));

              // Add cost config for heating
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.heating,
                      unitPrice: 0.12,
                      standingCharge: const drift.Value(200.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const drift.Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Tap the cost toggle (thermostat icon toggles to euro)
              await tester.tap(find.byIcon(Icons.thermostat).last);
              await tester.pumpAndSettle();

              // Now euro icon should be visible
              expect(find.byIcon(Icons.euro), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('toggling back to kWh reverts to consumption display',
        (tester) => tester.runAsync(() async {
              final year = DateTime.now().year;
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Test Meter',
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 1, 1),
                value: 1000.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 2, 1),
                value: 1300.0,
              ));
              await dao.insertReading(HeatingReadingsCompanion.insert(
                heatingMeterId: meterId,
                timestamp: DateTime(year, 3, 1),
                value: 1550.0,
              ));

              // Add cost config
              await database.into(database.costConfigs).insert(
                    CostConfigsCompanion.insert(
                      householdId: householdId,
                      meterType: CostMeterType.heating,
                      unitPrice: 0.12,
                      standingCharge: const drift.Value(200.0),
                      validFrom: DateTime(year, 1, 1),
                      currencySymbol: const drift.Value('\u20AC'),
                    ),
                  );

              await Future.delayed(const Duration(milliseconds: 200));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              // Switch to Analyse tab
              await tester.tap(find.text('Analysis'));
              await Future.delayed(const Duration(milliseconds: 200));
              await tester.pumpAndSettle();

              // Toggle to EUR
              await tester.tap(find.byIcon(Icons.thermostat).last);
              await tester.pumpAndSettle();

              // Verify euro icon is showing (cost mode active)
              expect(find.byIcon(Icons.euro), findsOneWidget);

              // Toggle back to kWh
              await tester.tap(find.byIcon(Icons.euro));
              await tester.pumpAndSettle();

              // Should revert: thermostat icon visible again,
              // consumption with units shown
              expect(find.textContaining('units'), findsAtLeast(1));

              await tester.pumpWidget(Container());
            }));
  });
}
