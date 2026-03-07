import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/water_dao.dart';
import '../database/tables.dart';

/// Represents a reading with its calculated delta from the previous reading.
class WaterReadingWithDelta {
  final WaterReading reading;
  final double? deltaCubicMeters;

  const WaterReadingWithDelta({required this.reading, this.deltaCubicMeters});
}

/// Manages water meter and reading state including CRUD operations and delta calculations.
class WaterProvider extends ChangeNotifier {
  final WaterDao _dao;

  List<WaterMeter> _meters = [];
  final Map<int, List<WaterReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<WaterReading>>> _readingSubscriptions =
      {};
  int? _householdId;
  int? _selectedMeterId;
  StreamSubscription<List<WaterMeter>>? _metersSubscription;

  WaterProvider(this._dao);

  /// List of all water meters for the current household.
  List<WaterMeter> get meters => List.unmodifiable(_meters);

  /// The currently selected household ID.
  int? get householdId => _householdId;

  /// The currently selected meter ID.
  int? get selectedMeterId => _selectedMeterId;

  /// Sets the household ID and refreshes meters.
  void setHouseholdId(int? householdId) {
    if (_householdId == householdId) return;

    _householdId = householdId;
    _selectedMeterId = null;
    _metersSubscription?.cancel();
    _cancelAllReadingSubscriptions();
    _readingsByMeter.clear();

    if (householdId == null) {
      _meters = [];
      notifyListeners();
      return;
    }

    _metersSubscription = _dao.watchMetersForHousehold(householdId).listen(
      (meters) {
        _meters = meters;
        // Subscribe to readings for each meter
        for (final meter in meters) {
          _subscribeToReadings(meter.id);
        }
        notifyListeners();
      },
    );
  }

  /// Sets the selected meter ID.
  void setSelectedMeterId(int? meterId) {
    if (_selectedMeterId == meterId) return;
    _selectedMeterId = meterId;
    notifyListeners();
  }

  void _subscribeToReadings(int meterId) {
    if (_readingSubscriptions.containsKey(meterId)) return;

    _readingSubscriptions[meterId] =
        _dao.watchReadingsForMeter(meterId).listen((readings) {
      _readingsByMeter[meterId] = readings;
      notifyListeners();
    });
  }

  void _cancelAllReadingSubscriptions() {
    for (final subscription in _readingSubscriptions.values) {
      subscription.cancel();
    }
    _readingSubscriptions.clear();
  }

  // ============== Meter Operations ==============

  /// Adds a new water meter.
  Future<int> addMeter(String name, WaterMeterType type) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertMeter(WaterMetersCompanion.insert(
      householdId: _householdId!,
      name: name,
      type: type,
    ));
  }

  /// Updates an existing water meter.
  Future<bool> updateMeter(int id, String name, WaterMeterType type) {
    return _dao.updateMeter(WaterMetersCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
    ));
  }

  /// Deletes a water meter and all its readings.
  Future<void> deleteMeter(int id) async {
    // Cancel reading subscription for this meter
    _readingSubscriptions[id]?.cancel();
    _readingSubscriptions.remove(id);
    _readingsByMeter.remove(id);

    if (_selectedMeterId == id) {
      _selectedMeterId = null;
    }

    await _dao.deleteMeter(id);
  }

  /// Gets the count of readings for a water meter.
  Future<int> getReadingCountForMeter(int meterId) {
    return _dao.getReadingCountForMeter(meterId);
  }

  // ============== Reading Operations ==============

  /// Adds a new reading for a water meter.
  Future<int> addReading(int meterId, DateTime timestamp, double valueCubicMeters) {
    return _dao.insertReading(WaterReadingsCompanion.insert(
      waterMeterId: meterId,
      timestamp: timestamp,
      valueCubicMeters: valueCubicMeters,
    ));
  }

  /// Updates an existing reading.
  Future<bool> updateReading(
      int id, DateTime timestamp, double valueCubicMeters) {
    return _dao.updateReading(WaterReadingsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      valueCubicMeters: Value(valueCubicMeters),
    ));
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) {
    return _dao.deleteReading(id);
  }

  /// Gets readings for a meter with calculated deltas.
  List<WaterReadingWithDelta> getReadingsWithDeltas(int meterId) {
    final readings = _readingsByMeter[meterId] ?? [];
    if (readings.isEmpty) return [];

    final result = <WaterReadingWithDelta>[];

    // Readings are sorted newest first, so iterate in order
    for (var i = 0; i < readings.length; i++) {
      final current = readings[i];

      // Previous reading is the next one in the list (older)
      final previous = i + 1 < readings.length ? readings[i + 1] : null;

      final delta = previous != null
          ? current.valueCubicMeters - previous.valueCubicMeters
          : null;

      result.add(WaterReadingWithDelta(reading: current, deltaCubicMeters: delta));
    }

    return result;
  }

  /// Gets the latest reading for a water meter.
  Future<WaterReading?> getLatestReading(int meterId) {
    return _dao.getLatestReading(meterId);
  }

  /// Validates a reading value against surrounding readings.
  ///
  /// Returns the boundary value as a raw double if invalid, null if valid.
  /// When editing (excludeId provided), finds the previous reading relative to that reading.
  Future<double?> validateReading(
    int meterId,
    double value,
    DateTime timestamp, {
    int? excludeId,
  }) async {
    // Get the reading immediately before this timestamp
    final previous = await _dao.getPreviousReading(meterId, timestamp);

    // If there's a previous reading and it's not the one we're editing
    if (previous != null && previous.id != excludeId) {
      if (value < previous.valueCubicMeters) {
        return previous.valueCubicMeters;
      }
    }

    // Also check if there's a next reading that would become invalid
    if (excludeId != null) {
      final next = await _dao.getNextReading(meterId, timestamp);
      if (next != null && next.id != excludeId && next.valueCubicMeters < value) {
        return next.valueCubicMeters;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _metersSubscription?.cancel();
    _cancelAllReadingSubscriptions();
    super.dispose();
  }
}
