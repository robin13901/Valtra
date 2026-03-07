import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics/analytics_models.dart';
import '../../services/number_format_service.dart';

/// Reusable pie chart for consumption breakdown.
///
/// Follows the same stateless-widget-with-data-input pattern
/// as ConsumptionLineChart and MonthlyBarChart.
class ConsumptionPieChart extends StatelessWidget {
  final List<PieSliceData> slices;
  final String unit;
  final String locale;

  const ConsumptionPieChart({
    super.key,
    required this.slices,
    required this.unit,
    this.locale = 'de',
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return PieChart(
      PieChartData(
        sections: slices
            .map((s) => PieChartSectionData(
                  value: s.value,
                  color: s.color,
                  title: '${ValtraNumberFormat.consumption(s.percentage, locale)}%',
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ))
            .toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }
}
