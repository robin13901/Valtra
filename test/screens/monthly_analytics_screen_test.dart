import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/screens/monthly_analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';

class MockAnalyticsProvider extends ChangeNotifier
    with Mock
    implements AnalyticsProvider {}

void main() {
  late MockAnalyticsProvider mockProvider;

  final testMonth = DateTime(2026, 3, 1);
  final testData = MonthlyAnalyticsData(
    meterType: MeterType.electricity,
    month: testMonth,
    dailyValues: [
      ChartDataPoint(
        timestamp: DateTime(2026, 3, 5),
        value: 100.0,
        isInterpolated: false,
      ),
      ChartDataPoint(
        timestamp: DateTime(2026, 3, 15),
        value: 150.0,
        isInterpolated: true,
      ),
    ],
    recentMonths: [
      PeriodConsumption(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 2, 1),
        startValue: 0,
        endValue: 200,
        consumption: 200.0,
        startInterpolated: false,
        endInterpolated: false,
      ),
      PeriodConsumption(
        periodStart: DateTime(2026, 2, 1),
        periodEnd: DateTime(2026, 3, 1),
        startValue: 200,
        endValue: 420,
        consumption: 220.0,
        startInterpolated: false,
        endInterpolated: false,
      ),
      PeriodConsumption(
        periodStart: DateTime(2026, 3, 1),
        periodEnd: DateTime(2026, 4, 1),
        startValue: 420,
        endValue: 670,
        consumption: 250.0,
        startInterpolated: false,
        endInterpolated: false,
      ),
    ],
    totalConsumption: 250.0,
    unit: 'kWh',
  );

  Widget buildSubject() {
    return ChangeNotifierProvider<AnalyticsProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const MonthlyAnalyticsScreen(),
      ),
    );
  }

  void setUpDefaultStubs() {
    when(() => mockProvider.selectedMonth).thenReturn(testMonth);
    when(() => mockProvider.selectedMeterType)
        .thenReturn(MeterType.electricity);
    when(() => mockProvider.monthlyData).thenReturn(testData);
    when(() => mockProvider.overviewSummaries).thenReturn({});
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.householdId).thenReturn(1);
  }

  setUp(() {
    mockProvider = MockAnalyticsProvider();
    setUpDefaultStubs();
  });

  group('MonthlyAnalyticsScreen', () {
    testWidgets('renders month navigation header with correct month text',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // March 2026 should appear in the month navigation
      expect(find.textContaining('March'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('previous/next month buttons are present', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows consumption summary card', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Total Consumption'), findsOneWidget);
      expect(find.text('250.0 kWh'), findsOneWidget);
    });

    testWidgets('shows monthly progress section title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll down to reveal the monthly progress section
      await tester.scrollUntilVisible(
        find.text('Monthly Progress'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Progress'), findsOneWidget);
    });

    testWidgets('shows noData when data is null', (tester) async {
      when(() => mockProvider.monthlyData).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      when(() => mockProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

  });
}
