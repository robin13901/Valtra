import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/yearly_analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';

import '../helpers/test_locale_provider.dart';

class MockAnalyticsProvider extends ChangeNotifier
    with Mock
    implements AnalyticsProvider {}

PeriodConsumption _period(DateTime start, double consumption,
    {bool interpolated = false}) {
  return PeriodConsumption(
    periodStart: start,
    periodEnd: DateTime(start.year, start.month + 1, 1),
    startValue: 0,
    endValue: consumption,
    consumption: consumption,
    startInterpolated: interpolated,
    endInterpolated: interpolated,
  );
}

YearlyAnalyticsData _buildYearlyData({
  int year = 2026,
  List<PeriodConsumption>? monthlyBreakdown,
  List<PeriodConsumption>? previousYearBreakdown,
  double? totalConsumption,
  double? previousYearTotal,
  String unit = 'kWh',
}) {
  final breakdown = monthlyBreakdown ??
      [
        _period(DateTime(year, 1, 1), 200),
        _period(DateTime(year, 2, 1), 180),
        _period(DateTime(year, 3, 1), 220),
      ];
  return YearlyAnalyticsData(
    meterType: MeterType.electricity,
    year: year,
    monthlyBreakdown: breakdown,
    previousYearBreakdown: previousYearBreakdown,
    totalConsumption: totalConsumption ?? 600.0,
    previousYearTotal: previousYearTotal,
    unit: unit,
  );
}

Widget _wrap(Widget child, MockAnalyticsProvider provider,
    ThemeProvider themeProvider, MockLocaleProvider localeProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AnalyticsProvider>.value(value: provider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  late MockAnalyticsProvider provider;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;

  setUpAll(() {
    registerFallbackValue(MeterType.electricity);
  });

  void setUpDefaultStubs({
    bool isLoading = false,
    YearlyAnalyticsData? yearlyData,
    int selectedYear = 2026,
    MeterType selectedMeterType = MeterType.electricity,
  }) {
    when(() => provider.isLoading).thenReturn(isLoading);
    when(() => provider.yearlyData).thenReturn(yearlyData);
    when(() => provider.selectedYear).thenReturn(selectedYear);
    when(() => provider.selectedMeterType).thenReturn(selectedMeterType);
    when(() => provider.monthlyData).thenReturn(null);
    when(() => provider.overviewSummaries).thenReturn({});
    when(() => provider.householdId).thenReturn(1);
    when(() => provider.selectedMonth).thenReturn(DateTime(2026, 3, 1));

    // Void method stubs
    when(() => provider.setSelectedMeterType(any())).thenReturn(null);
    when(() => provider.setSelectedYear(any())).thenReturn(null);
    when(() => provider.navigateYear(any())).thenReturn(null);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = MockAnalyticsProvider();
    themeProvider = ThemeProvider();
    await themeProvider.init();
    localeProvider = MockLocaleProvider();
  });

  group('YearlyAnalyticsScreen', () {
    testWidgets('renders loading state', (tester) async {
      setUpDefaultStubs(isLoading: true);

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state with "No data for year" message',
        (tester) async {
      final emptyData = _buildYearlyData(
        monthlyBreakdown: [],
        totalConsumption: null,
      );
      setUpDefaultStubs(yearlyData: emptyData);

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No data for 2026'), findsOneWidget);
    });

    testWidgets('renders no data when yearlyData is null', (tester) async {
      setUpDefaultStubs(yearlyData: null);

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('renders year navigation header with year', (tester) async {
      setUpDefaultStubs(yearlyData: _buildYearlyData());

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows summary card with total consumption', (tester) async {
      setUpDefaultStubs(yearlyData: _buildYearlyData());

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // The summary card shows "Total for 2026" and the consumption value
      expect(find.textContaining('Total for 2026'), findsOneWidget);
      expect(find.text('600.0 kWh'), findsOneWidget);
    });

    testWidgets('shows monthly breakdown section', (tester) async {
      setUpDefaultStubs(yearlyData: _buildYearlyData());

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Breakdown'), findsOneWidget);
    });

    testWidgets('shows year-over-year section when previous year data exists',
        (tester) async {
      final prevBreakdown = [
        _period(DateTime(2025, 1, 1), 190),
        _period(DateTime(2025, 2, 1), 170),
        _period(DateTime(2025, 3, 1), 210),
      ];
      final data = _buildYearlyData(
        previousYearBreakdown: prevBreakdown,
        previousYearTotal: 570.0,
      );
      setUpDefaultStubs(yearlyData: data);

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal the year-over-year section
      await tester.scrollUntilVisible(
        find.text('Year-over-Year'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Year-over-Year'), findsOneWidget);
      expect(find.text('Current Year'), findsOneWidget);
      expect(find.text('Previous Year'), findsOneWidget);
    });

    testWidgets('hides year-over-year section when no previous year data',
        (tester) async {
      setUpDefaultStubs(yearlyData: _buildYearlyData());

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Year-over-Year'), findsNothing);
    });

    testWidgets('shows export FAB when data exists', (tester) async {
      setUpDefaultStubs(yearlyData: _buildYearlyData());

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('hides export FAB when no data', (tester) async {
      setUpDefaultStubs(yearlyData: null);

      await tester.pumpWidget(
        _wrap(
          const YearlyAnalyticsScreen(meterType: MeterType.electricity),
          provider,
          themeProvider,
          localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
