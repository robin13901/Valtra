import 'interpolation/models.dart';

/// Converts gas consumption from m³ to kWh using a configurable factor.
class GasConversionService {
  /// Default conversion factor: kWh per m³ (German natural gas average).
  static const double defaultFactor = 10.3;

  /// Convert cubic meters to kWh.
  double toKwh(double cubicMeters, {double factor = defaultFactor}) =>
      cubicMeters * factor;

  /// Convert a PeriodConsumption from m³ values to kWh.
  PeriodConsumption toKwhConsumption(
    PeriodConsumption period, {
    double factor = defaultFactor,
  }) {
    return PeriodConsumption(
      periodStart: period.periodStart,
      periodEnd: period.periodEnd,
      startValue: period.startValue * factor,
      endValue: period.endValue * factor,
      consumption: period.consumption * factor,
      startInterpolated: period.startInterpolated,
      endInterpolated: period.endInterpolated,
    );
  }

  /// Convert a list of PeriodConsumptions from m³ to kWh.
  List<PeriodConsumption> toKwhConsumptions(
    List<PeriodConsumption> periods, {
    double factor = defaultFactor,
  }) {
    return periods
        .map((p) => toKwhConsumption(p, factor: factor))
        .toList();
  }
}
