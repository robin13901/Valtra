import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/interpolation/models.dart';
import 'package:valtra/widgets/charts/monthly_bar_chart.dart';

void main() {
  Widget buildTestWidget({
    List<PeriodConsumption> periods = const [],
    Color primaryColor = Colors.blue,
    String unit = 'kWh',
    DateTime? highlightMonth,
    List<double?>? periodCosts,
    bool showCosts = false,
    String? costUnit,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
      await tester.pumpWidget(buildTestWidget());
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
}
