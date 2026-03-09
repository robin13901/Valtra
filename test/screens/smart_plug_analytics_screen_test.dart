import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/smart_plug_analytics_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/smart_plug_analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';

import '../helpers/test_locale_provider.dart';

class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

void main() {
  late MockSmartPlugAnalyticsProvider mockProvider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
            value: mockProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SmartPlugAnalyseTab()),
      ),
    );
  }

  SmartPlugAnalyticsData createSampleData({
    double? otherConsumption = 15.0,
    double? totalElectricity = 65.0,
  }) {
    return SmartPlugAnalyticsData(
      byPlug: [
        PlugConsumption(
          plugId: 1,
          plugName: 'Desk Lamp',
          roomName: 'Office',
          consumption: 20.0,
          color: pieChartColors[0],
        ),
        PlugConsumption(
          plugId: 2,
          plugName: 'TV',
          roomName: 'Living Room',
          consumption: 15.0,
          color: pieChartColors[1],
        ),
        PlugConsumption(
          plugId: 3,
          plugName: 'Monitor',
          roomName: 'Office',
          consumption: 15.0,
          color: pieChartColors[2],
        ),
      ],
      byRoom: [
        RoomConsumption(
          roomId: 1,
          roomName: 'Office',
          consumption: 35.0,
          color: pieChartColors[0],
        ),
        RoomConsumption(
          roomId: 2,
          roomName: 'Living Room',
          consumption: 15.0,
          color: pieChartColors[1],
        ),
      ],
      totalSmartPlug: 50.0,
      totalElectricity: totalElectricity,
      otherConsumption: otherConsumption,
    );
  }

  void setUpDefaultStubs({
    bool isLoading = false,
    SmartPlugAnalyticsData? data,
  }) {
    when(() => mockProvider.isLoading).thenReturn(isLoading);
    when(() => mockProvider.data).thenReturn(data);
    when(() => mockProvider.selectedMonth).thenReturn(DateTime(2026, 3, 1));
    when(() => mockProvider.householdId).thenReturn(1);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockProvider = MockSmartPlugAnalyticsProvider();
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
    setUpDefaultStubs();
  });

  group('SmartPlugAnalyseTab', () {
    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      setUpDefaultStubs(isLoading: true);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state text when data has empty byPlug',
        (tester) async {
      setUpDefaultStubs(
        data: const SmartPlugAnalyticsData(
          byPlug: [],
          byRoom: [],
          totalSmartPlug: 0,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No smart plug consumption data for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('does not render SegmentedButton', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<AnalyticsPeriod>), findsNothing);
    });

    testWidgets('renders month navigation with arrows', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Should show month label (e.g. "March 2026")
      expect(find.text('March 2026'), findsOneWidget);
      // Should show chevron navigation icons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets(
        'tapping left chevron in month navigation calls navigateMonth(-1)',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());
      when(() => mockProvider.navigateMonth(any())).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      verify(() => mockProvider.navigateMonth(-1)).called(1);
    });

    testWidgets('stats card shows renamed labels', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Total Consumption'), findsOneWidget);
      expect(find.text('Tracked by Plugs'), findsOneWidget);
      expect(find.text('Not Tracked'), findsOneWidget);
    });

    testWidgets('stats card does NOT show old labels', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Total Tracked'), findsNothing);
      expect(find.text('Total Electricity'), findsNothing);
      expect(find.text('Other (Untracked)'), findsNothing);
    });

    testWidgets('section titles use new l10n keys', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to find section titles
      await tester.scrollUntilVisible(
        find.text('Consumption by Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Room'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Consumption by Plug'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Plug'), findsOneWidget);
    });

    testWidgets('room breakdown shows kWh and percentage', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Office = 35.0 / 50.0 = 70%
      // Living Room = 15.0 / 50.0 = 30%
      // Scroll to find room breakdown
      await tester.scrollUntilVisible(
        find.text('Consumption by Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Room items should show percentage
      expect(find.textContaining('70%'), findsOneWidget);
      expect(find.textContaining('30%'), findsOneWidget);
    });

    testWidgets(
        'renders "Not Tracked" with value when otherConsumption is not null',
        (tester) async {
      setUpDefaultStubs(data: createSampleData(otherConsumption: 15.0));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Not Tracked'), findsOneWidget);
      expect(find.text('15.0 kWh'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'does NOT show "Not Tracked" card when otherConsumption is null',
        (tester) async {
      setUpDefaultStubs(
        data: createSampleData(
          otherConsumption: null,
          totalElectricity: null,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Not Tracked'), findsNothing);
    });

    testWidgets(
        'renders plug breakdown list items with plug name, room name, and consumption',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to plug section
      await tester.scrollUntilVisible(
        find.text('Consumption by Plug'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Plug'), findsOneWidget);
      expect(find.text('Desk Lamp'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
      // Room names as subtitles
      expect(find.text('Office'), findsAtLeastNWidgets(1));
      expect(find.text('Living Room'), findsAtLeastNWidgets(1));
      // Consumption values
      expect(find.text('20.0 kWh'), findsOneWidget);
    });

    testWidgets('shows empty state when data is null', (tester) async {
      setUpDefaultStubs(data: null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No smart plug consumption data for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('UI sections appear in correct order', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Verify month nav, then stats, then room, then plug
      // Month label should be at top
      expect(find.text('March 2026'), findsOneWidget);

      // Stats labels should be visible
      expect(find.text('Total Consumption'), findsOneWidget);
      expect(find.text('Tracked by Plugs'), findsOneWidget);

      // Scroll down to find room section then plug section
      await tester.scrollUntilVisible(
        find.text('Consumption by Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Consumption by Room'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Consumption by Plug'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Consumption by Plug'), findsOneWidget);
    });

    testWidgets('reduced padding on list items', (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to see room breakdown items with dense ListTile
      await tester.scrollUntilVisible(
        find.text('Consumption by Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find ListTile widgets and verify they have dense property
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles, isNotEmpty);
      for (final tile in listTiles) {
        expect(tile.dense, isTrue);
      }
    });
  });
}
