import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/heating_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/heating_screen.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late HeatingDao dao;
  late HeatingProvider provider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<HeatingProvider>.value(value: provider),
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

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    provider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    provider.dispose();
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

    testWidgets('displays list of meters',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                name: 'Bedroom Radiator',
                location: const Value('Bedroom'),
              ));
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                name: 'Kitchen Radiator',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Bedroom Radiator'), findsOneWidget);
              expect(find.text('Kitchen Radiator'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter shows location subtitle when set',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                name: 'Bedroom Radiator',
                location: const Value('Bedroom'),
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Bedroom'), findsOneWidget);
              expect(find.byIcon(Icons.location_on), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter hides location when null',
        (tester) => tester.runAsync(() async {
              await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
                name: 'Hall Radiator',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Hall Radiator'), findsOneWidget);
              expect(find.byIcon(Icons.location_on), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add meter dialog',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const HeatingScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(FloatingActionButton));
              await tester.pumpAndSettle();

              expect(find.text('Add Heating Meter'), findsOneWidget);
              expect(find.text('Meter Name'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('meter card expands to show readings',
        (tester) => tester.runAsync(() async {
              final meterId =
                  await dao.insertMeter(HeatingMetersCompanion.insert(
                householdId: householdId,
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
  });
}
