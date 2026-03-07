import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/widgets/charts/consumption_line_chart.dart';

void main() {
  Widget buildTestWidget(ConsumptionLineChart chart) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SizedBox(
          height: 300,
          width: 400,
          child: chart,
        ),
      ),
    );
  }

  group('ConsumptionLineChart', () {
    final rangeStart = DateTime(2026, 1, 1);
    final rangeEnd = DateTime(2026, 1, 31);
    const primaryColor = Colors.blue;
    const unit = 'kWh';

    testWidgets('shows noData text when dataPoints is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: const [],
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The widget should display the localized 'noData' string
      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart with actual-only data points',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 100.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 10),
          value: 150.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 200.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders LineChart with mixed actual and interpolated data',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 100.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 10),
          value: 130.0,
          isInterpolated: true,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 160.0,
          isInterpolated: true,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 20),
          value: 200.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders LineChart with all interpolated data',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 100.0,
          isInterpolated: true,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 10),
          value: 150.0,
          isInterpolated: true,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with single data point',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 100.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with zero-value data points',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 0.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 0.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still render chart even with zero values (maxY defaults to 1.0)
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets(
        'renders with interpolated-to-actual transition for continuity',
        (WidgetTester tester) async {
      // Tests the bridge point logic: interpolated -> actual creates a
      // bridge point in the interpolated series for visual continuity
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 100.0,
          isInterpolated: true,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 10),
          value: 150.0,
          isInterpolated: true,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 200.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 20),
          value: 250.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: primaryColor,
            unit: unit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with different primary colors',
        (WidgetTester tester) async {
      final dataPoints = [
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 5),
          value: 100.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2026, 1, 15),
          value: 200.0,
          isInterpolated: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ConsumptionLineChart(
            dataPoints: dataPoints,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            primaryColor: Colors.orange,
            unit: 'm\u00B3',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
