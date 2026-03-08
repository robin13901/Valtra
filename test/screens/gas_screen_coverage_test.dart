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

  group('GasScreen - interpolation coverage', () {
    testWidgets('shows interpolated readings when toggle is on',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 1, 15),
                valueCubicMeters: 500.0,
              ));
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15),
                valueCubicMeters: 700.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              provider.toggleInterpolatedValues();

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Interpolated'), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('visibility icon toggles for gas screen',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.visibility_off), findsOneWidget);

              provider.toggleInterpolatedValues();
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.visibility), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('delete confirmation via popup menu',
        (tester) => tester.runAsync(() async {
              await dao.insertReading(GasReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueCubicMeters: 500.0,
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Delete').last);
              await tester.pumpAndSettle();

              expect(find.text('Delete Gas Reading?'), findsOneWidget);

              // Confirm deletion
              await tester.tap(find.text('Delete').last);
              await tester.pumpAndSettle();

              await Future.delayed(const Duration(milliseconds: 100));
              await tester.pumpAndSettle();
              expect(
                  find.text(
                      'No readings yet. Add your first meter reading!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('has analytics button',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const GasScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.analytics), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
