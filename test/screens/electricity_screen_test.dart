import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/electricity_provider.dart';
import 'package:valtra/screens/electricity_screen.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late ElectricityDao dao;
  late ElectricityProvider provider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<ElectricityProvider>.value(value: provider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  setUp(() async {
    database = createTestDatabase();
    dao = ElectricityDao(database);
    provider = ElectricityProvider(dao);

    // Create a test household
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

  group('ElectricityScreen', () {
    testWidgets('displays empty state when no readings',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              expect(find.text('No readings yet. Add your first meter reading!'),
                  findsOneWidget);
              expect(find.byIcon(Icons.electric_meter_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays list of readings',
        (tester) => tester.runAsync(() async {
              // Add readings
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueKwh: 1000.0,
              ));
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 16, 10, 30),
                valueKwh: 1150.0,
              ));

              // Wait for provider to update
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              // Should show readings
              expect(find.textContaining('1,000.0'), findsOneWidget);
              expect(find.textContaining('1,150.0'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add dialog', (tester) => tester.runAsync(() async {
          await tester
              .pumpWidget(wrapWithProviders(const ElectricityScreen()));
          await tester.pumpAndSettle();

          // Tap FAB
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          // Dialog should appear
          expect(find.text('Add Reading'), findsOneWidget);
          expect(find.text('Meter Value'), findsOneWidget);

          await tester.pumpWidget(Container());
        }));

    testWidgets('shows delta values correctly',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueKwh: 1000.0,
              ));
              await dao.insertReading(ElectricityReadingsCompanion.insert(
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

    testWidgets('tap opens edit dialog', (tester) => tester.runAsync(() async {
          await dao.insertReading(ElectricityReadingsCompanion.insert(
            householdId: householdId,
            timestamp: DateTime(2024, 3, 15, 10, 30),
            valueKwh: 1234.5,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          await tester
              .pumpWidget(wrapWithProviders(const ElectricityScreen()));
          await tester.pumpAndSettle();

          // Tap on the card
          await tester.tap(find.byType(Card));
          await tester.pumpAndSettle();

          // Dialog should appear in edit mode
          expect(find.text('Edit Reading'), findsOneWidget);

          await tester.pumpWidget(Container());
        }));

    testWidgets('shows kWh chip in app bar',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const ElectricityScreen()));
              await tester.pumpAndSettle();

              expect(find.text('kWh'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
