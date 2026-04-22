import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'heating_dao.g.dart';

@DriftAccessor(tables: [HeatingMeters, HeatingReadings, Rooms])
class HeatingDao extends DatabaseAccessor<AppDatabase>
    with _$HeatingDaoMixin {
  HeatingDao(super.db);

  // ============== Heating Meter Methods ==============

  /// Inserts a new heating meter and returns its ID.
  Future<int> insertMeter(HeatingMetersCompanion entry) {
    return into(heatingMeters).insert(entry);
  }

  /// Retrieves a heating meter by its ID.
  Future<HeatingMeter> getMeter(int id) {
    return (select(heatingMeters)..where((m) => m.id.equals(id))).getSingle();
  }

  /// Retrieves all heating meters for a household, ordered by room ID.
  Future<List<HeatingMeter>> getMetersForHousehold(int householdId) {
    return (select(heatingMeters)
          ..where((m) => m.householdId.equals(householdId))
          ..orderBy([(m) => OrderingTerm.asc(m.roomId)]))
        .get();
  }

  /// Watches all heating meters for a household for reactive updates.
  Stream<List<HeatingMeter>> watchMetersForHousehold(int householdId) {
    return (select(heatingMeters)
          ..where((m) => m.householdId.equals(householdId))
          ..orderBy([(m) => OrderingTerm.asc(m.roomId)]))
        .watch();
  }

  /// Retrieves all heating meters for a specific room.
  Future<List<HeatingMeter>> getMetersForRoom(int roomId) {
    return (select(heatingMeters)
          ..where((m) => m.roomId.equals(roomId))
          ..orderBy([(m) => OrderingTerm.asc(m.id)]))
        .get();
  }

  /// Watches all heating meters for a specific room for reactive updates.
  Stream<List<HeatingMeter>> watchMetersForRoom(int roomId) {
    return (select(heatingMeters)
          ..where((m) => m.roomId.equals(roomId))
          ..orderBy([(m) => OrderingTerm.asc(m.id)]))
        .watch();
  }

  /// Gets the room associated with a heating meter.
  Future<Room> getRoomForMeter(int meterId) async {
    final meter = await getMeter(meterId);
    return (select(rooms)..where((r) => r.id.equals(meter.roomId)))
        .getSingle();
  }

  /// Updates an existing heating meter. Returns true if a row was updated.
  Future<bool> updateMeter(HeatingMetersCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Heating meter ID is required for update');
    }
    final rows = await (update(heatingMeters)
          ..where((m) => m.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a heating meter by ID, cascading to delete all its readings.
  Future<void> deleteMeter(int id) async {
    await transaction(() async {
      await (delete(heatingReadings)
            ..where((r) => r.heatingMeterId.equals(id)))
          .go();
      await (delete(heatingMeters)..where((m) => m.id.equals(id))).go();
    });
  }

  /// Gets the count of readings for a heating meter.
  Future<int> getReadingCountForMeter(int meterId) async {
    final count = heatingReadings.id.count();
    final query = selectOnly(heatingReadings)
      ..addColumns([count])
      ..where(heatingReadings.heatingMeterId.equals(meterId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============== Heating Reading Methods ==============

  /// Inserts a new heating reading and returns its ID.
  Future<int> insertReading(HeatingReadingsCompanion entry) {
    return into(heatingReadings).insert(entry);
  }

  /// Retrieves a heating reading by its ID.
  Future<HeatingReading> getReading(int id) {
    return (select(heatingReadings)..where((r) => r.id.equals(id)))
        .getSingle();
  }

  /// Retrieves all readings for a heating meter, ordered by timestamp descending.
  Future<List<HeatingReading>> getReadingsForMeter(int meterId) {
    return (select(heatingReadings)
          ..where((r) => r.heatingMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }

  /// Watches all readings for a heating meter for reactive updates.
  Stream<List<HeatingReading>> watchReadingsForMeter(int meterId) {
    return (select(heatingReadings)
          ..where((r) => r.heatingMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .watch();
  }

  /// Updates an existing heating reading. Returns true if a row was updated.
  Future<bool> updateReading(HeatingReadingsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Reading ID is required for update');
    }
    final rows = await (update(heatingReadings)
          ..where((r) => r.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a heating reading by ID.
  Future<void> deleteReading(int id) async {
    await (delete(heatingReadings)..where((r) => r.id.equals(id))).go();
  }

  /// Deletes all readings for a heating meter.
  Future<void> deleteReadingsForMeter(int meterId) async {
    await (delete(heatingReadings)
          ..where((r) => r.heatingMeterId.equals(meterId)))
        .go();
  }

  /// Gets the reading immediately before the given timestamp for a meter.
  /// Returns null if no previous reading exists.
  Future<HeatingReading?> getPreviousReading(
    int meterId,
    DateTime timestamp,
  ) async {
    return (select(heatingReadings)
          ..where((r) =>
              r.heatingMeterId.equals(meterId) &
              r.timestamp.isSmallerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the latest reading for a heating meter.
  /// Returns null if no readings exist.
  Future<HeatingReading?> getLatestReading(int meterId) async {
    return (select(heatingReadings)
          ..where((r) => r.heatingMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the reading immediately after the given timestamp for a meter.
  /// Returns null if no next reading exists.
  Future<HeatingReading?> getNextReading(
    int meterId,
    DateTime timestamp,
  ) async {
    return (select(heatingReadings)
          ..where((r) =>
              r.heatingMeterId.equals(meterId) &
              r.timestamp.isBiggerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets all readings within a date range plus the immediately surrounding
  /// readings (one before rangeStart, one after rangeEnd) for interpolation.
  Future<List<HeatingReading>> getReadingsForRange(
    int heatingMeterId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final before = await getPreviousReading(heatingMeterId, rangeStart);
    final after = await getNextReading(heatingMeterId, rangeEnd);
    final inRange = await (select(heatingReadings)
          ..where((r) =>
              r.heatingMeterId.equals(heatingMeterId) &
              r.timestamp.isBiggerOrEqualValue(rangeStart) &
              r.timestamp.isSmallerOrEqualValue(rangeEnd))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
        .get();
    return [?before, ...inRange, ?after];
  }
}
