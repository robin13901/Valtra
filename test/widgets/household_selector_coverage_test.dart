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

  Widget wrapWithTheme(Widget child, {required ThemeData theme}) {
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
        theme: theme,
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

  group('HouseholdSelector trigger button theme colors', () {
    testWidgets(
        'text color uses onSurface in light theme',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Light Home');
              await Future.delayed(const Duration(milliseconds: 50));

              final household = provider.households.first;
              provider.selectHousehold(household.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                wrapWithTheme(
                  const HouseholdSelector(),
                  theme: AppTheme.lightTheme,
                ),
              );
              await tester.pumpAndSettle();

              // Find the Text widget in the trigger button row
              final textFinder = find.text('Light Home');
              expect(textFinder, findsOneWidget);

              final textWidget = tester.widget<Text>(textFinder);
              expect(textWidget.style, isNotNull);
              expect(textWidget.style!.color, isNotNull);
              expect(
                textWidget.style!.color,
                equals(AppTheme.lightTheme.colorScheme.onSurface),
              );

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'text color uses onSurface in dark theme',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Dark Home');
              await Future.delayed(const Duration(milliseconds: 50));

              final household = provider.households.first;
              provider.selectHousehold(household.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                wrapWithTheme(
                  const HouseholdSelector(),
                  theme: AppTheme.darkTheme,
                ),
              );
              await tester.pumpAndSettle();

              final textFinder = find.text('Dark Home');
              expect(textFinder, findsOneWidget);

              final textWidget = tester.widget<Text>(textFinder);
              expect(textWidget.style, isNotNull);
              expect(textWidget.style!.color, isNotNull);
              expect(
                textWidget.style!.color,
                equals(AppTheme.darkTheme.colorScheme.onSurface),
              );

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'home icon color uses onSurface in light theme',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Icon Home');
              await Future.delayed(const Duration(milliseconds: 50));

              final household = provider.households.first;
              provider.selectHousehold(household.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                wrapWithTheme(
                  const HouseholdSelector(),
                  theme: AppTheme.lightTheme,
                ),
              );
              await tester.pumpAndSettle();

              // Find Icon widgets in the trigger button (not in popup)
              // The trigger row has: home icon, text, arrow_drop_down icon
              final homeIconFinder = find.byIcon(Icons.home);
              expect(homeIconFinder, findsOneWidget);

              final homeIcon = tester.widget<Icon>(homeIconFinder);
              expect(homeIcon.color, isNotNull);
              expect(
                homeIcon.color,
                equals(AppTheme.lightTheme.colorScheme.onSurface),
              );

              final arrowIconFinder = find.byIcon(Icons.arrow_drop_down);
              expect(arrowIconFinder, findsOneWidget);

              final arrowIcon = tester.widget<Icon>(arrowIconFinder);
              expect(arrowIcon.color, isNotNull);
              expect(
                arrowIcon.color,
                equals(AppTheme.lightTheme.colorScheme.onSurface),
              );

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'home icon color uses onSurface in dark theme',
        (tester) => tester.runAsync(() async {
              await provider.createHousehold('Dark Icon Home');
              await Future.delayed(const Duration(milliseconds: 50));

              final household = provider.households.first;
              provider.selectHousehold(household.id);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(
                wrapWithTheme(
                  const HouseholdSelector(),
                  theme: AppTheme.darkTheme,
                ),
              );
              await tester.pumpAndSettle();

              final homeIconFinder = find.byIcon(Icons.home);
              expect(homeIconFinder, findsOneWidget);

              final homeIcon = tester.widget<Icon>(homeIconFinder);
              expect(homeIcon.color, isNotNull);
              expect(
                homeIcon.color,
                equals(AppTheme.darkTheme.colorScheme.onSurface),
              );

              final arrowIconFinder = find.byIcon(Icons.arrow_drop_down);
              expect(arrowIconFinder, findsOneWidget);

              final arrowIcon = tester.widget<Icon>(arrowIconFinder);
              expect(arrowIcon.color, isNotNull);
              expect(
                arrowIcon.color,
                equals(AppTheme.darkTheme.colorScheme.onSurface),
              );

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'light and dark theme produce different onSurface colors',
        (tester) => tester.runAsync(() async {
              // Verify that the two themes actually have different onSurface
              // values so the fix is meaningful
              final lightOnSurface =
                  AppTheme.lightTheme.colorScheme.onSurface;
              final darkOnSurface =
                  AppTheme.darkTheme.colorScheme.onSurface;
              expect(lightOnSurface, isNot(equals(darkOnSurface)));

              await tester.pumpWidget(Container());
            }));
  });
}
