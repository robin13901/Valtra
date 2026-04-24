import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/gas_dao.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/models.dart';

/// Represents a reading with its calculated delta from the previous reading.
class GasReadingWithDelta {
  final GasReading reading;
  final double? deltaCubicMeters;

  const GasReadingWithDelta({required this.reading, this.deltaCubicMeters});
}

/// Manages gas reading state including CRUD operations and delta calculations.
class GasProvider extends ChangeNotifier {
  final GasDao _dao;
  final InterpolationService _interpolationService;

  List<GasReading> _readings = [];
  int? _householdId;
  StreamSubscription<List<GasReading>>? _readingsSubscription;
  bool _showInterpolatedValues = false;

  GasProvider(this._dao, {InterpolationService? interpolationService})
      : _interpolationService =
            interpolationService ?? InterpolationService();

  /// Whether interpolated values are currently shown in the reading list.
  bool get showInterpolatedValues => _showInterpolatedValues;

  /// Toggle showing/hiding interpolated boundary values in the reading list.
  void toggleInterpolatedValues() {
    _showInterpolatedValues = !_showInterpolatedValues;
    notifyListeners();
  }

  /// List of all readings for the current household (newest first).
  List<GasReading> get readings => List.unmodifiable(_readings);

  /// List of readings with calculated deltas.
  List<GasReadingWithDelta> get readingsWithDeltas {
    if (_readings.isEmpty) return [];

    final result = <GasReadingWithDelta>[];

    // Readings are sorted newest first, so iterate in order
    for (var i = 0; i < _readings.length; i++) {
      final current = _readings[i];

      // Previous reading is the next one in the list (older)
      final previous = i + 1 < _readings.length ? _readings[i + 1] : null;

      final delta = previous != null
          ? current.valueCubicMeters - previous.valueCubicMeters
          : null;

      result.add(GasReadingWithDelta(reading: current, deltaCubicMeters: delta));
    }

    return result;
  }

  /// List of display items that may include interpolated boundary values.
  List<ReadingDisplayItem> get displayItems {
    if (_readings.isEmpty) return [];

    final realItems = <ReadingDisplayItem>[];
    for (var i = 0; i < _readings.length; i++) {
      final current = _readings[i];
      final previous = i + 1 < _readings.length ? _readings[i + 1] : null;
      final delta = previous != null
          ? current.valueCubicMeters - previous.valueCubicMeters
          : null;

      realItems.add(ReadingDisplayItem(
        timestamp: current.timestamp,
        value: current.valueCubicMeters,
        isInterpolated: false,
        delta: delta,
        readingId: current.id,
      ));
    }

    if (!_showInterpolatedValues || _readings.length < 2) {
      return realItems;
    }

    final readingPoints = _readings
        .map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters))
        .toList();
    readingPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final oldest = readingPoints.first.timestamp;
    final newest = readingPoints.last.timestamp;
    final rangeStart = DateTime(oldest.year, oldest.month, 1);
    final rangeEnd = DateTime(newest.year, newest.month + 1, 1);

    final boundaries = _interpolationService.getMonthlyBoundaries(
      readings: readingPoints,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final boundaryByMonth = <DateTime, double>{};
    for (final b in boundaries) {
      boundaryByMonth[b.timestamp] = b.value;
    }

    final interpolatedItems = boundaries
        .where((b) => b.isInterpolated)
        .map((b) {
          final prevMonth = DateTime(b.timestamp.year, b.timestamp.month - 1, 1);
          final prevValue = boundaryByMonth[prevMonth];
          final delta = prevValue != null ? b.value - prevValue : null;
          return ReadingDisplayItem(
            timestamp: b.timestamp,
            value: b.value,
            isInterpolated: true,
            delta: delta != null && delta > 0 ? delta : null,
          );
        })
        .toList();

    final merged = [...realItems, ...interpolatedItems];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return merged;
  }

  /// The currently selected household ID.
  int? get householdId => _householdId;

  /// Sets the household ID and refreshes readings.
  void setHouseholdId(int? householdId) {
    if (_householdId == householdId) return;

    _householdId = householdId;
    _readingsSubscription?.cancel();

    if (householdId == null) {
      _readings = [];
      notifyListeners();
      return;
    }

    _readingsSubscription = _dao.watchReadingsForHousehold(householdId).listen(
      (readings) {
        _readings = readings;
        notifyListeners();
      },
    );
  }

  /// Adds a new reading for the current household.
  Future<int> addReading(DateTime timestamp, double valueCubicMeters) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertReading(GasReadingsCompanion.insert(
      householdId: _householdId!,
      timestamp: timestamp,
      valueCubicMeters: valueCubicMeters,
    ));
  }

  /// Updates an existing reading.
  Future<bool> updateReading(
      int id, DateTime timestamp, double valueCubicMeters) {
    return _dao.updateReading(GasReadingsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      valueCubicMeters: Value(valueCubicMeters),
    ));
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) {
    return _dao.deleteReading(id);
  }

  /// Validates a reading value against the previous reading.
  Future<double?> validateReading(
    double value,
    DateTime timestamp, {
    int? excludeId,
  }) async {
    if (_householdId == null) return null;

    final previous = await _dao.getPreviousReading(_householdId!, timestamp);

    if (previous != null && previous.id != excludeId) {
      if (value < previous.valueCubicMeters) {
        return previous.valueCubicMeters;
      }
    }

    if (excludeId != null) {
      final next = await _dao.getNextReading(_householdId!, timestamp);
      if (next != null &&
          next.id != excludeId &&
          next.valueCubicMeters < value) {
        return next.valueCubicMeters;
      }
    }

    return null;
  }

  /// Gets the latest reading for validation purposes.
  Future<GasReading?> getLatestReading() {
    if (_householdId == null) return Future.value(null);
    return _dao.getLatestReading(_householdId!);
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    super.dispose();
  }
}
