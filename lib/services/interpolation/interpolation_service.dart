import 'models.dart';

/// Result of year-end extrapolation.
class ExtrapolationResult {
  /// Projected total consumption for the full year.
  final double projectedTotal;

  /// Extrapolated monthly periods (one per remaining month).
  /// Each is marked with [PeriodConsumption.isExtrapolated] = true.
  final List<PeriodConsumption> projectedMonths;

  /// Number of actual data months used as basis.
  final int actualMonthCount;

  const ExtrapolationResult({
    required this.projectedTotal,
    required this.projectedMonths,
    required this.actualMonthCount,
  });
}

/// Pure-logic interpolation engine for estimating meter values
/// at arbitrary points in time between actual readings.
class InterpolationService {
  /// Single-point linear interpolation between two readings.
  ///
  /// fraction = (target - tA) / (tB - tA); result = vA + fraction * (vB - vA)
  double interpolateAt({
    required DateTime timeA,
    required double valueA,
    required DateTime timeB,
    required double valueB,
    required DateTime targetTime,
  }) {
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
  }) {
    final boundaries = getMonthlyBoundaries(
      readings: readings,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
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

  /// Extrapolate year-end consumption from partial-year data.
  ///
  /// Takes the actual monthly consumptions so far and projects
  /// the remaining months at the same average rate.
  /// Returns null if no actual consumption data is provided.
  ExtrapolationResult? extrapolateYearEnd({
    required List<PeriodConsumption> actualMonths,
    required int year,
  }) {
    if (actualMonths.isEmpty) return null;

    final actualTotal =
        actualMonths.fold<double>(0, (sum, p) => sum + p.consumption);
    final avgMonthly = actualTotal / actualMonths.length;

    // Determine which months are already covered
    final coveredMonths =
        actualMonths.map((p) => p.periodStart.month).toSet();

    // Generate extrapolated periods for remaining months
    final projectedMonths = <PeriodConsumption>[];
    for (int m = 1; m <= 12; m++) {
      if (!coveredMonths.contains(m)) {
        projectedMonths.add(PeriodConsumption(
          periodStart: DateTime(year, m, 1),
          periodEnd: DateTime(year, m + 1, 1),
          startValue: 0,
          endValue: 0,
          consumption: avgMonthly,
          startInterpolated: false,
          endInterpolated: false,
          isExtrapolated: true,
        ));
      }
    }

    final projectedTotal = actualTotal + projectedMonths.length * avgMonthly;

    return ExtrapolationResult(
      projectedTotal: projectedTotal,
      projectedMonths: projectedMonths,
      actualMonthCount: actualMonths.length,
    );
  }
}
