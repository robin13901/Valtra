import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/screens/analytics_screen.dart';
import 'package:valtra/services/analytics/analytics_models.dart';

class MockAnalyticsProvider extends ChangeNotifier
    with Mock
    implements AnalyticsProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(MeterType.electricity);
  });

  late MockAnalyticsProvider mockProvider;

  Widget buildSubject() {
    return ChangeNotifierProvider<AnalyticsProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const AnalyticsScreen(),
      ),
    );
  }

  void setUpDefaultStubs({
    bool isLoading = false,
    Map<MeterType, MeterTypeSummary>? summaries,
  }) {
    when(() => mockProvider.isLoading).thenReturn(isLoading);
    when(() => mockProvider.overviewSummaries)
        .thenReturn(summaries ?? <MeterType, MeterTypeSummary>{});
    when(() => mockProvider.selectedMonth)
        .thenReturn(DateTime(2026, 3, 1));
    when(() => mockProvider.selectedMeterType)
        .thenReturn(MeterType.electricity);
    when(() => mockProvider.monthlyData).thenReturn(null);
    when(() => mockProvider.householdId).thenReturn(1);
  }

  setUp(() {
    mockProvider = MockAnalyticsProvider();
    setUpDefaultStubs();
  });

  group('AnalyticsScreen', () {
    testWidgets('renders 4 overview cards (one per meter type)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(4));
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      setUpDefaultStubs(isLoading: true);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Cards should not be visible while loading
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows correct section title "Consumption Overview"',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Consumption Overview'), findsOneWidget);
    });

    testWidgets('shows correct meter type labels', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Gas'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Heating'), findsOneWidget);
    });

    testWidgets('shows correct icons per meter type', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.electric_bolt), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
    });

    testWidgets('shows noData text when summary has no consumption',
        (tester) async {
      // Empty summaries map = no summary for any type
      setUpDefaultStubs(summaries: {});

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Each card should show "No data available"
      expect(find.text('No data available'), findsNWidgets(4));
    });

    testWidgets(
        'shows noData when summary exists but latestMonthConsumption is null',
        (tester) async {
      setUpDefaultStubs(summaries: {
        MeterType.electricity: const MeterTypeSummary(
          meterType: MeterType.electricity,
          latestMonthConsumption: null,
          hasInterpolation: false,
          unit: 'kWh',
        ),
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Electricity card should show noData even though summary exists
      // The other 3 cards also show noData (no summary in map)
      expect(find.text('No data available'), findsNWidgets(4));
    });

    testWidgets('shows consumption value when summary has data',
        (tester) async {
      setUpDefaultStubs(summaries: {
        MeterType.electricity: const MeterTypeSummary(
          meterType: MeterType.electricity,
          latestMonthConsumption: 123.4,
          hasInterpolation: false,
          unit: 'kWh',
        ),
        MeterType.gas: const MeterTypeSummary(
          meterType: MeterType.gas,
          latestMonthConsumption: 56.7,
          hasInterpolation: true,
          unit: 'kWh',
        ),
        MeterType.water: const MeterTypeSummary(
          meterType: MeterType.water,
          latestMonthConsumption: 8.9,
          hasInterpolation: false,
          unit: 'm\u00B3',
        ),
        MeterType.heating: const MeterTypeSummary(
          meterType: MeterType.heating,
          latestMonthConsumption: 42.0,
          hasInterpolation: false,
          unit: 'units',
        ),
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('123.4 kWh'), findsOneWidget);
      expect(find.text('56.7 kWh'), findsOneWidget);
      expect(find.text('8.9 m\u00B3'), findsOneWidget);
      expect(find.text('42.0 units'), findsOneWidget);
      // No "No data available" text since all have data
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('handles empty summaries map gracefully', (tester) async {
      setUpDefaultStubs(summaries: {});

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Should still render 4 cards even with empty summaries
      expect(find.byType(Card), findsNWidgets(4));
      // All should show noData
      expect(find.text('No data available'), findsNWidgets(4));
    });

    testWidgets('AppBar shows "Analytics" title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('each card has a chevron right icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });

    testWidgets('tapping a card calls setSelectedMeterType', (tester) async {
      when(() => mockProvider.setSelectedMeterType(any())).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap the Gas card (find by the label text within InkWell)
      await tester.tap(find.text('Gas'));
      await tester.pumpAndSettle();

      verify(() => mockProvider.setSelectedMeterType(MeterType.gas)).called(1);
    });
  });
}
