import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'analytics/analytics_models.dart';
import 'interpolation/models.dart';

/// Stateless service that transforms analytics data into CSV strings.
class CsvExportService {
  const CsvExportService();

  static const _converter = ListToCsvConverter();

  /// Export monthly analytics data to CSV string.
  String exportMonthlyData(MonthlyAnalyticsData data) {
    final hasCost = data.periodCosts != null &&
        data.periodCosts!.any((c) => c != null);

    final rows = <List<dynamic>>[
      [
        'Month',
        'Consumption',
        'Unit',
        'Interpolated',
        if (hasCost) 'Cost (${data.currencySymbol ?? '\u20AC'})',
      ],
    ];

    for (int i = 0; i < data.recentMonths.length; i++) {
      final period = data.recentMonths[i];
      rows.add([
        DateFormat('yyyy-MM').format(period.periodStart),
        period.consumption.toStringAsFixed(2),
        data.unit,
        (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
        if (hasCost)
          (data.periodCosts != null && i < data.periodCosts!.length &&
                  data.periodCosts![i] != null)
              ? data.periodCosts![i]!.toStringAsFixed(2)
              : '',
      ]);
    }

    return _converter.convert(rows);
  }

  /// Export yearly analytics data to CSV string.
  String exportYearlyData(YearlyAnalyticsData data) {
    final hasPrevious = data.previousYearBreakdown != null &&
        data.previousYearBreakdown!.isNotEmpty;
    final hasCost = data.totalCost != null;

    final headers = <String>[
      'Month',
      'Consumption',
      if (hasPrevious) 'Previous Year',
      'Unit',
      'Interpolated',
      if (hasCost) 'Cost (${data.currencySymbol ?? '\u20AC'})',
    ];

    final rows = <List<dynamic>>[headers];

    for (int i = 0; i < data.monthlyBreakdown.length; i++) {
      final period = data.monthlyBreakdown[i];
      final row = <dynamic>[
        DateFormat('yyyy-MM').format(period.periodStart),
        period.consumption.toStringAsFixed(2),
        if (hasPrevious)
          i < data.previousYearBreakdown!.length
              ? data.previousYearBreakdown![i].consumption.toStringAsFixed(2)
              : '',
        data.unit,
        (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
        if (hasCost) '', // Per-month cost not tracked in yearly model
      ];
      rows.add(row);
    }

    return _converter.convert(rows);
  }

  /// Export all meter types for a year.
  String exportAllMeters({
    required int year,
    required Map<MeterType, List<PeriodConsumption>> dataByType,
    Map<MeterType, List<double?>>? costsByType,
    String? currencySymbol,
  }) {
    final hasCost = costsByType != null && costsByType.isNotEmpty;

    final rows = <List<dynamic>>[
      [
        'Meter Type',
        'Month',
        'Consumption',
        'Unit',
        'Interpolated',
        if (hasCost) 'Cost (${currencySymbol ?? '\u20AC'})',
      ],
    ];

    for (final entry in dataByType.entries) {
      final type = entry.key;
      final unit = unitForMeterType(type);
      final displayUnit = type == MeterType.gas ? 'kWh' : unit;
      final costs = costsByType?[type];

      for (int i = 0; i < entry.value.length; i++) {
        final period = entry.value[i];
        rows.add([
          type.name,
          DateFormat('yyyy-MM').format(period.periodStart),
          period.consumption.toStringAsFixed(2),
          displayUnit,
          (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
          if (hasCost)
            (costs != null && i < costs.length && costs[i] != null)
                ? costs[i]!.toStringAsFixed(2)
                : '',
        ]);
      }
    }

    return _converter.convert(rows);
  }
}
