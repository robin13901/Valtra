import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics/analytics_models.dart';
import '../../services/number_format_service.dart';

/// A line chart displaying consumption data points over a date range.
///
/// Actual readings are shown as a solid line with filled dots.
/// Interpolated readings are shown as a dashed line with hollow dots.
class ConsumptionLineChart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color primaryColor;
  final String unit;
  final String locale;

  const ConsumptionLineChart({
    super.key,
    required this.dataPoints,
    required this.rangeStart,
    required this.rangeEnd,
    required this.primaryColor,
    required this.unit,
    this.locale = 'de',
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return LineChart(
      _buildData(context),
      duration: const Duration(milliseconds: 300),
    );
  }

  LineChartData _buildData(BuildContext context) {
    final (actualSpots, interpolatedSpots) = _splitByInterpolation();
    return LineChartData(
      minX: rangeStart.millisecondsSinceEpoch.toDouble(),
      maxX: rangeEnd.millisecondsSinceEpoch.toDouble(),
      minY: 0,
      maxY: _calculateMaxY(),
      clipData: const FlClipData.all(),
      lineBarsData: [
        // Actual readings: solid line
        LineChartBarData(
          spots: actualSpots,
          color: primaryColor,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 4,
              color: primaryColor,
              strokeColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: primaryColor.withValues(alpha: 0.1),
          ),
        ),
        // Interpolated readings: dashed line
        if (interpolatedSpots.any((s) => s != FlSpot.nullSpot))
          LineChartBarData(
            spots: interpolatedSpots,
            color: primaryColor.withValues(alpha: 0.5),
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
                strokeColor: primaryColor.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
      titlesData: _buildTitles(context),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final dateStr = DateFormat.MMMd().format(date);
              final valueStr = ValtraNumberFormat.consumption(spot.y, locale);
              return LineTooltipItem(
                '$dateStr\n$valueStr $unit',
                TextStyle(
                  color: spot.bar.color ?? primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Split data points into actual (solid) and interpolated (dashed) FlSpot
  /// lists. Uses [FlSpot.nullSpot] to create gaps in lines where the other
  /// series has data, so fl_chart draws each segment independently.
  (List<FlSpot>, List<FlSpot>) _splitByInterpolation() {
    final actual = <FlSpot>[];
    final interpolated = <FlSpot>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      final spot = FlSpot(
        dp.timestamp.millisecondsSinceEpoch.toDouble(),
        dp.value,
      );

      if (dp.isInterpolated) {
        interpolated.add(spot);
        // Connect from previous actual point for visual continuity
        if (i > 0 && !dataPoints[i - 1].isInterpolated) {
          final prev = dataPoints[i - 1];
          interpolated.insert(
            interpolated.length - 1,
            FlSpot(
              prev.timestamp.millisecondsSinceEpoch.toDouble(),
              prev.value,
            ),
          );
        }
        actual.add(FlSpot.nullSpot);
      } else {
        actual.add(spot);
        if (i > 0 && dataPoints[i - 1].isInterpolated) {
          interpolated.add(spot); // bridge point for continuity
        } else {
          interpolated.add(FlSpot.nullSpot);
        }
      }
    }
    return (actual, interpolated);
  }

  FlTitlesData _buildTitles(BuildContext context) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final date =
                DateTime.fromMillisecondsSinceEpoch(value.toInt());
            if (date.day == 1 || date.day == 15) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  DateFormat.MMMd().format(date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (value == meta.min) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Calculate the maximum Y value with 10% headroom for visual padding.
  double _calculateMaxY() {
    if (dataPoints.isEmpty) return 1.0;
    final maxVal =
        dataPoints.map((dp) => dp.value).reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal * 1.1 : 1.0;
  }
}
