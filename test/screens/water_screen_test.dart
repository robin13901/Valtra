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
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/providers/water_provider.dart';
import 'package:valtra/screens/water_screen.dart';
import 'package:valtra/services/cost_calculation_service.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
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
      interpolationService: InterpolationService(),
      gasConversionService: GasConversionService(),
      settingsProvider: interpolationSettingsProvider,
      costConfigProvider: costConfigProvider,
    );

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

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

  group('WaterScreen', () {
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
              await tester.tap(find.byType(FloatingActionButton));
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
}
