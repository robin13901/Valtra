import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/electricity_dao.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/models.dart';

/// Represents a reading with its calculated delta from the previous reading.
class ReadingWithDelta {
  final ElectricityReading reading;
  final double? deltaKwh;

  const ReadingWithDelta({required this.reading, this.deltaKwh});
}

/// Manages electricity reading state including CRUD operations and delta calculations.
class ElectricityProvider extends ChangeNotifier {
  final ElectricityDao _dao;
  final InterpolationService _interpolationService;

  List<ElectricityReading> _readings = [];
  int? _householdId;
  StreamSubscription<List<ElectricityReading>>? _readingsSubscription;
  bool _showInterpolatedValues = false;

  ElectricityProvider(this._dao, {InterpolationService? interpolationService})
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
  List<ElectricityReading> get readings => List.unmodifiable(_readings);

  /// List of readings with calculated deltas.
  List<ReadingWithDelta> get readingsWithDeltas {
    if (_readings.isEmpty) return [];

    final result = <ReadingWithDelta>[];

    // Readings are sorted newest first, so iterate in order
    for (var i = 0; i < _readings.length; i++) {
      final current = _readings[i];

      // Previous reading is the next one in the list (older)
      final previous = i + 1 < _readings.length ? _readings[i + 1] : null;

      final delta = previous != null
          ? current.valueKwh - previous.valueKwh
          : null;

      result.add(ReadingWithDelta(reading: current, deltaKwh: delta));
    }

    return result;
  }

  /// List of display items that may include interpolated boundary values.
  ///
  /// When [showInterpolatedValues] is true, interpolated 1st-of-month
  /// boundary values are merged into the list alongside real readings.
  /// When false, only real readings are returned.
  List<ReadingDisplayItem> get displayItems {
    if (_readings.isEmpty) return [];

    // Build real reading items (newest first)
    final realItems = <ReadingDisplayItem>[];
    for (var i = 0; i < _readings.length; i++) {
      final current = _readings[i];
      final previous = i + 1 < _readings.length ? _readings[i + 1] : null;
      final delta =
          previous != null ? current.valueKwh - previous.valueKwh : null;

      realItems.add(ReadingDisplayItem(
        timestamp: current.timestamp,
        value: current.valueKwh,
        isInterpolated: false,
        delta: delta,
        readingId: current.id,
      ));
    }

    if (!_showInterpolatedValues || _readings.length < 2) {
      return realItems;
    }

    // Compute interpolated boundaries
    final readingPoints = _readings
        .map((r) => (timestamp: r.timestamp, value: r.valueKwh))
        .toList();
    // Sort ascending for interpolation service
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

    // Filter to only interpolated boundaries (non-exact matches)
    final interpolatedItems = boundaries
        .where((b) => b.isInterpolated)
        .map((b) => ReadingDisplayItem(
              timestamp: b.timestamp,
              value: b.value,
              isInterpolated: true,
            ))
        .toList();

    // Merge and sort newest first
    final merged = [...realItems, ...interpolatedItems];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Compute deltas for interpolated items (difference to next item in list)
    for (int i = 0; i < merged.length; i++) {
      if (merged[i].isInterpolated && i + 1 < merged.length) {
        final diff = merged[i].value - merged[i + 1].value;
        merged[i] = ReadingDisplayItem(
          timestamp: merged[i].timestamp,
          value: merged[i].value,
          isInterpolated: true,
          delta: diff > 0 ? diff : null,
        );
      }
    }

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
  Future<int> addReading(DateTime timestamp, double valueKwh) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertReading(ElectricityReadingsCompanion.insert(
      householdId: _householdId!,
      timestamp: timestamp,
      valueKwh: valueKwh,
    ));
  }

  /// Updates an existing reading.
  Future<bool> updateReading(int id, DateTime timestamp, double valueKwh) {
    return _dao.updateReading(ElectricityReadingsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      valueKwh: Value(valueKwh),
    ));
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) {
    return _dao.deleteReading(id);
  }

  /// Validates a reading value against the previous reading.
  ///
  /// Returns the boundary value as a raw double if invalid, null if valid.
  /// When editing (excludeId provided), finds the previous reading relative to that reading.
  Future<double?> validateReading(
    double value,
    DateTime timestamp, {
    int? excludeId,
  }) async {
    if (_householdId == null) return null;

    // Get the reading immediately before this timestamp
    final previous = await _dao.getPreviousReading(_householdId!, timestamp);

    // If there's a previous reading and it's not the one we're editing
    if (previous != null && previous.id != excludeId) {
      if (value < previous.valueKwh) {
        return previous.valueKwh;
      }
    }

    // Also check if there's a next reading that would become invalid
    if (excludeId != null) {
      final next = await _dao.getNextReading(_householdId!, timestamp);
      if (next != null && next.id != excludeId && next.valueKwh < value) {
        // The new value would be greater than the next reading
        return next.valueKwh;
      }
    }

    return null;
  }

  /// Gets the latest reading for validation purposes.
  Future<ElectricityReading?> getLatestReading() {
    if (_householdId == null) return Future.value(null);
    return _dao.getLatestReading(_householdId!);
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    super.dispose();
  }
}
