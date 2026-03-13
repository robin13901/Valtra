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

    testWidgets('Y-axis shows unit label in consumption mode', (tester) async {
      final periods = buildSamplePeriods();

      await tester.pumpWidget(
        buildTestWidget(periods: periods, unit: 'kWh', showCosts: false),
      );
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final data = barChart.data;
      final axisNameWidget = data.titlesData.leftTitles.axisNameWidget;

      expect(axisNameWidget, isNotNull);
      expect(axisNameWidget, isA<Text>());
      expect((axisNameWidget as Text).data, 'kWh');
    });

    testWidgets('Y-axis shows costUnit label in cost mode', (tester) async {
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
      final axisNameWidget = data.titlesData.leftTitles.axisNameWidget;

      expect(axisNameWidget, isNotNull);
      expect(axisNameWidget, isA<Text>());
      expect((axisNameWidget as Text).data, 'EUR');
    });

    testWidgets('Y-axis shows unit when showCosts=true but costUnit is null',
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
      final axisNameWidget = data.titlesData.leftTitles.axisNameWidget;

      expect(axisNameWidget, isNotNull);
      expect(axisNameWidget, isA<Text>());
      // Falls back to unit when costUnit is null
      expect((axisNameWidget as Text).data, 'kWh');
    });
  });
}
