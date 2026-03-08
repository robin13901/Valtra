import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/widgets/household_selector.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HouseholdDao dao;
  late HouseholdProvider provider;
  late ThemeProvider themeProvider;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<HouseholdProvider>.value(value: provider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(actions: [child]),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = createTestDatabase();
    dao = HouseholdDao(database);
    provider = HouseholdProvider(dao);
    await provider.init();
    themeProvider = ThemeProvider();
    await themeProvider.init();
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('HouseholdSelector', () {
    testWidgets('shows loading indicator when not initialized',
        (tester) => tester.runAsync(() async {
              // Create a non-initialized provider
              final uninitProvider = HouseholdProvider(dao);

              await tester.pumpWidget(MultiProvider(
                providers: [
                  Provider<AppDatabase>.value(value: database),
                  ChangeNotifierProvider<HouseholdProvider>.value(
                      value: uninitProvider),
                  ChangeNotifierProvider<ThemeProvider>.value(
                      value: themeProvider),
                ],
                child: MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('en'),
                  theme: AppTheme.lightTheme,
                  home: const Scaffold(
                    body: HouseholdSelector(),
                  ),
                ),
              ));
              await tester.pump();

              expect(
                  find.byType(CircularProgressIndicator), findsOneWidget);

              uninitProvider.dispose();
              await tester.pumpWidget(Container());
            }));

    testWidgets('shows add household button when no households',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(
                  wrapWithProviders(const HouseholdSelector()));
              await tester.pumpAndSettle();

              expect(find.text('Add Household'), findsOneWidget);
              expect(find.byIcon(Icons.add_home), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows selected household name when household exists',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('My Home');
              await Future.delayed(const Duration(milliseconds: 50));

              final household = provider.households.first;
              provider.selectHousehold(household.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                  wrapWithProviders(const HouseholdSelector()));
              await tester.pumpAndSettle();

              expect(find.text('My Home'), findsOneWidget);
              expect(find.byIcon(Icons.home), findsOneWidget);
              expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows popup menu with households on tap',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Home 1');
              await provider.createHousehold('Home 2');
              await Future.delayed(const Duration(milliseconds: 50));

              provider.selectHousehold(provider.households.first.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                  wrapWithProviders(const HouseholdSelector()));
              await tester.pumpAndSettle();

              // Tap to open popup
              await tester.tap(find.byIcon(Icons.arrow_drop_down));
              await tester.pumpAndSettle();

              expect(find.text('Home 1'), findsAtLeastNWidgets(1));
              expect(find.text('Home 2'), findsAtLeastNWidgets(1));
              expect(find.text('Households'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows check icon for selected household in popup',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Selected Home');
              await Future.delayed(const Duration(milliseconds: 50));

              provider.selectHousehold(provider.households.first.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                  wrapWithProviders(const HouseholdSelector()));
              await tester.pumpAndSettle();

              await tester.tap(find.byIcon(Icons.arrow_drop_down));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.check), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

  });
}
