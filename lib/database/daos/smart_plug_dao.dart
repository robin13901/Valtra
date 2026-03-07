import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'smart_plug_dao.g.dart';

@DriftAccessor(tables: [SmartPlugs, SmartPlugConsumptions, Rooms])
class SmartPlugDao extends DatabaseAccessor<AppDatabase>
    with _$SmartPlugDaoMixin {
  SmartPlugDao(super.db);

  // ============== Smart Plug Methods ==============

  /// Inserts a new smart plug and returns its ID.
  Future<int> insertSmartPlug(SmartPlugsCompanion entry) {
    return into(smartPlugs).insert(entry);
  }

  /// Retrieves a smart plug by its ID.
  Future<SmartPlug> getSmartPlug(int id) {
    return (select(smartPlugs)..where((p) => p.id.equals(id))).getSingle();
  }

  /// Retrieves all smart plugs for a room, ordered alphabetically by name.
  Future<List<SmartPlug>> getSmartPlugsForRoom(int roomId) {
    return (select(smartPlugs)
          ..where((p) => p.roomId.equals(roomId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Watches all smart plugs for a room for reactive updates.
  Stream<List<SmartPlug>> watchSmartPlugsForRoom(int roomId) {
    return (select(smartPlugs)
          ..where((p) => p.roomId.equals(roomId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Retrieves all smart plugs for a household (via room join).
  Future<List<SmartPlug>> getSmartPlugsForHousehold(int householdId) async {
    final query = select(smartPlugs).join([
      innerJoin(rooms, rooms.id.equalsExp(smartPlugs.roomId)),
    ]);
    query.where(rooms.householdId.equals(householdId));
    query.orderBy([OrderingTerm.asc(smartPlugs.name)]);

    final results = await query.get();
    return results.map((row) => row.readTable(smartPlugs)).toList();
  }

  /// Watches all smart plugs for a household for reactive updates.
  Stream<List<SmartPlug>> watchSmartPlugsForHousehold(int householdId) {
    final query = select(smartPlugs).join([
      innerJoin(rooms, rooms.id.equalsExp(smartPlugs.roomId)),
    ]);
    query.where(rooms.householdId.equals(householdId));
    query.orderBy([OrderingTerm.asc(smartPlugs.name)]);

    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(smartPlugs)).toList(),
        );
  }

  /// Updates an existing smart plug. Returns true if a row was updated.
  Future<bool> updateSmartPlug(SmartPlugsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Smart plug ID is required for update');
    }
    final rows = await (update(smartPlugs)
          ..where((p) => p.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a smart plug by ID, cascading to delete all its consumption records.
  Future<void> deleteSmartPlug(int id) async {
    await transaction(() async {
      // Delete all consumption records for this plug
      await (delete(smartPlugConsumptions)
            ..where((c) => c.smartPlugId.equals(id)))
          .go();

      // Delete the smart plug
      await (delete(smartPlugs)..where((p) => p.id.equals(id))).go();
    });
  }

  // ============== Consumption Methods ==============

  /// Inserts a new consumption entry and returns its ID.
  Future<int> insertConsumption(SmartPlugConsumptionsCompanion entry) {
    return into(smartPlugConsumptions).insert(entry);
  }

  /// Retrieves a consumption entry by its ID.
  Future<SmartPlugConsumption> getConsumption(int id) {
    return (select(smartPlugConsumptions)..where((c) => c.id.equals(id)))
        .getSingle();
  }

  /// Retrieves all consumption entries for a smart plug, ordered by month (newest first).
  Future<List<SmartPlugConsumption>> getConsumptionsForPlug(int smartPlugId) {
    return (select(smartPlugConsumptions)
          ..where((c) => c.smartPlugId.equals(smartPlugId))
          ..orderBy([(c) => OrderingTerm.desc(c.month)]))
        .get();
  }

  /// Watches all consumption entries for a smart plug for reactive updates.
  Stream<List<SmartPlugConsumption>> watchConsumptionsForPlug(int smartPlugId) {
    return (select(smartPlugConsumptions)
          ..where((c) => c.smartPlugId.equals(smartPlugId))
          ..orderBy([(c) => OrderingTerm.desc(c.month)]))
        .watch();
  }

  /// Updates an existing consumption entry. Returns true if a row was updated.
  Future<bool> updateConsumption(SmartPlugConsumptionsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Consumption ID is required for update');
    }
    final rows = await (update(smartPlugConsumptions)
          ..where((c) => c.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a consumption entry by ID.
  Future<void> deleteConsumption(int id) async {
    await (delete(smartPlugConsumptions)..where((c) => c.id.equals(id))).go();
  }

  /// Gets the latest consumption entry for a smart plug.
  Future<SmartPlugConsumption?> getLatestConsumptionForPlug(
      int smartPlugId) async {
    return (select(smartPlugConsumptions)
          ..where((c) => c.smartPlugId.equals(smartPlugId))
          ..orderBy([(c) => OrderingTerm.desc(c.month)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the consumption entry for a specific plug and month.
  /// Returns null if no entry exists for that month.
  Future<SmartPlugConsumption?> getConsumptionForMonth(
    int smartPlugId,
    DateTime month,
  ) async {
    return (select(smartPlugConsumptions)
          ..where((c) =>
              c.smartPlugId.equals(smartPlugId) & c.month.equals(month)))
        .getSingleOrNull();
  }

  // ============== Aggregation Methods ==============

  /// Gets the total consumption for a smart plug within a date range.
  Future<double> getTotalConsumptionForPlug(
    int smartPlugId,
    DateTime from,
    DateTime to,
  ) async {
    final query = selectOnly(smartPlugConsumptions)
      ..addColumns([smartPlugConsumptions.valueKwh.sum()])
      ..where(smartPlugConsumptions.smartPlugId.equals(smartPlugId) &
          smartPlugConsumptions.month.isBiggerOrEqualValue(from) &
          smartPlugConsumptions.month.isSmallerThanValue(to));

    final result = await query.getSingle();
    return result.read(smartPlugConsumptions.valueKwh.sum()) ?? 0.0;
  }

  /// Gets the total consumption for a room within a date range.
  Future<double> getTotalConsumptionForRoom(
    int roomId,
    DateTime from,
    DateTime to,
  ) async {
    final query = selectOnly(smartPlugConsumptions).join([
      innerJoin(smartPlugs, smartPlugs.id.equalsExp(smartPlugConsumptions.smartPlugId)),
    ]);
    query
      ..addColumns([smartPlugConsumptions.valueKwh.sum()])
      ..where(smartPlugs.roomId.equals(roomId) &
          smartPlugConsumptions.month.isBiggerOrEqualValue(from) &
          smartPlugConsumptions.month.isSmallerThanValue(to));

    final result = await query.getSingle();
    return result.read(smartPlugConsumptions.valueKwh.sum()) ?? 0.0;
  }

  /// Gets the total smart plug consumption for a household within a date range.
  Future<double> getTotalSmartPlugConsumption(
    int householdId,
    DateTime from,
    DateTime to,
  ) async {
    final query = selectOnly(smartPlugConsumptions).join([
      innerJoin(smartPlugs, smartPlugs.id.equalsExp(smartPlugConsumptions.smartPlugId)),
      innerJoin(rooms, rooms.id.equalsExp(smartPlugs.roomId)),
    ]);
    query
      ..addColumns([smartPlugConsumptions.valueKwh.sum()])
      ..where(rooms.householdId.equals(householdId) &
          smartPlugConsumptions.month.isBiggerOrEqualValue(from) &
          smartPlugConsumptions.month.isSmallerThanValue(to));

    final result = await query.getSingle();
    return result.read(smartPlugConsumptions.valueKwh.sum()) ?? 0.0;
  }

  /// Gets the room for a given smart plug ID.
  Future<Room> getRoomForSmartPlug(int smartPlugId) async {
    final plug = await getSmartPlug(smartPlugId);
    return (select(rooms)..where((r) => r.id.equals(plug.roomId))).getSingle();
  }
}
