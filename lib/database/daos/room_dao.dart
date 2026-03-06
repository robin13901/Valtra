import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'room_dao.g.dart';

@DriftAccessor(tables: [Rooms, SmartPlugs, SmartPlugConsumptions])
class RoomDao extends DatabaseAccessor<AppDatabase> with _$RoomDaoMixin {
  RoomDao(super.db);

  /// Inserts a new room and returns its ID.
  Future<int> insertRoom(RoomsCompanion entry) {
    return into(rooms).insert(entry);
  }

  /// Retrieves a room by its ID.
  Future<Room> getRoom(int id) {
    return (select(rooms)..where((r) => r.id.equals(id))).getSingle();
  }

  /// Retrieves all rooms for a household, ordered alphabetically by name.
  Future<List<Room>> getRoomsForHousehold(int householdId) {
    return (select(rooms)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.asc(r.name)]))
        .get();
  }

  /// Watches all rooms for a household for reactive updates.
  Stream<List<Room>> watchRoomsForHousehold(int householdId) {
    return (select(rooms)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.asc(r.name)]))
        .watch();
  }

  /// Updates an existing room. Returns true if a row was updated.
  Future<bool> updateRoom(RoomsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Room ID is required for update');
    }
    final rows = await (update(rooms)..where((r) => r.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a room by ID, cascading to delete all smart plugs and their consumption records.
  Future<void> deleteRoom(int id) async {
    await transaction(() async {
      // Get all smart plugs in this room
      final plugsInRoom = await (select(smartPlugs)
            ..where((p) => p.roomId.equals(id)))
          .get();

      // Delete consumption records for each plug
      for (final plug in plugsInRoom) {
        await (delete(smartPlugConsumptions)
              ..where((c) => c.smartPlugId.equals(plug.id)))
            .go();
      }

      // Delete all smart plugs in this room
      await (delete(smartPlugs)..where((p) => p.roomId.equals(id))).go();

      // Delete the room
      await (delete(rooms)..where((r) => r.id.equals(id))).go();
    });
  }

  /// Checks if a room has smart plugs.
  Future<bool> roomHasSmartPlugs(int roomId) async {
    final plugs = await (select(smartPlugs)
          ..where((p) => p.roomId.equals(roomId)))
        .get();
    return plugs.isNotEmpty;
  }

  /// Gets the count of smart plugs in a room.
  Future<int> getSmartPlugCount(int roomId) async {
    final plugs = await (select(smartPlugs)
          ..where((p) => p.roomId.equals(roomId)))
        .get();
    return plugs.length;
  }
}
