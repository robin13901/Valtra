/// Interpolation method for estimating meter values between readings.
enum InterpolationMethod { linear, step }

/// A generic reading point, agnostic of meter type.
typedef ReadingPoint = ({DateTime timestamp, double value});

/// A value at a specific point in time, possibly interpolated.
class TimestampedValue {
  final DateTime timestamp;
  final double value;
  final bool isInterpolated;

  const TimestampedValue({
    required this.timestamp,
    required this.value,
    required this.isInterpolated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimestampedValue &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          value == other.value &&
          isInterpolated == other.isInterpolated;

  @override
  int get hashCode => Object.hash(timestamp, value, isInterpolated);

  @override
  String toString() =>
      'TimestampedValue(timestamp: $timestamp, value: $value, isInterpolated: $isInterpolated)';
}

/// Consumption for a period derived from two boundary values.
class PeriodConsumption {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double startValue;
  final double endValue;
  final double consumption;
  final bool startInterpolated;
  final bool endInterpolated;

  const PeriodConsumption({
    required this.periodStart,
    required this.periodEnd,
    required this.startValue,
    required this.endValue,
    required this.consumption,
    required this.startInterpolated,
    required this.endInterpolated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodConsumption &&
          runtimeType == other.runtimeType &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          startValue == other.startValue &&
          endValue == other.endValue &&
          consumption == other.consumption &&
          startInterpolated == other.startInterpolated &&
          endInterpolated == other.endInterpolated;

  @override
  int get hashCode => Object.hash(
        periodStart,
        periodEnd,
        startValue,
        endValue,
        consumption,
        startInterpolated,
        endInterpolated,
      );

  @override
  String toString() =>
      'PeriodConsumption(periodStart: $periodStart, periodEnd: $periodEnd, '
      'startValue: $startValue, endValue: $endValue, consumption: $consumption, '
      'startInterpolated: $startInterpolated, endInterpolated: $endInterpolated)';
}
