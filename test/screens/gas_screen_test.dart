import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/gas_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/gas_screen.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

void main() {
  late AppDatabase database;
  late GasDao dao;
  late GasProvider provider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<GasProvider>.value(value: provider),
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

  group('GasScreen', () {
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
              await tester.tap(find.byType(FloatingActionButton));
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
              await tester.tap(find.byType(GlassCard));
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
              expect(find.text('Delete Reading'), findsOneWidget);
              expect(
                  find.text(
                      'Are you sure you want to delete this reading?'),
                  findsOneWidget);

              // Cancel
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              // Reading should still be there
              expect(find.textContaining('1,000.0'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
