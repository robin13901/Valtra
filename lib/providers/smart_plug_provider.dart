import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../database/daos/smart_plug_dao.dart';

/// Smart plug with its associated room name for display.
class SmartPlugWithRoom {
  final SmartPlug plug;
  final String roomName;

  SmartPlugWithRoom({required this.plug, required this.roomName});
}

/// Consumption entry with localized month/year label for display.
class ConsumptionWithLabel {
  final SmartPlugConsumption consumption;
  final String intervalLabel;

  ConsumptionWithLabel({required this.consumption, required this.intervalLabel});

  /// Generates a localized month/year label from the month DateTime.
  static String generateLabel(DateTime month, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    return formatter.format(month);
  }
}

/// Manages smart plug and consumption state.
class SmartPlugProvider extends ChangeNotifier {
  final SmartPlugDao _dao;

  List<SmartPlugWithRoom> _plugs = [];
  int? _householdId;
  StreamSubscription<List<SmartPlug>>? _plugsSubscription;

  SmartPlugProvider(this._dao);

  /// List of all smart plugs for the current household with room names.
  List<SmartPlugWithRoom> get plugs => List.unmodifiable(_plugs);

  /// Smart plugs grouped by room name.
  Map<String, List<SmartPlugWithRoom>> get plugsByRoom {
    final result = <String, List<SmartPlugWithRoom>>{};
    for (final plug in _plugs) {
      result.putIfAbsent(plug.roomName, () => []).add(plug);
    }
    return result;
  }

  /// The currently selected household ID.
  int? get householdId => _householdId;

  /// Sets the household ID and refreshes smart plugs.
  void setHouseholdId(int? householdId) {
    if (_householdId == householdId) return;

    _householdId = householdId;
    _plugsSubscription?.cancel();

    if (householdId == null) {
      _plugs = [];
      notifyListeners();
      return;
    }

    _plugsSubscription =
        _dao.watchSmartPlugsForHousehold(householdId).listen((plugs) async {
      // Fetch room names for each plug
      final plugsWithRooms = <SmartPlugWithRoom>[];
      for (final plug in plugs) {
        final room = await _dao.getRoomForSmartPlug(plug.id);
        plugsWithRooms
            .add(SmartPlugWithRoom(plug: plug, roomName: room.name));
      }
      _plugs = plugsWithRooms;
      notifyListeners();
    });
  }

  // ============== Smart Plug Methods ==============

  /// Adds a new smart plug.
  Future<int> addSmartPlug(String name, int roomId) async {
    return _dao.insertSmartPlug(SmartPlugsCompanion.insert(
      roomId: roomId,
      name: name,
    ));
  }

  /// Updates an existing smart plug.
  Future<bool> updateSmartPlug(int id, String name, int roomId) {
    return _dao.updateSmartPlug(SmartPlugsCompanion(
      id: Value(id),
      name: Value(name),
      roomId: Value(roomId),
    ));
  }

  /// Deletes a smart plug by ID.
  Future<void> deleteSmartPlug(int id) {
    return _dao.deleteSmartPlug(id);
  }

  /// Gets a smart plug by ID.
  Future<SmartPlug> getSmartPlug(int id) {
    return _dao.getSmartPlug(id);
  }

  /// Gets the room for a smart plug.
  Future<Room> getRoomForSmartPlug(int smartPlugId) {
    return _dao.getRoomForSmartPlug(smartPlugId);
  }

  // ============== Consumption Methods ==============

  /// Gets all consumption entries for a smart plug with localized month labels.
  Future<List<ConsumptionWithLabel>> getConsumptionsForPlug(
    int plugId,
    String locale,
  ) async {
    final consumptions = await _dao.getConsumptionsForPlug(plugId);
    return consumptions
        .map((c) => ConsumptionWithLabel(
              consumption: c,
              intervalLabel: ConsumptionWithLabel.generateLabel(
                c.month,
                locale,
              ),
            ))
        .toList();
  }

  /// Watches consumption entries for a smart plug with localized month labels.
  Stream<List<ConsumptionWithLabel>> watchConsumptionsForPlug(
    int plugId,
    String locale,
  ) {
    return _dao.watchConsumptionsForPlug(plugId).map((consumptions) {
      return consumptions
          .map((c) => ConsumptionWithLabel(
                consumption: c,
                intervalLabel: ConsumptionWithLabel.generateLabel(
                  c.month,
                  locale,
                ),
              ))
          .toList();
    });
  }

  /// Adds a new consumption entry for a given month.
  /// The [month] should be the 1st of the month at 00:00.
  /// Returns the new entry's ID, or -1 if a duplicate month exists.
  Future<int> addConsumption(
    int plugId,
    DateTime month,
    double kWh,
  ) async {
    // Check for duplicate month
    final existing = await _dao.getConsumptionForMonth(plugId, month);
    if (existing != null) {
      return -1;
    }
    return _dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
      smartPlugId: plugId,
      month: month,
      valueKwh: kWh,
    ));
  }

  /// Updates an existing consumption entry.
  Future<bool> updateConsumption(
    int id,
    DateTime month,
    double kWh,
  ) {
    return _dao.updateConsumption(SmartPlugConsumptionsCompanion(
      id: Value(id),
      month: Value(month),
      valueKwh: Value(kWh),
    ));
  }

  /// Deletes a consumption entry by ID.
  Future<void> deleteConsumption(int id) {
    return _dao.deleteConsumption(id);
  }

  /// Gets the latest consumption entry for a smart plug.
  Future<SmartPlugConsumption?> getLatestConsumptionForPlug(int plugId) {
    return _dao.getLatestConsumptionForPlug(plugId);
  }

  @override
  void dispose() {
    _plugsSubscription?.cancel();
    super.dispose();
  }
}
