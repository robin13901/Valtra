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
  final double? latestMonthCost; // null if no cost config
  final String? currencySymbol; // '€'

  const MeterTypeSummary({
    required this.meterType,
    required this.latestMonthConsumption,
    required this.hasInterpolation,
    required this.unit,
    this.latestMonthCost,
    this.currencySymbol,
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
  final double? totalCost; // null if no cost config
  final String? currencySymbol;
  final List<double?>? periodCosts; // cost per period (parallel to recentMonths)

  const MonthlyAnalyticsData({
    required this.meterType,
    required this.month,
    required this.dailyValues,
    required this.recentMonths,
    required this.totalConsumption,
    required this.unit,
    this.totalCost,
    this.currencySymbol,
    this.periodCosts,
  });
}

/// Complete data package for the yearly analytics screen.
class YearlyAnalyticsData {
  final MeterType meterType;
  final int year;
  final List<PeriodConsumption> monthlyBreakdown; // 12 months (bar chart)
  final List<PeriodConsumption>? previousYearBreakdown; // 12 months (comparison)
  final double? totalConsumption; // sum of monthlyBreakdown
  final double? previousYearTotal; // sum of previousYearBreakdown
  final String unit;
  final double? totalCost; // null if no cost config
  final double? previousYearTotalCost; // for YoY comparison
  final String? currencySymbol;
  final double? extrapolatedTotal; // projected year-end total (current year only)
  final int? extrapolationBasisMonths; // how many actual months used for projection
  final List<double?>? monthlyCosts; // per-month cost (parallel to monthlyBreakdown)
  final List<double?>? previousYearMonthlyCosts; // per-month cost for previous year

  const YearlyAnalyticsData({
    required this.meterType,
    required this.year,
    required this.monthlyBreakdown,
    this.previousYearBreakdown,
    this.totalConsumption,
    this.previousYearTotal,
    required this.unit,
    this.totalCost,
    this.previousYearTotalCost,
    this.currencySymbol,
    this.extrapolatedTotal,
    this.extrapolationBasisMonths,
    this.monthlyCosts,
    this.previousYearMonthlyCosts,
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

// ============== Smart Plug Analytics Models ==============

/// Period selection for smart plug analytics.
enum AnalyticsPeriod { monthly, yearly }

/// A single slice of data for rendering in a pie chart.
class PieSliceData {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  const PieSliceData({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

/// Per-plug consumption breakdown.
class PlugConsumption {
  final int plugId;
  final String plugName;
  final String roomName;
  final double consumption;
  final Color color;

  const PlugConsumption({
    required this.plugId,
    required this.plugName,
    required this.roomName,
    required this.consumption,
    required this.color,
  });
}

/// Per-room consumption breakdown.
class RoomConsumption {
  final int roomId;
  final String roomName;
  final double consumption;
  final Color color;

  const RoomConsumption({
    required this.roomId,
    required this.roomName,
    required this.consumption,
    required this.color,
  });
}

/// Complete data package for the smart plug analytics screen.
class SmartPlugAnalyticsData {
  final List<PlugConsumption> byPlug;
  final List<RoomConsumption> byRoom;
  final double totalSmartPlug;
  final double? totalElectricity; // null if no electricity readings
  final double? otherConsumption; // null if totalElectricity is null; clamped to >= 0
  final String unit; // always 'kWh'

  const SmartPlugAnalyticsData({
    required this.byPlug,
    required this.byRoom,
    required this.totalSmartPlug,
    this.totalElectricity,
    this.otherConsumption,
    this.unit = 'kWh',
  });
}

/// Distinct colors for pie chart slices (up to 10 plugs/rooms).
const List<Color> pieChartColors = [
  Color(0xFF5F4A8B), // ultra violet (brand)
  Color(0xFFFFD93D), // electricity yellow
  Color(0xFF6BC5F8), // water blue
  Color(0xFFFF8C42), // gas orange
  Color(0xFFFF6B6B), // heating red
  Color(0xFF4ECDC4), // teal
  Color(0xFF95E1D3), // mint
  Color(0xFFF38181), // salmon
  Color(0xFFAA96DA), // lavender
  Color(0xFFFCBFB7), // blush
];

/// Single-hue (electricity yellow shades) colors for smart plug pie charts.
/// Satisfies SPLG-02: unified single-hue color scheme.
/// Colors alternate dark/light to ensure adjacent pie slices are visually distinct.
const List<Color> smartPlugPieColors = [
  Color(0xFFFFD93D), // electricity yellow -- brand
  Color(0xFFEFC000), // darker gold
  Color(0xFFFFE57A), // lighter yellow
  Color(0xFFD4A800), // deep amber
  Color(0xFFFFF0B0), // pale yellow
  Color(0xFFB88F00), // dark gold
  Color(0xFFFFEC99), // light amber
  Color(0xFFCC9900), // medium dark
  Color(0xFFFFF5CC), // very light
  Color(0xFFE6B800), // mid amber
];
