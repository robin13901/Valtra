import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/room_dao.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/room_provider.dart';
import 'package:valtra/providers/smart_plug_analytics_provider.dart';
import 'package:valtra/providers/smart_plug_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/smart_plugs_screen.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';
import '../helpers/test_locale_provider.dart';

class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

void main() {
  late AppDatabase database;
  late SmartPlugDao smartPlugDao;
  late RoomDao roomDao;
  late SmartPlugProvider smartPlugProvider;
  late RoomProvider roomProvider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late MockSmartPlugAnalyticsProvider mockAnalyticsProvider;
  late int householdId;
  late int roomId;

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<SmartPlugProvider>.value(
            value: smartPlugProvider),
        ChangeNotifierProvider<RoomProvider>.value(value: roomProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
            value: mockAnalyticsProvider),
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
    smartPlugDao = SmartPlugDao(database);
    roomDao = RoomDao(database);
    smartPlugProvider = SmartPlugProvider(smartPlugDao);
    roomProvider = RoomProvider(roomDao);
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
    mockAnalyticsProvider = MockSmartPlugAnalyticsProvider();

    // Set up analytics provider stubs
    when(() => mockAnalyticsProvider.isLoading).thenReturn(false);
    when(() => mockAnalyticsProvider.data).thenReturn(null);
    when(() => mockAnalyticsProvider.selectedMonth)
        .thenReturn(DateTime(2026, 3, 1));
    when(() => mockAnalyticsProvider.householdId).thenReturn(1);
    when(() => mockAnalyticsProvider.loadData())
        .thenAnswer((_) async {});

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));

    roomId = await database.into(database.rooms).insert(
        RoomsCompanion.insert(householdId: householdId, name: 'Living Room'));

    smartPlugProvider.setHouseholdId(householdId);
    roomProvider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    smartPlugProvider.dispose();
    roomProvider.dispose();
    await database.close();
  });

  group('SmartPlugsScreen', () {
    testWidgets('displays empty state when no plugs',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.power_outlined), findsOneWidget);
              expect(
                  find.text(
                      'No smart plugs yet. Add one to start tracking device consumption!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays plugs grouped by room',
        (tester) => tester.runAsync(() async {
              await smartPlugDao.insertSmartPlug(SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'TV Plug',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Living Room'), findsAtLeastNWidgets(1));
              expect(find.text('TV Plug'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('shows room section icon',
        (tester) => tester.runAsync(() async {
              await smartPlugDao.insertSmartPlug(SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'Plug A',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.meeting_room), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB shows snackbar when no rooms exist',
        (tester) => tester.runAsync(() async {
              // Clear rooms
              roomProvider.setHouseholdId(null);
              await Future.delayed(const Duration(milliseconds: 50));

              // Create a new household with no rooms
              final emptyHousehold = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Empty', personCount: 1));
              roomProvider.setHouseholdId(emptyHousehold);
              await Future.delayed(const Duration(milliseconds: 50));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byKey(const Key('right_fab')));
              await tester.pumpAndSettle();

              // SnackBar with "no rooms" message
              expect(find.byType(SnackBar), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('popup menu shows edit and delete for plug',
        (tester) => tester.runAsync(() async {
              await smartPlugDao.insertSmartPlug(SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'My Plug',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              expect(find.text('Edit'), findsOneWidget);
              expect(find.text('Delete'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('no pie_chart icon in app bar, rooms button remains',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.pie_chart), findsNothing);
              expect(find.byIcon(Icons.meeting_room), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('plug card shows power icon',
        (tester) => tester.runAsync(() async {
              await smartPlugDao.insertSmartPlug(SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'Power Plug',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.power), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('delete confirmation dialog shows',
        (tester) => tester.runAsync(() async {
              await smartPlugDao.insertSmartPlug(SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'Deletable Plug',
              ));
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Delete'));
              await tester.pumpAndSettle();

              expect(find.text('Delete Smart Plug'), findsOneWidget);

              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              await tester.pumpWidget(Container());
            }));
  });

  group('Bottom Navigation', () {
    testWidgets('renders bottom nav with Analysis and List labels',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Analysis'), findsOneWidget);
              expect(find.text('List'), findsOneWidget);
              expect(find.byType(LiquidGlassBottomNav), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('default tab is Liste',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              // On Liste tab, should see empty state or plug list
              expect(find.byIcon(Icons.power_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping Analysis switches to Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Should show analytics content (empty state since data is null)
              expect(
                  find.text(
                      'No smart plug consumption data for this period.'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB visible on Liste tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byKey(const Key('right_fab')), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB hidden on Analyse tab',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              expect(find.byKey(const Key('right_fab')), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('no pie_chart icon in app bar',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.pie_chart), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('rooms button remains in app bar',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.meeting_room), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tab state preserved when switching (IndexedStack)',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const SmartPlugsScreen()));
              await tester.pumpAndSettle();

              // Default is Liste tab - verify empty state
              expect(find.byIcon(Icons.power_outlined), findsOneWidget);

              // Switch to Analysis
              await tester.tap(find.text('Analysis'));
              await tester.pumpAndSettle();

              // Switch back to Liste - state should be preserved
              await tester.tap(find.text('List'));
              await tester.pumpAndSettle();

              // Empty state should still be visible (IndexedStack preserves state)
              expect(find.byIcon(Icons.power_outlined), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
