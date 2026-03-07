import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/smart_plug_analytics_provider.dart';
import 'package:valtra/screens/smart_plug_analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';

class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

void main() {
  late MockSmartPlugAnalyticsProvider mockProvider;

  Widget buildSubject() {
    return ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SmartPlugAnalyticsScreen(),
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
    AnalyticsPeriod period = AnalyticsPeriod.monthly,
  }) {
    when(() => mockProvider.isLoading).thenReturn(isLoading);
    when(() => mockProvider.data).thenReturn(data);
    when(() => mockProvider.period).thenReturn(period);
    when(() => mockProvider.selectedMonth).thenReturn(DateTime(2026, 3, 1));
    when(() => mockProvider.selectedYear).thenReturn(2026);
    when(() => mockProvider.householdId).thenReturn(1);
  }

  setUpAll(() {
    registerFallbackValue(AnalyticsPeriod.monthly);
  });

  setUp(() {
    mockProvider = MockSmartPlugAnalyticsProvider();
    setUpDefaultStubs();
  });

  group('SmartPlugAnalyticsScreen', () {
    testWidgets('renders AppBar with title "Smart Plug Analytics"',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Smart Plug Analytics'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      setUpDefaultStubs(isLoading: true);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'shows empty state text when data has empty byPlug',
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

    testWidgets(
        'renders SegmentedButton with two segments (Monthly, Yearly)',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
    });

    testWidgets('tapping "Yearly" segment calls setPeriod',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());
      when(() => mockProvider.setPeriod(any())).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();

      verify(() => mockProvider.setPeriod(AnalyticsPeriod.yearly)).called(1);
    });

    testWidgets(
        'renders month navigation header when period is monthly',
        (tester) async {
      setUpDefaultStubs(
        data: createSampleData(),
        period: AnalyticsPeriod.monthly,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Should show month label (e.g. "March 2026")
      expect(find.text('March 2026'), findsOneWidget);
      // Should show chevron navigation icons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets(
        'renders year navigation header when period is yearly',
        (tester) async {
      setUpDefaultStubs(
        data: createSampleData(),
        period: AnalyticsPeriod.yearly,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets(
        'tapping left chevron in month navigation calls navigateMonth(-1)',
        (tester) async {
      setUpDefaultStubs(
        data: createSampleData(),
        period: AnalyticsPeriod.monthly,
      );
      when(() => mockProvider.navigateMonth(any())).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      verify(() => mockProvider.navigateMonth(-1)).called(1);
    });

    testWidgets(
        'renders "Consumption by Plug" section title when byPlug data exists',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Plug'), findsOneWidget);
    });

    testWidgets(
        'renders "Consumption by Room" section title when byRoom data exists',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Room'), findsOneWidget);
    });

    testWidgets(
        'renders "Other (Untracked)" card with value when otherConsumption is not null',
        (tester) async {
      setUpDefaultStubs(data: createSampleData(otherConsumption: 15.0));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to reveal summary card
      await tester.scrollUntilVisible(
        find.text('Other (Untracked)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Other (Untracked)'), findsOneWidget);
      expect(find.text('15.0 kWh'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'does NOT show "Other" card when otherConsumption is null',
        (tester) async {
      setUpDefaultStubs(
        data: createSampleData(
          otherConsumption: null,
          totalElectricity: null,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to the bottom to check entire list
      await tester.scrollUntilVisible(
        find.text('Room Breakdown'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Should show noElectricityData instead of Other card
      expect(find.text('Other (Untracked)'), findsNothing);
    });

    testWidgets(
        'renders plug breakdown list items with plug name, room name, and consumption',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to plug breakdown
      await tester.scrollUntilVisible(
        find.text('Plug Breakdown'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Plug Breakdown'), findsOneWidget);
      expect(find.text('Desk Lamp'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
      // Room names as subtitles
      expect(find.text('Office'), findsAtLeastNWidgets(1));
      expect(find.text('Living Room'), findsAtLeastNWidgets(1));
      // Consumption values
      expect(find.text('20.0 kWh'), findsOneWidget);
    });

    testWidgets(
        'renders room breakdown list items with room name and consumption',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to room breakdown
      await tester.scrollUntilVisible(
        find.text('Room Breakdown'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Room Breakdown'), findsOneWidget);
      // Room consumption values
      expect(find.text('35.0 kWh'), findsOneWidget);
    });

    testWidgets(
        'shows "Total Tracked" and "Total Electricity" summary values',
        (tester) async {
      setUpDefaultStubs(data: createSampleData());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to summary card
      await tester.scrollUntilVisible(
        find.text('Total Tracked'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Tracked'), findsOneWidget);
      expect(find.text('Total Electricity'), findsOneWidget);
      expect(find.text('50.0 kWh'), findsAtLeastNWidgets(1));
      expect(find.text('65.0 kWh'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'shows empty state when data is null',
        (tester) async {
      setUpDefaultStubs(data: null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No smart plug consumption data for this period.'),
        findsOneWidget,
      );
    });
  });
}
