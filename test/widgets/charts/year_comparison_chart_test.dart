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
  });
}
