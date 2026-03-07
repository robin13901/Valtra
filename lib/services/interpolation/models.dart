/// Interpolation method for estimating meter values between readings.
/// Only linear interpolation is supported (step was removed in Phase 15).
enum InterpolationMethod { linear }

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
  final bool isExtrapolated;

  const PeriodConsumption({
    required this.periodStart,
    required this.periodEnd,
    required this.startValue,
    required this.endValue,
    required this.consumption,
    required this.startInterpolated,
    required this.endInterpolated,
    this.isExtrapolated = false,
  });

  /// Create a copy with [isExtrapolated] set to true.
  PeriodConsumption copyWithExtrapolated() => PeriodConsumption(
        periodStart: periodStart,
        periodEnd: periodEnd,
        startValue: startValue,
        endValue: endValue,
        consumption: consumption,
        startInterpolated: startInterpolated,
        endInterpolated: endInterpolated,
        isExtrapolated: true,
      );

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
          endInterpolated == other.endInterpolated &&
          isExtrapolated == other.isExtrapolated;

  @override
  int get hashCode => Object.hash(
        periodStart,
        periodEnd,
        startValue,
        endValue,
        consumption,
        startInterpolated,
        endInterpolated,
        isExtrapolated,
      );

  @override
  String toString() =>
      'PeriodConsumption(periodStart: $periodStart, periodEnd: $periodEnd, '
      'startValue: $startValue, endValue: $endValue, consumption: $consumption, '
      'startInterpolated: $startInterpolated, endInterpolated: $endInterpolated, '
      'isExtrapolated: $isExtrapolated)';
}

/// A display item for reading lists that wraps either a real reading
/// (with delta) or an interpolated boundary value.
///
/// Used by meter providers when the interpolation toggle is ON.
class ReadingDisplayItem {
  /// The timestamp of the reading or interpolated value.
  final DateTime timestamp;

  /// The meter value at this point.
  final double value;

  /// Whether this item is an interpolated boundary value.
  final bool isInterpolated;

  /// The delta from the previous reading (null for first reading or interpolated items).
  final double? delta;

  /// The ID of the real reading (null for interpolated items).
  final int? readingId;

  const ReadingDisplayItem({
    required this.timestamp,
    required this.value,
    required this.isInterpolated,
    this.delta,
    this.readingId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingDisplayItem &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          value == other.value &&
          isInterpolated == other.isInterpolated &&
          delta == other.delta &&
          readingId == other.readingId;

  @override
  int get hashCode => Object.hash(timestamp, value, isInterpolated, delta, readingId);

  @override
  String toString() =>
      'ReadingDisplayItem(timestamp: $timestamp, value: $value, '
      'isInterpolated: $isInterpolated, delta: $delta, readingId: $readingId)';
}
