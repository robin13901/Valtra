import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/heating_dao.dart';
import '../database/tables.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/models.dart';

/// Represents a reading with its calculated delta from the previous reading.
class HeatingReadingWithDelta {
  final HeatingReading reading;
  final double? delta;

  const HeatingReadingWithDelta({required this.reading, this.delta});
}

/// Heating meter with its associated room name for display.
class HeatingMeterWithRoom {
  final HeatingMeter meter;
  final String roomName;

  HeatingMeterWithRoom({required this.meter, required this.roomName});
}

/// Manages heating meter and reading state including CRUD operations and delta calculations.
class HeatingProvider extends ChangeNotifier {
  final HeatingDao _dao;
  final InterpolationService _interpolationService;

  List<HeatingMeterWithRoom> _metersWithRooms = [];
  final Map<int, List<HeatingReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<HeatingReading>>>
      _readingSubscriptions = {};
  int? _householdId;
  int? _selectedMeterId;
  StreamSubscription<List<HeatingMeter>>? _metersSubscription;
  bool _showInterpolatedValues = false;

  HeatingProvider(this._dao, {InterpolationService? interpolationService})
      : _interpolationService =
            interpolationService ?? InterpolationService();

  /// Whether interpolated values are currently shown in the reading list.
  bool get showInterpolatedValues => _showInterpolatedValues;

  /// Toggle showing/hiding interpolated boundary values in the reading list.
  void toggleInterpolatedValues() {
    _showInterpolatedValues = !_showInterpolatedValues;
    notifyListeners();
  }

  /// List of all heating meters for the current household (raw HeatingMeter objects).
  List<HeatingMeter> get meters =>
      List.unmodifiable(_metersWithRooms.map((m) => m.meter));

  /// List of all heating meters with room names for the current household.
  List<HeatingMeterWithRoom> get metersWithRooms =>
      List.unmodifiable(_metersWithRooms);

  /// Heating meters grouped by room name.
  Map<String, List<HeatingMeterWithRoom>> get metersByRoom {
    final result = <String, List<HeatingMeterWithRoom>>{};
    for (final mwr in _metersWithRooms) {
      result.putIfAbsent(mwr.roomName, () => []).add(mwr);
    }
    return result;
  }

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
      _metersWithRooms = [];
      notifyListeners();
      return;
    }

    _metersSubscription = _dao.watchMetersForHousehold(householdId).listen(
      (meters) async {
        final metersWithRooms = <HeatingMeterWithRoom>[];
        for (final meter in meters) {
          final room = await _dao.getRoomForMeter(meter.id);
          metersWithRooms.add(
              HeatingMeterWithRoom(meter: meter, roomName: room.name));
        }
        _metersWithRooms = metersWithRooms;
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

  /// Adds a new heating meter assigned to a room.
  Future<int> addMeter(
    String name,
    int roomId, {
    HeatingType heatingType = HeatingType.ownMeter,
    double? heatingRatio,
  }) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertMeter(HeatingMetersCompanion.insert(
      householdId: _householdId!,
      roomId: roomId,
      name: name,
      heatingType: Value(heatingType),
      heatingRatio: Value(heatingRatio),
    ));
  }

  /// Updates an existing heating meter.
  Future<bool> updateMeter(
    int id,
    String name,
    int roomId, {
    HeatingType? heatingType,
    double? heatingRatio,
  }) {
    final companion = HeatingMetersCompanion(
      id: Value(id),
      name: Value(name),
      roomId: Value(roomId),
      heatingType:
          heatingType != null ? Value(heatingType) : const Value.absent(),
      heatingRatio: Value(heatingRatio),
    );
    return _dao.updateMeter(companion);
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

  /// Gets display items for a meter that may include interpolated values.
  List<ReadingDisplayItem> getDisplayItems(int meterId) {
    final readings = _readingsByMeter[meterId] ?? [];
    if (readings.isEmpty) return [];

    final realItems = <ReadingDisplayItem>[];
    for (var i = 0; i < readings.length; i++) {
      final current = readings[i];
      final previous = i + 1 < readings.length ? readings[i + 1] : null;
      final delta =
          previous != null ? current.value - previous.value : null;

      realItems.add(ReadingDisplayItem(
        timestamp: current.timestamp,
        value: current.value,
        isInterpolated: false,
        delta: delta,
        readingId: current.id,
      ));
    }

    if (!_showInterpolatedValues || readings.length < 2) {
      return realItems;
    }

    final readingPoints = readings
        .map((r) => (timestamp: r.timestamp, value: r.value))
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
    return merged;
  }

  /// Validates a reading value against surrounding readings.
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
