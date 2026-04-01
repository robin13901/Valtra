import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/interpolation/models.dart';
import 'package:valtra/widgets/charts/monthly_bar_chart.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  Widget buildTestWidget({
    List<PeriodConsumption> periods = const [],
    Color primaryColor = Colors.blue,
    String unit = 'kWh',
    DateTime? highlightMonth,
    List<double?>? periodCosts,
    bool showCosts = false,
    String? costUnit,
    String locale = 'de',
    int visibleBars = 12,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(
        body: SizedBox(
          height: 300,
          width: 400,
          child: MonthlyBarChart(
            periods: periods,
            primaryColor: primaryColor,
            unit: unit,
            highlightMonth: highlightMonth,
            periodCosts: periodCosts,
            showCosts: showCosts,
            costUnit: costUnit,
            locale: locale,
            visibleBars: visibleBars,
          ),
        ),
      ),
    );
  }

  List<PeriodConsumption> buildSamplePeriods() {
    return [
      PeriodConsumption(
        periodStart: DateTime(2025, 1, 1),
        periodEnd: DateTime(2025, 2, 1),
        startValue: 100,
        endValue: 150,
        consumption: 50,
        startInterpolated: false,
        endInterpolated: false,
      ),
      PeriodConsumption(
        periodStart: DateTime(2025, 2, 1),
        periodEnd: DateTime(2025, 3, 1),
        startValue: 150,
        endValue: 220,
        consumption: 70,
        startInterpolated: false,
        endInterpolated: false,
      ),
      PeriodConsumption(
        periodStart: DateTime(2025, 3, 1),
        periodEnd: DateTime(2025, 4, 1),
        startValue: 220,
        endValue: 280,
        consumption: 60,
        startInterpolated: true,
        endInterpolated: false,
      ),
    ];
  }

  group('MonthlyBarChart', () {
    testWidgets('shows noData text when periods list is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders BarChart when periods are provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(periods: buildSamplePeriods()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders without error with highlightMonth set',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          periods: buildSamplePeriods(),
          highlightMonth: DateTime(2025, 2, 15),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with interpolated periods without error',
        (tester) async {
      final periods = [
        PeriodConsumption(
          periodStart: DateTime(2025, 1, 1),
          periodEnd: DateTime(2025, 2, 1),
          startValue: 100,
          endValue: 150,
          consumption: 50,
          startInterpolated: true,
          endInterpolated: true,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(periods: periods));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with zero consumption values', (tester) async {
      final periods = [
        PeriodConsumption(
          periodStart: DateTime(2025, 1, 1),
          periodEnd: DateTime(2025, 2, 1),
          startValue: 100,
          endValue: 100,
          consumption: 0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(periods: periods));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('uses custom unit and color', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          periods: buildSamplePeriods(),
          primaryColor: Colors.green,
          unit: 'm\u00B3',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });
  });

  group('MonthlyBarChart - cost mode', () {
    testWidgets('showCosts=true renders bar heights from periodCosts',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          showCosts: true,
          periodCosts: [15.0, 21.0, 18.0],
          costUnit: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);

      // Extract BarChartData to verify bar heights
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      expect(data.barGroups.length, 3);
      expect(data.barGroups[0].barRods[0].toY, 15.0);
      expect(data.barGroups[1].barRods[0].toY, 21.0);
      expect(data.barGroups[2].barRods[0].toY, 18.0);
    });

    testWidgets('showCosts=false (default) uses consumption values',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          showCosts: false,
          periodCosts: [15.0, 21.0, 18.0],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);

      // Extract BarChartData to verify bar heights use consumption
      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      expect(data.barGroups[0].barRods[0].toY, 50.0); // consumption
      expect(data.barGroups[1].barRods[0].toY, 70.0);
      expect(data.barGroups[2].barRods[0].toY, 60.0);
    });

    testWidgets('showCosts=true with null periodCosts falls back to consumption',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          showCosts: true,
          periodCosts: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      // Falls back to consumption values
      expect(data.barGroups[0].barRods[0].toY, 50.0);
      expect(data.barGroups[1].barRods[0].toY, 70.0);
      expect(data.barGroups[2].barRods[0].toY, 60.0);
    });

    testWidgets('cost mode skips null cost entries (falls back to consumption)',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          showCosts: true,
          periodCosts: [15.0, null, 18.0],
          costUnit: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      expect(data.barGroups[0].barRods[0].toY, 15.0);
      expect(data.barGroups[1].barRods[0].toY, 70.0); // null cost -> consumption
      expect(data.barGroups[2].barRods[0].toY, 18.0);
    });

    testWidgets('maxY is computed from cost values in cost mode',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          showCosts: true,
          periodCosts: [100.0, 200.0, 150.0],
          costUnit: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      // maxY should be 200 * 1.2 = 240
      expect(data.maxY, closeTo(240.0, 0.01));
    });
  });

  // ---------------------------------------------------------------
  // Locale-aware month label tests
  // ---------------------------------------------------------------

  group('MonthlyBarChart - locale-aware month labels', () {
    TitleMeta buildMeta() => TitleMeta(
          min: 0,
          max: 100,
          parentAxisSize: 300,
          axisPosition: 0,
          appliedInterval: 1,
          sideTitles: SideTitles(),
          formattedValue: '',
          axisSide: AxisSide.bottom,
        );

    testWidgets('locale=de renders German month abbreviations on X-axis',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(periods: periods, locale: 'de'),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      final getTitles =
          data.titlesData.bottomTitles.sideTitles.getTitlesWidget;

      // Index 0 = January -> 'Jan' (same in DE and EN)
      final janWidget = getTitles(0.0, buildMeta());
      expect(janWidget, isA<SideTitleWidget>());
      final janSide = janWidget as SideTitleWidget;
      final janText = janSide.child as Text;
      expect(janText.data, 'Jan');

      // Index 2 = March -> German abbreviation 'Mrz' or 'März'
      final marWidget = getTitles(2.0, buildMeta());
      expect(marWidget, isA<SideTitleWidget>());
      final marSide = marWidget as SideTitleWidget;
      final marText = marSide.child as Text;
      // German abbreviation for March varies by platform (Mrz or Mär)
      expect(marText.data, isNotNull);
      expect(marText.data, isNot('Mar')); // Must not be English
    });

    testWidgets('locale=en renders English month abbreviations on X-axis',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(periods: periods, locale: 'en'),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      final getTitles =
          data.titlesData.bottomTitles.sideTitles.getTitlesWidget;

      // Index 2 = March -> English 'Mar'
      final marWidget = getTitles(2.0, buildMeta());
      expect(marWidget, isA<SideTitleWidget>());
      final marSide = marWidget as SideTitleWidget;
      final marText = marSide.child as Text;
      expect(marText.data, 'Mar');
    });

    // ChartAxisStyle uses inline labels in sideTitles.getTitlesWidget (not axisNameWidget).
    // Unit is embedded in the label text as "{value} {unit}" format.
    testWidgets('Y-axis left titles are shown in consumption mode', (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(periods: periods, unit: 'kWh', showCosts: false),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      // ChartAxisStyle uses sideTitles with showTitles: true (no axisNameWidget)
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    });

    testWidgets('Y-axis left titles are shown in cost mode', (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          unit: 'kWh',
          showCosts: true,
          costUnit: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    });

    testWidgets('Y-axis left titles shown when showCosts=true but costUnit is null',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          unit: 'kWh',
          showCosts: true,
          costUnit: null,
        ),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      // Falls back to unit when costUnit is null; left titles still shown
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    });

    testWidgets('Y-axis label widget includes unit text for consumption mode',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(periods: periods, unit: 'kWh', showCosts: false),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final getTitles =
          barChart.data.titlesData.leftTitles.sideTitles.getTitlesWidget;
      // Call with a mid-range value (not min or max) to get a real label
      final meta = TitleMeta(
        min: 0,
        max: 100,
        parentAxisSize: 300,
        axisPosition: 0,
        appliedInterval: 25,
        sideTitles: SideTitles(),
        formattedValue: '',
        axisSide: AxisSide.left,
      );
      final labelWidget = getTitles(50.0, meta);
      expect(labelWidget, isA<SideTitleWidget>());
      final text = (labelWidget as SideTitleWidget).child as Text;
      expect(text.data, contains('kWh'));
    });

    testWidgets('Y-axis label widget includes costUnit text in cost mode',
        (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(
          periods: periods,
          unit: 'kWh',
          showCosts: true,
          costUnit: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final getTitles =
          barChart.data.titlesData.leftTitles.sideTitles.getTitlesWidget;
      final meta = TitleMeta(
        min: 0,
        max: 100,
        parentAxisSize: 300,
        axisPosition: 0,
        appliedInterval: 25,
        sideTitles: SideTitles(),
        formattedValue: '',
        axisSide: AxisSide.left,
      );
      final labelWidget = getTitles(50.0, meta);
      expect(labelWidget, isA<SideTitleWidget>());
      final text = (labelWidget as SideTitleWidget).child as Text;
      expect(text.data, contains('EUR'));
    });
  });

  // ---------------------------------------------------------------
  // BAR-01: Horizontal scrolling tests
  // ---------------------------------------------------------------

  group('MonthlyBarChart - horizontal scrolling (BAR-01)', () {
    List<PeriodConsumption> buildManyPeriods(int count) {
      return List.generate(
          count,
          (i) => PeriodConsumption(
                periodStart: DateTime(2025, 1 + (i % 12), 1),
                periodEnd: DateTime(2025, 1 + ((i + 1) % 12), 1),
                startValue: 100.0 * i,
                endValue: 100.0 * (i + 1),
                consumption: 50.0 + i * 5,
                startInterpolated: false,
                endInterpolated: false,
              ));
    }

    testWidgets('does not use ScrollView when periods <= visibleBars',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        periods: buildSamplePeriods(), // 3 periods, visibleBars defaults to 12
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('uses horizontal ScrollView when periods > visibleBars',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        periods: buildManyPeriods(15),
        visibleBars: 12,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // Two BarCharts: one for fixed Y-axis, one for scrollable content
      expect(find.byType(BarChart), findsNWidgets(2));
    });

    testWidgets('renders all bar groups in scrollable mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        periods: buildManyPeriods(18),
        visibleBars: 12,
      ));
      await tester.pumpAndSettle();

      // The scrollable BarChart should have all 18 bar groups
      final barCharts =
          tester.widgetList<BarChart>(find.byType(BarChart)).toList();
      // Second BarChart is the scrollable one with actual data
      final scrollableChart = barCharts.last;
      expect(scrollableChart.data.barGroups.length, 18);
    });
  });

  // ---------------------------------------------------------------
  // BAR-02: Glow effect tests
  // ---------------------------------------------------------------

  group('MonthlyBarChart - glow effect (BAR-02)', () {
    testWidgets('highlighted bar has backDrawRodData with translucent color',
        (tester) async {
      final periods = buildSamplePeriods(); // 3 periods: Jan, Feb, Mar 2025

      await tester.pumpWidget(buildTestWidget(
        periods: periods,
        highlightMonth: DateTime(2025, 2, 1), // Highlight February
        primaryColor: Colors.amber,
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;

      // Bar at index 1 (February) should have backDrawRodData.show = true
      final highlightedBar = data.barGroups[1].barRods[0];
      expect(highlightedBar.backDrawRodData.show, isTrue);
      expect(highlightedBar.backDrawRodData.toY, highlightedBar.toY);

      // Non-highlighted bars should have backDrawRodData.show = false
      final normalBar = data.barGroups[0].barRods[0];
      expect(normalBar.backDrawRodData.show, isFalse);
    });

    testWidgets('highlighted bar has full opacity', (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(buildTestWidget(
        periods: periods,
        highlightMonth: DateTime(2025, 2, 1),
        primaryColor: Colors.amber,
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;

      // Highlighted bar should have full opacity (alpha = 1.0)
      final highlightedColor = data.barGroups[1].barRods[0].color!;
      expect(highlightedColor.a, closeTo(1.0, 0.01));
    });
  });

  // ---------------------------------------------------------------
  // BAR-03: Opacity tests (past opaque, future transparent)
  // ---------------------------------------------------------------

  group('MonthlyBarChart - opacity (BAR-03)', () {
    testWidgets('extrapolated bars have low opacity', (tester) async {
      final periods = [
        PeriodConsumption(
          periodStart: DateTime(2025, 1, 1),
          periodEnd: DateTime(2025, 2, 1),
          startValue: 100,
          endValue: 150,
          consumption: 50,
          startInterpolated: false,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2025, 2, 1),
          periodEnd: DateTime(2025, 3, 1),
          startValue: 150,
          endValue: 200,
          consumption: 50,
          startInterpolated: false,
          endInterpolated: false,
          isExtrapolated: true,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        periods: periods,
        primaryColor: Colors.amber,
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;

      // Normal bar should have higher opacity
      final normalAlpha = data.barGroups[0].barRods[0].color!.a;
      // Extrapolated bar should have lower opacity (0.3)
      final extraAlpha = data.barGroups[1].barRods[0].color!.a;

      expect(normalAlpha, greaterThan(extraAlpha));
      expect(extraAlpha, closeTo(0.3, 0.05));
    });

    testWidgets('past bars have medium-high opacity', (tester) async {
      final periods = buildSamplePeriods(); // All in past (2025)

      await tester.pumpWidget(buildTestWidget(
        periods: periods,
        primaryColor: Colors.amber,
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;

      // Past bars should have alpha around 0.85
      for (final group in data.barGroups) {
        final alpha = group.barRods[0].color!.a;
        expect(alpha, closeTo(0.85, 0.05));
      }
    });
  });

  // ---------------------------------------------------------------
  // AXIS-01/02/03: Axis style tests
  // ---------------------------------------------------------------

  group('MonthlyBarChart - axis style (AXIS-01/02/03)', () {
    testWidgets('has no left border (AXIS-01)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        periods: buildSamplePeriods(),
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final border = barChart.data.borderData.border;
      expect(border.left, BorderSide.none);
      expect(border.bottom, isNot(BorderSide.none));
    });

    testWidgets('grid lines are dashed horizontal only', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        periods: buildSamplePeriods(),
      ));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final gridData = barChart.data.gridData;
      expect(gridData.show, isTrue);
      expect(gridData.drawVerticalLine, isFalse);

      final line = gridData.getDrawingHorizontalLine(50);
      expect(line.dashArray, [4, 4]);
    });
  });
}
