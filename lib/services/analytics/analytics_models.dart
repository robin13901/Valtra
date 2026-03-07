import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../interpolation/models.dart';

/// Meter type enum for analytics scoping.
enum MeterType { electricity, gas, water, heating }

/// Summary data for one meter type shown on the analytics hub.
class MeterTypeSummary {
  final MeterType meterType;
  final double? latestMonthConsumption; // null if insufficient data
  final bool hasInterpolation;
  final String unit; // 'kWh', 'm³', 'units'

  const MeterTypeSummary({
    required this.meterType,
    required this.latestMonthConsumption,
    required this.hasInterpolation,
    required this.unit,
  });
}

/// Chart-ready data point combining value + interpolation flag.
class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  final bool isInterpolated;

  const ChartDataPoint({
    required this.timestamp,
    required this.value,
    required this.isInterpolated,
  });
}

/// Complete data package for the monthly analytics screen.
class MonthlyAnalyticsData {
  final MeterType meterType;
  final DateTime month; // 1st of selected month
  final List<ChartDataPoint> dailyValues; // line chart (boundaries within month)
  final List<PeriodConsumption> recentMonths; // bar chart (last 6 months)
  final double? totalConsumption; // sum for selected month
  final String unit;

  const MonthlyAnalyticsData({
    required this.meterType,
    required this.month,
    required this.dailyValues,
    required this.recentMonths,
    required this.totalConsumption,
    required this.unit,
  });
}

/// Returns the brand color associated with a [MeterType].
Color colorForMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity:
      return AppColors.electricityColor;
    case MeterType.gas:
      return AppColors.gasColor;
    case MeterType.water:
      return AppColors.waterColor;
    case MeterType.heating:
      return AppColors.heatingColor;
  }
}

/// Returns the icon associated with a [MeterType].
IconData iconForMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity:
      return Icons.electric_bolt;
    case MeterType.gas:
      return Icons.local_fire_department;
    case MeterType.water:
      return Icons.water_drop;
    case MeterType.heating:
      return Icons.thermostat;
  }
}

/// Returns the display unit string for a [MeterType].
String unitForMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity:
      return 'kWh';
    case MeterType.gas:
      return 'm\u00B3';
    case MeterType.water:
      return 'm\u00B3';
    case MeterType.heating:
      return 'units';
  }
}
