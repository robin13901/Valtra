import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/room_dao.dart';

/// Room with smart plug count for display.
class RoomWithPlugCount {
  final Room room;
  final int plugCount;

  RoomWithPlugCount({required this.room, required this.plugCount});
}

/// Manages room state including the list of rooms for the current household.
class RoomProvider extends ChangeNotifier {
  final RoomDao _dao;

  List<Room> _rooms = [];
  int? _householdId;
  StreamSubscription<List<Room>>? _roomsSubscription;

  RoomProvider(this._dao);

  /// List of all rooms for the current household.
  List<Room> get rooms => List.unmodifiable(_rooms);

  /// The currently selected household ID.
  int? get householdId => _householdId;

  /// Sets the household ID and refreshes rooms.
  void setHouseholdId(int? householdId) {
    if (_householdId == householdId) return;

    _householdId = householdId;
    _roomsSubscription?.cancel();

    if (householdId == null) {
      _rooms = [];
      notifyListeners();
      return;
    }

    _roomsSubscription = _dao.watchRoomsForHousehold(householdId).listen(
      (rooms) {
        _rooms = rooms;
        notifyListeners();
      },
    );
  }

  /// Gets rooms with their smart plug counts.
  Future<List<RoomWithPlugCount>> getRoomsWithPlugCounts() async {
    final result = <RoomWithPlugCount>[];
    for (final room in _rooms) {
      final count = await _dao.getSmartPlugCount(room.id);
      result.add(RoomWithPlugCount(room: room, plugCount: count));
    }
    return result;
  }

  /// Adds a new room for the current household.
  Future<int> addRoom(String name) async {
    if (_householdId == null) {
      throw StateError('No household selected');
    }

    return _dao.insertRoom(RoomsCompanion.insert(
      householdId: _householdId!,
      name: name,
    ));
  }

  /// Updates an existing room.
  Future<bool> updateRoom(int id, String name) {
    return _dao.updateRoom(RoomsCompanion(
      id: Value(id),
      name: Value(name),
    ));
  }

  /// Deletes a room by ID, cascading to delete all its smart plugs.
  Future<void> deleteRoom(int id) {
    return _dao.deleteRoom(id);
  }

  /// Checks if a room can be safely deleted (has smart plugs).
  Future<bool> canDeleteRoom(int id) async {
    final hasPlugs = await _dao.roomHasSmartPlugs(id);
    return !hasPlugs;
  }

  /// Gets the count of smart plugs in a room.
  Future<int> getSmartPlugCount(int roomId) {
    return _dao.getSmartPlugCount(roomId);
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    super.dispose();
  }
}
