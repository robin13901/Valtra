import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/heating_dao.dart';

/// Represents a reading with its calculated delta from the previous reading.
class HeatingReadingWithDelta {
  final HeatingReading reading;
  final double? delta;

  const HeatingReadingWithDelta({required this.reading, this.delta});
}

/// Manages heating meter and reading state including CRUD operations and delta calculations.
class HeatingProvider extends ChangeNotifier {
  final HeatingDao _dao;

  List<HeatingMeter> _meters = [];
  final Map<int, List<HeatingReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<HeatingReading>>>
      _readingSubscriptions = {};
  int? _householdId;
  int? _selectedMeterId;
  StreamSubscription<List<HeatingMeter>>? _metersSubscription;

  HeatingProvider(this._dao);

  /// List of all heating meters for the current household.
  List<HeatingMeter> get meters => List.unmodifiable(_meters);

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

  /// Adds a new heating meter.
  Future<int> addMeter(String name, String? location) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertMeter(HeatingMetersCompanion.insert(
      householdId: _householdId!,
      name: name,
      location: Value(location),
    ));
  }

  /// Updates an existing heating meter.
  Future<bool> updateMeter(int id, String name, String? location) {
    return _dao.updateMeter(HeatingMetersCompanion(
      id: Value(id),
      name: Value(name),
      location: Value(location),
    ));
  }

  /// Deletes a heating meter and all its readings.
  Future<void> deleteMeter(int id) async {
    _readingSubscriptions[id]?.cancel();
    _readingSubscriptions.remove(id);
    _readingsByMeter.remove(id);

    if (_selectedMeterId == id) {
      _selectedMeterId = null;
    }

    await _dao.deleteMeter(id);
  }

  /// Gets the count of readings for a heating meter.
  Future<int> getReadingCountForMeter(int meterId) {
    return _dao.getReadingCountForMeter(meterId);
  }

  // ============== Reading Operations ==============

  /// Adds a new reading for a heating meter.
  Future<int> addReading(int meterId, DateTime timestamp, double value) {
    return _dao.insertReading(HeatingReadingsCompanion.insert(
      heatingMeterId: meterId,
      timestamp: timestamp,
      value: value,
    ));
  }

  /// Updates an existing reading.
  Future<bool> updateReading(int id, DateTime timestamp, double value) {
    return _dao.updateReading(HeatingReadingsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      value: Value(value),
    ));
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) {
    return _dao.deleteReading(id);
  }

  /// Gets readings for a meter with calculated deltas.
  List<HeatingReadingWithDelta> getReadingsWithDeltas(int meterId) {
    final readings = _readingsByMeter[meterId] ?? [];
    if (readings.isEmpty) return [];

    final result = <HeatingReadingWithDelta>[];

    for (var i = 0; i < readings.length; i++) {
      final current = readings[i];
      final previous = i + 1 < readings.length ? readings[i + 1] : null;

      final delta =
          previous != null ? current.value - previous.value : null;

      result
          .add(HeatingReadingWithDelta(reading: current, delta: delta));
    }

    return result;
  }

  /// Validates a reading value against surrounding readings.
  ///
  /// Returns the boundary value as a raw double if invalid, null if valid.
  Future<double?> validateReading(
    int meterId,
    double value,
    DateTime timestamp, {
    int? excludeId,
  }) async {
    final previous = await _dao.getPreviousReading(meterId, timestamp);

    if (previous != null && previous.id != excludeId) {
      if (value < previous.value) {
        return previous.value;
      }
    }

    if (excludeId != null) {
      final next = await _dao.getNextReading(meterId, timestamp);
      if (next != null && next.id != excludeId && next.value < value) {
        return next.value;
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
