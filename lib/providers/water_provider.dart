import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/water_dao.dart';
import '../database/tables.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/models.dart';

/// Represents a reading with its calculated delta from the previous reading.
class WaterReadingWithDelta {
  final WaterReading reading;
  final double? deltaCubicMeters;

  const WaterReadingWithDelta({required this.reading, this.deltaCubicMeters});
}

/// Manages water meter and reading state including CRUD operations and delta calculations.
class WaterProvider extends ChangeNotifier {
  final WaterDao _dao;
  final InterpolationService _interpolationService;

  List<WaterMeter> _meters = [];
  final Map<int, List<WaterReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<WaterReading>>> _readingSubscriptions =
      {};
  int? _householdId;
  int? _selectedMeterId;
  StreamSubscription<List<WaterMeter>>? _metersSubscription;
  bool _showInterpolatedValues = false;

  WaterProvider(this._dao, {InterpolationService? interpolationService})
      : _interpolationService =
            interpolationService ?? InterpolationService();

  /// Whether interpolated values are currently shown in the reading list.
  bool get showInterpolatedValues => _showInterpolatedValues;

  /// Toggle showing/hiding interpolated boundary values in the reading list.
  void toggleInterpolatedValues() {
    _showInterpolatedValues = !_showInterpolatedValues;
    notifyListeners();
  }

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

  /// Gets display items for a meter that may include interpolated values.
  List<ReadingDisplayItem> getDisplayItems(int meterId) {
    final readings = _readingsByMeter[meterId] ?? [];
    if (readings.isEmpty) return [];

    final realItems = <ReadingDisplayItem>[];
    for (var i = 0; i < readings.length; i++) {
      final current = readings[i];
      final previous = i + 1 < readings.length ? readings[i + 1] : null;
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

    if (!_showInterpolatedValues || readings.length < 2) {
      return realItems;
    }

    final readingPoints = readings
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

    final interpolatedItems = boundaries
        .where((b) => b.isInterpolated)
        .map((b) => ReadingDisplayItem(
              timestamp: b.timestamp,
              value: b.value,
              isInterpolated: true,
            ))
        .toList();

    final merged = [...realItems, ...interpolatedItems];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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

  /// Gets the latest reading for a water meter.
  Future<WaterReading?> getLatestReading(int meterId) {
    return _dao.getLatestReading(meterId);
  }

  /// Validates a reading value against surrounding readings.
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
