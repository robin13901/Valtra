import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/gas_dao.dart';

/// Represents a reading with its calculated delta from the previous reading.
class GasReadingWithDelta {
  final GasReading reading;
  final double? deltaCubicMeters;

  const GasReadingWithDelta({required this.reading, this.deltaCubicMeters});
}

/// Manages gas reading state including CRUD operations and delta calculations.
class GasProvider extends ChangeNotifier {
  final GasDao _dao;

  List<GasReading> _readings = [];
  int? _householdId;
  StreamSubscription<List<GasReading>>? _readingsSubscription;

  GasProvider(this._dao);

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
      if (value < previous.valueCubicMeters) {
        return previous.valueCubicMeters;
      }
    }

    // Also check if there's a next reading that would become invalid
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
