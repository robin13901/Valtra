import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Shared axis configuration enforcing AXIS-01, AXIS-02, and AXIS-03
/// across all Valtra charts.
///
/// All methods are static; this class cannot be instantiated.
class ChartAxisStyle {
  ChartAxisStyle._();

  /// AXIS-01: No vertical Y-axis line. Only bottom border.
  ///
  /// Returns a [FlBorderData] with only the bottom border visible,
  /// removing the vertical Y-axis line from all charts.
  static FlBorderData borderData(BuildContext context) => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          // NO left border = removes vertical Y-axis line (AXIS-01)
        ),
      );

  /// AXIS-02: Dashed horizontal grid lines, no vertical grid lines.
  ///
  /// Returns a [FlGridData] that draws only horizontal dashed lines
  /// (4px dash, 4px gap) at a translucent weight.
  static FlGridData gridData(BuildContext context) => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      );

  /// AXIS-03: Small translucent value labels with unit that float inside
  /// the chart area on the dashed horizontal grid lines.
  ///
  /// Used for the left (Y-axis) titles. Labels are skipped at [TitleMeta.min]
  /// and [TitleMeta.max] to avoid clutter at chart edges.
  static AxisTitles leftTitles({
    required BuildContext context,
    required String unit,
  }) =>
      AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            // Skip min and max values to avoid label overlap at edges
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
            );
          },
        ),
      );

  /// Hidden titles — used for top and right axis sides to suppress labels.
  ///
  /// Declared as a constant to avoid repeated instantiation.
  static const AxisTitles hiddenTitles = AxisTitles(
    sideTitles: SideTitles(showTitles: false),
  );
}
