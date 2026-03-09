import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/interpolation/models.dart';
import 'package:valtra/widgets/charts/year_comparison_chart.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SizedBox(height: 300, width: 400, child: child)),
  );
}

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

/// Extract the [LineChartData] from a rendered [LineChart] widget.
LineChartData _extractChartData(WidgetTester tester) {
  final lineChart = tester.widget<LineChart>(find.byType(LineChart));
  return lineChart.data;
}

void main() {
  group('YearComparisonChart', () {
    testWidgets('renders with current year data only', (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 100),
        _period(DateTime(2026, 2, 1), 120),
        _period(DateTime(2026, 3, 1), 90),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders with both current and previous year data',
        (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 100),
        _period(DateTime(2026, 2, 1), 120),
        _period(DateTime(2026, 3, 1), 90),
      ];
      final previousYear = [
        _period(DateTime(2025, 1, 1), 80),
        _period(DateTime(2025, 2, 1), 110),
        _period(DateTime(2025, 3, 1), 95),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          previousYear: previousYear,
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('shows "No data" when currentYear is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const YearComparisonChart(
          currentYear: [],
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('handles null previousYear gracefully', (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 150),
        _period(DateTime(2026, 2, 1), 200),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          previousYear: null,
          primaryColor: Colors.green,
          unit: 'm\u00B3',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('empty previousYear list treated same as null',
        (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 150),
        _period(DateTime(2026, 2, 1), 200),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          previousYear: const [],
          primaryColor: Colors.orange,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      // Should render chart without errors; empty previous year produces
      // no second line series (guarded by previousSpots.isNotEmpty)
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with interpolated data points', (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 100, interpolated: true),
        _period(DateTime(2026, 2, 1), 120),
        _period(DateTime(2026, 3, 1), 90, interpolated: true),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with full 12-month data', (tester) async {
      final currentYear = List.generate(
        12,
        (i) => _period(DateTime(2026, i + 1, 1), (i + 1) * 50.0),
      );
      final previousYear = List.generate(
        12,
        (i) => _period(DateTime(2025, i + 1, 1), (i + 1) * 45.0),
      );

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          previousYear: previousYear,
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with zero consumption values', (tester) async {
      final currentYear = [
        _period(DateTime(2026, 1, 1), 0),
        _period(DateTime(2026, 2, 1), 0),
        _period(DateTime(2026, 3, 1), 0),
      ];

      await tester.pumpWidget(
        _wrap(YearComparisonChart(
          currentYear: currentYear,
          primaryColor: Colors.blue,
          unit: 'kWh',
        )),
      );
      await tester.pumpAndSettle();

      // maxY defaults to 1.0 when all values are 0
      expect(find.byType(LineChart), findsOneWidget);
    });

    // ---------------------------------------------------------------
    // Calendar month alignment tests
    // ---------------------------------------------------------------

    group('calendar month alignment', () {
      testWidgets(
          'current year Jan-Mar uses calendar month positions 0, 1, 2',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 120),
          _period(DateTime(2026, 3, 1), 90),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final currentSpots = data.lineBarsData[0].spots;

        expect(currentSpots.length, 3);
        expect(currentSpots[0].x, 0); // Jan
        expect(currentSpots[1].x, 1); // Feb
        expect(currentSpots[2].x, 2); // Mar
        expect(currentSpots[0].y, 100);
        expect(currentSpots[1].y, 120);
        expect(currentSpots[2].y, 90);
      });

      testWidgets(
          'current year Jan-Mar + previous year Jan-Dec both use calendar month positions',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 120),
          _period(DateTime(2026, 3, 1), 90),
        ];
        final previousYear = List.generate(
          12,
          (i) => _period(DateTime(2025, i + 1, 1), (i + 1) * 10.0),
        );

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            previousYear: previousYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);

        // Current year spots at months 0, 1, 2
        final currentSpots = data.lineBarsData[0].spots;
        expect(currentSpots[0].x, 0);
        expect(currentSpots[1].x, 1);
        expect(currentSpots[2].x, 2);

        // Previous year spots at months 0..11
        final previousSpots = data.lineBarsData[1].spots;
        expect(previousSpots.length, 12);
        expect(previousSpots.first.x, 0); // Jan
        expect(previousSpots.last.x, 11); // Dec
        for (int i = 0; i < 12; i++) {
          expect(previousSpots[i].x, i.toDouble());
        }
      });

      testWidgets(
          'previous year with only Mar-Dec data starts at x=2 (March position)',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 120),
          _period(DateTime(2026, 3, 1), 90),
        ];
        // Previous year has data only from March to December
        final previousYear = List.generate(
          10,
          (i) => _period(DateTime(2025, i + 3, 1), (i + 3) * 10.0),
        );

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            previousYear: previousYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final previousSpots = data.lineBarsData[1].spots;

        expect(previousSpots.length, 10);
        expect(previousSpots.first.x, 2); // March = index 2
        expect(previousSpots.last.x, 11); // December = index 11
      });

      testWidgets('maxX includes highest month across both datasets',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 120),
        ];
        // Previous year goes up to December
        final previousYear = List.generate(
          12,
          (i) => _period(DateTime(2025, i + 1, 1), (i + 1) * 10.0),
        );

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            previousYear: previousYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        // maxX should be 11 (December), not 1 (Feb from current year)
        expect(data.maxX, 11);
      });

      testWidgets('maxX based on current year only when no previous year',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 5, 1), 200),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        // maxX should be 4 (May = month 5 -> index 4)
        expect(data.maxX, 4);
      });

      testWidgets('single month data uses correct calendar position',
          (tester) async {
        // Only June data
        final currentYear = [
          _period(DateTime(2026, 6, 1), 300),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots;
        expect(spots.length, 1);
        expect(spots[0].x, 5); // June = index 5
        expect(data.maxX, 5);
      });
    });

    // ---------------------------------------------------------------
    // Cost mode tests
    // ---------------------------------------------------------------

    group('cost mode', () {
      testWidgets('showCosts=false uses consumption values (default)',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 200),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            currentYearCosts: [25.0, 50.0],
            showCosts: false,
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots;
        // Should use consumption values, not costs
        expect(spots[0].y, 100);
        expect(spots[1].y, 200);
      });

      testWidgets('showCosts=true uses cost values for current year',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 200),
          _period(DateTime(2026, 3, 1), 150),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            currentYearCosts: [25.0, 50.0, 37.5],
            showCosts: true,
            costUnit: 'EUR',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots;
        expect(spots.length, 3);
        expect(spots[0].y, 25.0);
        expect(spots[1].y, 50.0);
        expect(spots[2].y, 37.5);
        // Calendar month positions should still be correct
        expect(spots[0].x, 0); // Jan
        expect(spots[1].x, 1); // Feb
        expect(spots[2].x, 2); // Mar
      });

      testWidgets('showCosts=true uses cost values for previous year',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 200),
        ];
        final previousYear = [
          _period(DateTime(2025, 1, 1), 80),
          _period(DateTime(2025, 2, 1), 160),
          _period(DateTime(2025, 3, 1), 120),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            previousYear: previousYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            currentYearCosts: [25.0, 50.0],
            previousYearCosts: [20.0, 40.0, 30.0],
            showCosts: true,
            costUnit: 'EUR',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        // Previous year line
        final prevSpots = data.lineBarsData[1].spots;
        expect(prevSpots.length, 3);
        expect(prevSpots[0].y, 20.0);
        expect(prevSpots[1].y, 40.0);
        expect(prevSpots[2].y, 30.0);
      });

      testWidgets('cost mode skips null cost entries', (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 200),
          _period(DateTime(2026, 3, 1), 150),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            currentYearCosts: [25.0, null, 37.5],
            showCosts: true,
            costUnit: 'EUR',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots;
        // Only 2 spots (null cost for Feb is skipped)
        expect(spots.length, 2);
        expect(spots[0].x, 0); // Jan
        expect(spots[0].y, 25.0);
        expect(spots[1].x, 2); // Mar
        expect(spots[1].y, 37.5);
      });

      testWidgets(
          'showCosts=true with null currentYearCosts falls back to consumption',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 200),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            currentYearCosts: null,
            showCosts: true,
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots;
        // Falls back to consumption when costs are null
        expect(spots[0].y, 100);
        expect(spots[1].y, 200);
      });

      testWidgets('costUnit is not used when showCosts=false', (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
            costUnit: 'EUR',
            showCosts: false,
          )),
        );
        await tester.pumpAndSettle();

        // Widget renders normally without error
        expect(find.byType(LineChart), findsOneWidget);
      });
    });

    // ---------------------------------------------------------------
    // Bottom title label tests
    // ---------------------------------------------------------------

    group('bottom titles', () {
      TitleMeta buildMeta() => TitleMeta(
            min: 0,
            max: 11,
            parentAxisSize: 400,
            axisPosition: 0,
            appliedInterval: 1,
            sideTitles: SideTitles(),
            formattedValue: '',
            axisSide: AxisSide.bottom,
          );

      testWidgets('shows every month label when range <= 6 months',
          (tester) async {
        // 4 months Jan-Apr -> range = 4
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
          _period(DateTime(2026, 2, 1), 120),
          _period(DateTime(2026, 3, 1), 90),
          _period(DateTime(2026, 4, 1), 110),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final getTitles =
            data.titlesData.bottomTitles.sideTitles.getTitlesWidget;

        // All 4 months should return non-empty widgets (SideTitleWidget)
        for (int i = 0; i <= 3; i++) {
          final widget = getTitles(i.toDouble(), buildMeta());
          expect(widget, isA<SideTitleWidget>(),
              reason: 'Month index $i should show a title');
        }
      });

      testWidgets('shows every other month label when range > 6 months',
          (tester) async {
        // Full 12-month year -> range = 12
        final currentYear = List.generate(
          12,
          (i) => _period(DateTime(2026, i + 1, 1), (i + 1) * 50.0),
        );

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final getTitles =
            data.titlesData.bottomTitles.sideTitles.getTitlesWidget;

        // Odd indices should be skipped (SizedBox.shrink)
        final oddWidget = getTitles(1.0, buildMeta());
        expect(oddWidget, isA<SizedBox>());

        // Even indices should show a title
        final evenWidget = getTitles(0.0, buildMeta());
        expect(evenWidget, isA<SideTitleWidget>());
      });

      testWidgets('out-of-range index returns SizedBox.shrink',
          (tester) async {
        final currentYear = [
          _period(DateTime(2026, 1, 1), 100),
        ];

        await tester.pumpWidget(
          _wrap(YearComparisonChart(
            currentYear: currentYear,
            primaryColor: Colors.blue,
            unit: 'kWh',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final getTitles =
            data.titlesData.bottomTitles.sideTitles.getTitlesWidget;

        // Index -1 should be out of range
        final neg = getTitles(-1.0, buildMeta());
        expect(neg, isA<SizedBox>());

        // Index 12 should be out of range
        final over = getTitles(12.0, buildMeta());
        expect(over, isA<SizedBox>());
      });
    });
  });
}
