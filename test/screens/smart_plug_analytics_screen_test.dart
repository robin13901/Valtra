import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/smart_plug_analytics_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/smart_plug_analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';
import 'package:valtra/widgets/charts/consumption_pie_chart.dart';
import 'package:valtra/widgets/charts/month_selector.dart';
import 'package:valtra/widgets/charts/monthly_bar_chart.dart';
import 'package:valtra/widgets/charts/monthly_summary_card.dart';

import '../helpers/test_locale_provider.dart';

class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

class MockAnalyticsProvider extends ChangeNotifier
    with Mock
    implements AnalyticsProvider {}

void main() {
  late MockSmartPlugAnalyticsProvider mockSpProvider;
  late MockAnalyticsProvider mockAnalyticsProvider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;

  // Sample monthly data for AnalyticsProvider stubs
  MonthlyAnalyticsData createSampleMonthlyData() {
    return MonthlyAnalyticsData(
      meterType: MeterType.electricity,
      month: DateTime(2025, 1, 1),
      dailyValues: const [],
      recentMonths: [
        PeriodConsumption(
          periodStart: DateTime(2024, 12, 1),
          periodEnd: DateTime(2025, 1, 1),
          startValue: 0,
          endValue: 90,
          consumption: 90,
          startInterpolated: false,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2025, 1, 1),
          periodEnd: DateTime(2025, 2, 1),
          startValue: 90,
          endValue: 190,
          consumption: 100,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ],
      totalConsumption: 100,
      unit: 'kWh',
    );
  }

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
            value: mockSpProvider),
        ChangeNotifierProvider<AnalyticsProvider>.value(
            value: mockAnalyticsProvider),
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
          color: smartPlugPieColors[0],
        ),
        PlugConsumption(
          plugId: 2,
          plugName: 'TV',
          roomName: 'Living Room',
          consumption: 15.0,
          color: smartPlugPieColors[1],
        ),
        PlugConsumption(
          plugId: 3,
          plugName: 'Monitor',
          roomName: 'Office',
          consumption: 15.0,
          color: smartPlugPieColors[2],
        ),
      ],
      byRoom: [],
      totalSmartPlug: 50.0,
      totalElectricity: totalElectricity,
      otherConsumption: otherConsumption,
    );
  }

  void setUpDefaultSpStubs({
    bool isLoading = false,
    SmartPlugAnalyticsData? data,
  }) {
    when(() => mockSpProvider.isLoading).thenReturn(isLoading);
    when(() => mockSpProvider.data).thenReturn(data);
    when(() => mockSpProvider.selectedMonth).thenReturn(DateTime(2025, 1, 1));
    when(() => mockSpProvider.householdId).thenReturn(1);
  }

  void setUpDefaultAnalyticsStubs({
    bool isLoading = false,
    MonthlyAnalyticsData? monthlyData,
    YearlyAnalyticsData? yearlyData,
  }) {
    when(() => mockAnalyticsProvider.isLoading).thenReturn(isLoading);
    when(() => mockAnalyticsProvider.monthlyData).thenReturn(monthlyData);
    when(() => mockAnalyticsProvider.yearlyData).thenReturn(yearlyData);
    when(() => mockAnalyticsProvider.selectedMonth)
        .thenReturn(DateTime(2025, 1, 1));
    when(() => mockAnalyticsProvider.selectedYear).thenReturn(2025);
    when(() => mockAnalyticsProvider.householdComparisonData)
        .thenReturn(const []);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockSpProvider = MockSmartPlugAnalyticsProvider();
    mockAnalyticsProvider = MockAnalyticsProvider();
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
    setUpDefaultSpStubs();
    setUpDefaultAnalyticsStubs();
  });

  tearDown(() async {
    // Allow any outstanding async provider loads to complete before disposal.
    await Future.delayed(const Duration(milliseconds: 300));
  });

  group('SmartPlugAnalyseTab', () {
    testWidgets('shows CircularProgressIndicator when analyticsProvider is loading',
        (tester) async {
      setUpDefaultSpStubs(isLoading: false);
      setUpDefaultAnalyticsStubs(isLoading: true);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when spProvider is loading',
        (tester) async {
      setUpDefaultSpStubs(isLoading: true);
      setUpDefaultAnalyticsStubs(isLoading: false);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'shows empty state when both providers have no data',
        (tester) async {
      setUpDefaultSpStubs(data: null);
      setUpDefaultAnalyticsStubs(monthlyData: null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No smart plug consumption data for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when spProvider data has empty byPlug',
        (tester) async {
      setUpDefaultSpStubs(
        data: const SmartPlugAnalyticsData(
          byPlug: [],
          byRoom: [],
          totalSmartPlug: 0,
        ),
      );
      setUpDefaultAnalyticsStubs(monthlyData: null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No smart plug consumption data for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('renders MonthSelector widget', (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(MonthSelector), findsOneWidget);
    });

    testWidgets('renders MonthlySummaryCard when monthlyData is available',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(MonthlySummaryCard), findsOneWidget);
    });

    testWidgets('renders MonthlyBarChart when monthlyData has recentMonths',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyBarChart), findsOneWidget);
    });

    testWidgets(
        'renders per-plug ConsumptionPieChart when byPlug data exists',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ConsumptionPieChart), findsOneWidget);
    });

    testWidgets('renders per-plug breakdown items', (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to find the plug section
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
      // Consumption value
      expect(find.text('20.0 kWh'), findsOneWidget);
    });

    testWidgets('does NOT render room sections', (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Room'), findsNothing);
    });

    testWidgets('MonthSelector shows month label and navigation icons',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('January 2025'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('does NOT render SegmentedButton', (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<AnalyticsPeriod>), findsNothing);
    });

    testWidgets(
        'plug breakdown items use dense ListTile',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: createSampleMonthlyData());
      when(() => mockAnalyticsProvider.setSelectedMonth(any()))
          .thenReturn(null);
      when(() => mockSpProvider.setSelectedMonth(any())).thenReturn(null);
      when(() => mockAnalyticsProvider.setSelectedYear(any()))
          .thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to plug section
      await tester.scrollUntilVisible(
        find.text('Desk Lamp'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles, isNotEmpty);
      for (final tile in listTiles) {
        expect(tile.dense, isTrue);
      }
    });

    testWidgets(
        'shows per-plug section even when monthlyData is null (sp only)',
        (tester) async {
      setUpDefaultSpStubs(data: createSampleData());
      setUpDefaultAnalyticsStubs(monthlyData: null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Consumption by Plug'), findsOneWidget);
    });
  });
}
