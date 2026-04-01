import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/main.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HouseholdProvider householdProvider;
  late ThemeProvider themeProvider;
  late LocaleProvider localeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = createTestDatabase();
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = LocaleProvider();
    await localeProvider.init();
    householdProvider = HouseholdProvider(HouseholdDao(database));
    await householdProvider.init();
  });

  tearDown(() async {
    householdProvider.dispose();
    await database.close();
  });

  Widget buildHomeScreen() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<HouseholdProvider>.value(
          value: householdProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen - glass card styling', () {
    testWidgets('uses BackdropFilter for frosted glass effect',
        (tester) => tester.runAsync(() async {
              // Add a household so the card is rendered
              await householdProvider.createHousehold(
                'Test Home',
                personCount: 2,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // BackdropFilter should be present for frosted glass card
              expect(find.byType(BackdropFilter), findsWidgets);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'does not contain a LinearGradient with blue-purple colors in header',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Test Home',
                personCount: 2,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // There should be no LinearGradient using ultraViolet in a household header.
              final containerFinder = find.byType(Container);
              bool foundGradient = false;
              for (final element in containerFinder.evaluate()) {
                final widget = element.widget as Container;
                if (widget.decoration is BoxDecoration) {
                  final decoration = widget.decoration as BoxDecoration;
                  if (decoration.gradient is LinearGradient) {
                    final gradient = decoration.gradient as LinearGradient;
                    final hasUltraViolet = gradient.colors.any(
                      (c) => c.value == AppColors.ultraViolet.value,
                    );
                    if (hasUltraViolet) {
                      foundGradient = true;
                      break;
                    }
                  }
                }
              }
              expect(foundGradient, isFalse,
                  reason:
                      'No blue-purple LinearGradient should be in home screen header');

              await tester.pumpWidget(Container());
            }));
  });

  group('HomeScreen - household card display', () {
    testWidgets('displays household name prominently',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'My Apartment',
                personCount: 3,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // Household name appears in the carousel card (headlineMedium, w700)
              expect(find.text('My Apartment'), findsWidgets);
              // Specifically verify it uses headlineMedium style in the card
              final headlineWidgets = find.byWidgetPredicate((w) {
                if (w is Text && w.data == 'My Apartment') {
                  final style = w.style;
                  return style?.fontWeight == FontWeight.w700;
                }
                return false;
              });
              expect(headlineWidgets, findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays person count with people icon',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Test Home',
                personCount: 2,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // Person count text
              expect(find.text('2 Persons'), findsOneWidget);
              // People icon
              expect(find.byIcon(Icons.people_outline), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('uses singular "Person" for 1 person',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Solo Flat',
                personCount: 1,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.text('1 Person'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('uses plural "Persons" for multiple persons',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Family Home',
                personCount: 4,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.text('4 Persons'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows description when present',
        (tester) => tester.runAsync(() async {
              final dao = HouseholdDao(database);
              await dao.insert(HouseholdsCompanion.insert(
                name: 'Home with Desc',
                description: const Value('Main residence'),
                personCount: 2,
              ));
              // Wait for stream to propagate
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.text('Main residence'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows check_circle icon on selected household card',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Selected Home',
                personCount: 2,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // The selected household should show a check_circle icon
              expect(find.byIcon(Icons.check_circle), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('HomeScreen - carousel', () {
    testWidgets('uses PageView for household carousel',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Home 1',
                personCount: 2,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.byType(PageView), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('PageView contains one page for single household',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Only Home',
                personCount: 1,
              );

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.byType(PageView), findsOneWidget);
              // Household name appears in carousel (may appear more than once due to selector)
              expect(find.text('Only Home'), findsWidgets);

              await tester.pumpWidget(Container());
            }));

    testWidgets('multiple households result in PageView being rendered',
        (tester) => tester.runAsync(() async {
              await householdProvider.createHousehold(
                'Home Alpha',
                personCount: 2,
                selectAfterCreate: true,
              );
              await householdProvider.createHousehold(
                'Home Beta',
                personCount: 3,
                selectAfterCreate: false,
              );
              await Future.delayed(const Duration(milliseconds: 50));

              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.byType(PageView), findsOneWidget);
              // The first household (selected) should be visible
              // (may appear more than once due to selector)
              expect(find.text('Home Alpha'), findsWidgets);

              await tester.pumpWidget(Container());
            }));
  });

  group('HomeScreen - empty state', () {
    testWidgets('shows empty state when no households exist',
        (tester) => tester.runAsync(() async {
              // No households created
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // Empty state text should be visible (no households message)
              expect(find.textContaining('No households'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('does not show PageView when no households',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.byType(PageView), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('empty state uses BackdropFilter for glass effect',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // Even empty state card uses frosted glass
              expect(find.byType(BackdropFilter), findsWidgets);

              await tester.pumpWidget(Container());
            }));
  });

  group('HomeScreen - bento grid still present', () {
    testWidgets('renders 5 GlassCard navigation items',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // 5 category GlassCards: Electricity, Smart Plugs, Gas, Heating, Water
              expect(find.byType(GlassCard), findsNWidgets(5));

              await tester.pumpWidget(Container());
            }));

    testWidgets('all 5 category labels are present',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.text('Electricity'), findsOneWidget);
              expect(find.text('Smart Plugs'), findsOneWidget);
              expect(find.text('Gas'), findsOneWidget);
              expect(find.text('Heating'), findsOneWidget);
              expect(find.text('Water'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('bento grid category icons are present',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.electric_bolt), findsWidgets);
              expect(find.byIcon(Icons.power), findsOneWidget);
              expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
              expect(find.byIcon(Icons.water_drop), findsOneWidget);
              expect(find.byIcon(Icons.thermostat), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });

  group('HomeScreen - StatefulWidget and PageController', () {
    testWidgets('HomeScreen is a StatefulWidget',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(buildHomeScreen());
              await tester.pumpAndSettle();

              // Verify HomeScreen is rendered as a StatefulElement
              final element = find.byType(HomeScreen).evaluate().first;
              expect(element.widget, isA<HomeScreen>());
              expect(element, isA<StatefulElement>());

              await tester.pumpWidget(Container());
            }));
  });
}
