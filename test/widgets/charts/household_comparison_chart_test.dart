import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';
import 'package:valtra/widgets/charts/household_comparison_chart.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: SizedBox(height: 300, width: 400, child: child)),
  );
}

PeriodConsumption _period(DateTime start, double consumption, {
  bool interpolated = false,
  bool extrapolated = false,
}) {
  return PeriodConsumption(
    periodStart: start,
    periodEnd: DateTime(start.year, start.month + 1, 1),
    startValue: 0,
    endValue: consumption,
    consumption: consumption,
    startInterpolated: interpolated,
    endInterpolated: interpolated,
    isExtrapolated: extrapolated,
  );
}

LineChartData _extractChartData(WidgetTester tester) {
  final lineChart = tester.widget<LineChart>(find.byType(LineChart));
  return lineChart.data;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  group('HouseholdComparisonChart', () {
    testWidgets('shows noData when households list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const HouseholdComparisonChart(
          households: [],
          unit: 'kWh',
          locale: 'en',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('shows noData when all households have empty periods', (tester) async {
      await tester.pumpWidget(
        _wrap(HouseholdComparisonChart(
          households: [
            HouseholdChartData(name: 'Home', periods: const [], color: pieChartColors[0]),
          ],
          unit: 'kWh',
          locale: 'en',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('renders LineChart with single household', (tester) async {
      await tester.pumpWidget(
        _wrap(HouseholdComparisonChart(
          households: [
            HouseholdChartData(
              name: 'Home',
              periods: [
                _period(DateTime(2026, 1, 1), 100),
                _period(DateTime(2026, 2, 1), 120),
                _period(DateTime(2026, 3, 1), 90),
              ],
              color: pieChartColors[0],
            ),
          ],
          unit: 'kWh',
          locale: 'en',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders multiple household lines', (tester) async {
      await tester.pumpWidget(
        _wrap(HouseholdComparisonChart(
          households: [
            HouseholdChartData(
              name: 'Home A',
              periods: [
                _period(DateTime(2026, 1, 1), 100),
                _period(DateTime(2026, 2, 1), 120),
              ],
              color: pieChartColors[0],
            ),
            HouseholdChartData(
              name: 'Home B',
              periods: [
                _period(DateTime(2026, 1, 1), 80),
                _period(DateTime(2026, 2, 1), 110),
              ],
              color: pieChartColors[1],
            ),
          ],
          unit: 'kWh',
          locale: 'en',
        )),
      );
      await tester.pumpAndSettle();

      final data = _extractChartData(tester);
      // Each household with only actual data produces 1 line
      expect(data.lineBarsData.length, 2);
    });

    // ---------------------------------------------------------------
    // HCMP-02: Actual vs Interpolated visual distinction
    // ---------------------------------------------------------------

    group('actual vs interpolated (HCMP-02)', () {
      testWidgets('actual values produce solid line (no dashArray)', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [
                  _period(DateTime(2026, 1, 1), 100),
                  _period(DateTime(2026, 2, 1), 120),
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final actualLine = data.lineBarsData[0];
        expect(actualLine.dashArray, isNull);
      });

      testWidgets('interpolated values produce dashed line', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [
                  _period(DateTime(2026, 1, 1), 100, interpolated: true),
                  _period(DateTime(2026, 2, 1), 120, interpolated: true),
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        // Only interpolated data -> only dashed line
        final dashedLine = data.lineBarsData[0];
        expect(dashedLine.dashArray, isNotNull);
        expect(dashedLine.dashArray, [8, 4]);
      });

      testWidgets('mixed data produces both solid and dashed lines for same household', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [
                  _period(DateTime(2026, 1, 1), 100), // actual
                  _period(DateTime(2026, 2, 1), 120, interpolated: true), // interpolated
                  _period(DateTime(2026, 3, 1), 90), // actual
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        // Should have 2 lines: actual (solid) and interpolated (dashed)
        expect(data.lineBarsData.length, 2);

        final solidLine = data.lineBarsData.firstWhere((l) => l.dashArray == null);
        final dashedLine = data.lineBarsData.firstWhere((l) => l.dashArray != null);

        expect(solidLine, isNotNull);
        expect(dashedLine.dashArray, [8, 4]);
      });

      testWidgets('extrapolated periods are treated as interpolated (dashed)', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [
                  _period(DateTime(2026, 1, 1), 100, extrapolated: true),
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        final line = data.lineBarsData[0];
        expect(line.dashArray, isNotNull);
      });
    });

    // ---------------------------------------------------------------
    // HCMP-01: Color assignment
    // ---------------------------------------------------------------

    group('color assignment (HCMP-01)', () {
      testWidgets('each household line uses its assigned color', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'A',
                periods: [_period(DateTime(2026, 1, 1), 100)],
                color: pieChartColors[0],
              ),
              HouseholdChartData(
                name: 'B',
                periods: [_period(DateTime(2026, 1, 1), 80)],
                color: pieChartColors[1],
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        expect(data.lineBarsData[0].color, pieChartColors[0]);
        expect(data.lineBarsData[1].color, pieChartColors[1]);
      });
    });

    // ---------------------------------------------------------------
    // AXIS-01/02: Axis style tests
    // ---------------------------------------------------------------

    group('axis style (AXIS-01/02)', () {
      testWidgets('has no left border (AXIS-01)', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [_period(DateTime(2026, 1, 1), 100)],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        expect(data.borderData.border.left, BorderSide.none);
        expect(data.borderData.border.bottom, isNot(BorderSide.none));
      });

      testWidgets('grid lines are dashed horizontal only', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [_period(DateTime(2026, 1, 1), 100)],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        final data = _extractChartData(tester);
        expect(data.gridData.show, isTrue);
        expect(data.gridData.drawVerticalLine, isFalse);
        final line = data.gridData.getDrawingHorizontalLine(50);
        expect(line.dashArray, [4, 4]);
      });
    });

    // ---------------------------------------------------------------
    // Edge cases
    // ---------------------------------------------------------------

    group('edge cases', () {
      testWidgets('handles household with zero consumption', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [
                  _period(DateTime(2026, 1, 1), 0),
                  _period(DateTime(2026, 2, 1), 0),
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('handles household with single data point', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Home',
                periods: [_period(DateTime(2026, 6, 1), 200)],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);

        final data = _extractChartData(tester);
        final spots = data.lineBarsData[0].spots.where((s) => s != FlSpot.nullSpot).toList();
        expect(spots.length, 1);
        expect(spots[0].y, 200);
      });

      testWidgets('skips household with empty periods in mixed list', (tester) async {
        await tester.pumpWidget(
          _wrap(HouseholdComparisonChart(
            households: [
              HouseholdChartData(
                name: 'Empty',
                periods: const [],
                color: Colors.red,
              ),
              HouseholdChartData(
                name: 'HasData',
                periods: [
                  _period(DateTime(2026, 1, 1), 100),
                  _period(DateTime(2026, 2, 1), 120),
                ],
                color: Colors.blue,
              ),
            ],
            unit: 'kWh',
            locale: 'en',
          )),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);

        final data = _extractChartData(tester);
        // Only 1 line (the household with data)
        expect(data.lineBarsData.length, 1);
        expect(data.lineBarsData[0].color, Colors.blue);
      });
    });
  });
}
