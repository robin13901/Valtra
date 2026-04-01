import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';
import '../../services/number_format_service.dart';
import 'chart_axis_style.dart';

/// Data for one household in the comparison chart.
class HouseholdChartData {
  /// Display name of the household.
  final String name;

  /// Monthly consumption data for this household.
  final List<PeriodConsumption> periods;

  /// Color for this household's line (from pieChartColors by default).
  final Color color;

  const HouseholdChartData({
    required this.name,
    required this.periods,
    required this.color,
  });
}

/// A multi-line chart comparing monthly consumption across households.
///
/// Each household is rendered as a separate line. Actual values use solid lines
/// with filled dots; interpolated values use dashed lines with open dots.
class HouseholdComparisonChart extends StatelessWidget {
  /// Data for each household to compare.
  final List<HouseholdChartData> households;

  /// Display unit (e.g., 'kWh', 'm3').
  final String unit;

  /// Locale for formatting month names and numbers.
  final String locale;

  const HouseholdComparisonChart({
    super.key,
    required this.households,
    required this.unit,
    this.locale = 'de',
  });

  @override
  Widget build(BuildContext context) {
    if (households.isEmpty || households.every((h) => h.periods.isEmpty)) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return LineChart(
      _buildData(context),
      duration: const Duration(milliseconds: 300),
    );
  }

  LineChartData _buildData(BuildContext context) {
    final lineBars = <LineChartBarData>[];

    for (final household in households) {
      if (household.periods.isEmpty) continue;

      // Split periods into actual and interpolated segments
      final actualSpots = <FlSpot>[];
      final interpolatedSpots = <FlSpot>[];

      for (final period in household.periods) {
        final x = (period.periodStart.month - 1).toDouble() +
            ((period.periodStart.year - _minYear) * 12);
        final spot = FlSpot(x, period.consumption);
        final isInterpolated =
            period.startInterpolated || period.endInterpolated || period.isExtrapolated;

        if (isInterpolated) {
          interpolatedSpots.add(spot);
          actualSpots.add(FlSpot.nullSpot);
        } else {
          actualSpots.add(spot);
          interpolatedSpots.add(FlSpot.nullSpot);
        }
      }

      // HCMP-02: Actual values = solid line + filled dots
      if (actualSpots.any((s) => s != FlSpot.nullSpot)) {
        lineBars.add(LineChartBarData(
          spots: actualSpots,
          color: household.color,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 4,
              color: household.color,
              strokeColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ));
      }

      // HCMP-02: Interpolated values = dashed line + open dots
      if (interpolatedSpots.any((s) => s != FlSpot.nullSpot)) {
        lineBars.add(LineChartBarData(
          spots: interpolatedSpots,
          color: household.color.withValues(alpha: 0.5),
          barWidth: 2.0,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          dashArray: [8, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 3,
              color: Theme.of(context).colorScheme.surface,
              strokeColor: household.color.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    final allValues = lineBars
        .expand((bar) => bar.spots)
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.y);
    final maxVal =
        allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;

    final allX = lineBars
        .expand((bar) => bar.spots)
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.x);
    final maxX = allX.isEmpty ? 11.0 : allX.reduce((a, b) => a > b ? a : b);
    final minX = allX.isEmpty ? 0.0 : allX.reduce((a, b) => a < b ? a : b);

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: lineBars,
      titlesData: _buildTitles(context, minX, maxX),
      gridData: ChartAxisStyle.gridData(context),
      borderData: ChartAxisStyle.borderData(context),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthIndex = spot.x.toInt() % 12;
              final monthName =
                  DateFormat.MMM(locale).format(DateTime(2024, monthIndex + 1));
              final valueStr = ValtraNumberFormat.consumption(spot.y, locale);
              return LineTooltipItem(
                '$monthName\n$valueStr $unit',
                TextStyle(
                  color: spot.bar.color ?? Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  int get _minYear {
    int min = 9999;
    for (final h in households) {
      for (final p in h.periods) {
        if (p.periodStart.year < min) min = p.periodStart.year;
      }
    }
    return min == 9999 ? DateTime.now().year : min;
  }

  FlTitlesData _buildTitles(BuildContext context, double minX, double maxX) {
    return FlTitlesData(
      topTitles: ChartAxisStyle.hiddenTitles,
      rightTitles: ChartAxisStyle.hiddenTitles,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            final monthIndex = index % 12;
            if (monthIndex < 0 || monthIndex > 11) {
              return const SizedBox.shrink();
            }
            // Show every other label if range > 6
            final range = (maxX - minX).toInt() + 1;
            if (range > 6 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final monthName =
                DateFormat.MMM(locale).format(DateTime(2024, monthIndex + 1));
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(monthName,
                  style: Theme.of(context).textTheme.bodySmall),
            );
          },
        ),
      ),
      leftTitles: ChartAxisStyle.leftTitles(context: context, unit: unit),
    );
  }
}
