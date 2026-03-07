import 'models.dart';

/// Pure-logic interpolation engine for estimating meter values
/// at arbitrary points in time between actual readings.
class InterpolationService {
  /// Single-point interpolation between two readings.
  ///
  /// Linear: fraction = (target - tA) / (tB - tA); result = vA + fraction * (vB - vA)
  /// Step: returns valueA (previous reading holds until next)
  double interpolateAt({
    required DateTime timeA,
    required double valueA,
    required DateTime timeB,
    required double valueB,
    required DateTime targetTime,
    InterpolationMethod method = InterpolationMethod.linear,
  }) {
    if (method == InterpolationMethod.step) {
      return valueA;
    }

    final totalDuration = timeB.difference(timeA).inMilliseconds;
    if (totalDuration == 0) return valueA;

    final targetDuration = targetTime.difference(timeA).inMilliseconds;
    final fraction = targetDuration / totalDuration;
    return valueA + fraction * (valueB - valueA);
  }

  /// Generate boundary values at the 1st of each month in range.
  ///
  /// Readings must be sorted ascending by timestamp (defensive sort applied).
  /// No extrapolation: boundaries outside reading range are skipped.
  List<TimestampedValue> getMonthlyBoundaries({
    required List<ReadingPoint> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  }) {
    if (readings.isEmpty) return [];

    // Defensive sort + deduplicate (keep last for duplicate timestamps)
    final sorted = _sortAndDeduplicate(readings);
    if (sorted.isEmpty) return [];

    // Generate target dates: 1st of each month in range
    final targets = _generateMonthlyTargets(rangeStart, rangeEnd);

    final results = <TimestampedValue>[];

    for (final target in targets) {
      // Find surrounding readings
      ReadingPoint? before;
      ReadingPoint? after;
      ReadingPoint? exact;

      for (final reading in sorted) {
        if (reading.timestamp == target) {
          exact = reading;
          break;
        } else if (reading.timestamp.isBefore(target)) {
          before = reading;
        } else {
          after = reading;
          break;
        }
      }

      if (exact != null) {
        results.add(TimestampedValue(
          timestamp: target,
          value: exact.value,
          isInterpolated: false,
        ));
      } else if (before != null && after != null) {
        final value = interpolateAt(
          timeA: before.timestamp,
          valueA: before.value,
          timeB: after.timestamp,
          valueB: after.value,
          targetTime: target,
          method: method,
        );
        results.add(TimestampedValue(
          timestamp: target,
          value: value,
          isInterpolated: true,
        ));
      }
      // else: skip (no extrapolation)
    }

    return results;
  }

  /// Calculate consumption per month from boundary values.
  List<PeriodConsumption> getMonthlyConsumption({
    required List<ReadingPoint> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  }) {
    final boundaries = getMonthlyBoundaries(
      readings: readings,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      method: method,
    );

    if (boundaries.length < 2) return [];

    final results = <PeriodConsumption>[];
    for (var i = 0; i < boundaries.length - 1; i++) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      results.add(PeriodConsumption(
        periodStart: start.timestamp,
        periodEnd: end.timestamp,
        startValue: start.value,
        endValue: end.value,
        consumption: end.value - start.value,
        startInterpolated: start.isInterpolated,
        endInterpolated: end.isInterpolated,
      ));
    }

    return results;
  }

  /// Sort readings by timestamp, keeping last value for duplicate timestamps.
  List<ReadingPoint> _sortAndDeduplicate(List<ReadingPoint> readings) {
    final sorted = List<ReadingPoint>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.length <= 1) return sorted;

    final deduped = <ReadingPoint>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i < sorted.length - 1 &&
          sorted[i].timestamp == sorted[i + 1].timestamp) {
        continue; // Skip, keep the later one
      }
      deduped.add(sorted[i]);
    }

    return deduped;
  }

  /// Generate target dates: 1st of each month between rangeStart and rangeEnd.
  List<DateTime> _generateMonthlyTargets(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final targets = <DateTime>[];
    var year = rangeStart.year;
    var month = rangeStart.month;

    while (true) {
      final target = DateTime(year, month, 1);
      if (target.isAfter(rangeEnd)) break;
      if (!target.isBefore(rangeStart)) {
        targets.add(target);
      }
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    return targets;
  }
}
