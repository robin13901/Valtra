import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/widgets/charts/consumption_pie_chart.dart';

void main() {
  Widget buildSubject({
    List<PieSliceData> slices = const [],
    String unit = 'kWh',
    String locale = 'en',
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SizedBox(
          height: 250,
          width: 250,
          child: ConsumptionPieChart(
            slices: slices,
            unit: unit,
            locale: locale,
          ),
        ),
      ),
    );
  }

  group('ConsumptionPieChart', () {
    testWidgets('shows "No data available" when slices list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject(slices: []));
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders PieChart when slices are provided',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'TV',
          value: 40.0,
          percentage: 40.0,
          color: pieChartColors[0],
        ),
        PieSliceData(
          label: 'Fridge',
          value: 30.0,
          percentage: 30.0,
          color: pieChartColors[1],
        ),
        PieSliceData(
          label: 'Lamp',
          value: 30.0,
          percentage: 30.0,
          color: pieChartColors[2],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders correct number of sections matching slices count',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'A',
          value: 50.0,
          percentage: 50.0,
          color: pieChartColors[0],
        ),
        PieSliceData(
          label: 'B',
          value: 50.0,
          percentage: 50.0,
          color: pieChartColors[1],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sections, hasLength(2));
    });

    testWidgets('each section has correct color from slice data',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'A',
          value: 60.0,
          percentage: 60.0,
          color: pieChartColors[0],
        ),
        PieSliceData(
          label: 'B',
          value: 40.0,
          percentage: 40.0,
          color: pieChartColors[1],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sections[0].color, pieChartColors[0]);
      expect(pieChart.data.sections[1].color, pieChartColors[1]);
    });

    testWidgets('each section title shows percentage formatted as X.X%',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'A',
          value: 60.0,
          percentage: 60.0,
          color: pieChartColors[0],
        ),
        PieSliceData(
          label: 'B',
          value: 40.0,
          percentage: 40.0,
          color: pieChartColors[1],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sections[0].title, '60.0%');
      expect(pieChart.data.sections[1].title, '40.0%');
    });

    testWidgets('centerSpaceRadius creates a donut shape',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'Only',
          value: 100.0,
          percentage: 100.0,
          color: pieChartColors[0],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      // centerSpaceRadius > 0 means donut shape
      expect(pieChart.data.centerSpaceRadius, greaterThan(0));
      expect(pieChart.data.centerSpaceRadius, 40.0);
    });

    testWidgets('renders with single slice',
        (WidgetTester tester) async {
      final slices = [
        PieSliceData(
          label: 'Single',
          value: 100.0,
          percentage: 100.0,
          color: pieChartColors[0],
        ),
      ];

      await tester.pumpWidget(buildSubject(slices: slices));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sections, hasLength(1));
    });
  });
}
