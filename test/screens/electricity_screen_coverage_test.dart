import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/electricity_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/electricity_screen.dart';


import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late ElectricityDao dao;
  late ElectricityProvider provider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<ElectricityProvider>.value(value: provider),
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
    dao = ElectricityDao(database);
    provider = ElectricityProvider(dao);
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

  group('ElectricityScreen - interpolation and delete', () {
    testWidgets('shows interpolated readings when toggle is on',
        (tester) => tester.runAsync(() async {
              // Add readings with gap for interpolation
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 1, 15),
                valueKwh: 1000.0,
              ));
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueKwh: 1200.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              // Toggle interpolation on
              provider.toggleInterpolatedValues();

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Should show interpolated label
              expect(find.text('Interpolated'), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('visibility icon changes based on interpolation state',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Default: visibility_off
              expect(find.byIcon(Icons.visibility_off), findsOneWidget);

              // Toggle on
              provider.toggleInterpolatedValues();
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.visibility), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('delete confirmation via popup menu works',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueKwh: 1000.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Open popup menu
              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              // Tap delete
              await tester.tap(find.text('Delete').last);
              await tester.pumpAndSettle();

              // Confirmation dialog should appear
              expect(find.text('Delete Electricity Reading?'), findsOneWidget);

              // Confirm deletion
              await tester.tap(find.text('Delete').last);
              await tester.pumpAndSettle();

              // Reading should be gone -> show empty state
              await Future.delayed(const Duration(milliseconds: 100));
              await tester.pumpAndSettle();
              expect(
                  find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('has analytics button in app bar',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.analytics), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
