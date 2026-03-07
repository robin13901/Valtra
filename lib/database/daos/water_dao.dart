import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'water_dao.g.dart';

@DriftAccessor(tables: [WaterMeters, WaterReadings])
class WaterDao extends DatabaseAccessor<AppDatabase> with _$WaterDaoMixin {
  WaterDao(super.db);

  // ============== Water Meter Methods ==============

  /// Inserts a new water meter and returns its ID.
  Future<int> insertMeter(WaterMetersCompanion entry) {
    return into(waterMeters).insert(entry);
  }

  /// Retrieves a water meter by its ID.
  Future<WaterMeter> getMeter(int id) {
    return (select(waterMeters)..where((m) => m.id.equals(id))).getSingle();
  }

  /// Retrieves all water meters for a household, ordered alphabetically by name.
  Future<List<WaterMeter>> getMetersForHousehold(int householdId) {
    return (select(waterMeters)
          ..where((m) => m.householdId.equals(householdId))
          ..orderBy([(m) => OrderingTerm.asc(m.name)]))
        .get();
  }

  /// Watches all water meters for a household for reactive updates.
  Stream<List<WaterMeter>> watchMetersForHousehold(int householdId) {
    return (select(waterMeters)
          ..where((m) => m.householdId.equals(householdId))
          ..orderBy([(m) => OrderingTerm.asc(m.name)]))
        .watch();
  }

  /// Updates an existing water meter. Returns true if a row was updated.
  Future<bool> updateMeter(WaterMetersCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Water meter ID is required for update');
    }
    final rows = await (update(waterMeters)
          ..where((m) => m.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a water meter by ID, cascading to delete all its readings.
  Future<void> deleteMeter(int id) async {
    await transaction(() async {
      // Delete all readings for this meter
      await (delete(waterReadings)..where((r) => r.waterMeterId.equals(id)))
          .go();

      // Delete the water meter
      await (delete(waterMeters)..where((m) => m.id.equals(id))).go();
    });
  }

  /// Gets the count of readings for a water meter.
  Future<int> getReadingCountForMeter(int meterId) async {
    final count = waterReadings.id.count();
    final query = selectOnly(waterReadings)
      ..addColumns([count])
      ..where(waterReadings.waterMeterId.equals(meterId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============== Water Reading Methods ==============

  /// Inserts a new water reading and returns its ID.
  Future<int> insertReading(WaterReadingsCompanion entry) {
    return into(waterReadings).insert(entry);
  }

  /// Retrieves a water reading by its ID.
  Future<WaterReading> getReading(int id) {
    return (select(waterReadings)..where((r) => r.id.equals(id))).getSingle();
  }

  /// Retrieves all readings for a water meter, ordered by timestamp descending.
  Future<List<WaterReading>> getReadingsForMeter(int meterId) {
    return (select(waterReadings)
          ..where((r) => r.waterMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }

  /// Watches all readings for a water meter for reactive updates.
  Stream<List<WaterReading>> watchReadingsForMeter(int meterId) {
    return (select(waterReadings)
          ..where((r) => r.waterMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .watch();
  }

  /// Updates an existing water reading. Returns true if a row was updated.
  Future<bool> updateReading(WaterReadingsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Reading ID is required for update');
    }
    final rows = await (update(waterReadings)
          ..where((r) => r.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a water reading by ID.
  Future<void> deleteReading(int id) async {
    await (delete(waterReadings)..where((r) => r.id.equals(id))).go();
  }

  /// Deletes all readings for a water meter.
  Future<void> deleteReadingsForMeter(int meterId) async {
    await (delete(waterReadings)..where((r) => r.waterMeterId.equals(meterId)))
        .go();
  }

  /// Gets the reading immediately before the given timestamp for a meter.
  /// Returns null if no previous reading exists.
  Future<WaterReading?> getPreviousReading(
    int meterId,
    DateTime timestamp,
  ) async {
    return (select(waterReadings)
          ..where((r) =>
              r.waterMeterId.equals(meterId) &
              r.timestamp.isSmallerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the latest reading for a water meter.
  /// Returns null if no readings exist.
  Future<WaterReading?> getLatestReading(int meterId) async {
    return (select(waterReadings)
          ..where((r) => r.waterMeterId.equals(meterId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the reading immediately after the given timestamp for a meter.
  /// Returns null if no next reading exists.
  Future<WaterReading?> getNextReading(
    int meterId,
    DateTime timestamp,
  ) async {
    return (select(waterReadings)
          ..where((r) =>
              r.waterMeterId.equals(meterId) &
              r.timestamp.isBiggerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets all readings within a date range plus the immediately surrounding
  /// readings (one before rangeStart, one after rangeEnd) for interpolation.
  Future<List<WaterReading>> getReadingsForRange(
    int waterMeterId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final before = await getPreviousReading(waterMeterId, rangeStart);
    final after = await getNextReading(waterMeterId, rangeEnd);
    final inRange = await (select(waterReadings)
          ..where((r) =>
              r.waterMeterId.equals(waterMeterId) &
              r.timestamp.isBiggerOrEqualValue(rangeStart) &
              r.timestamp.isSmallerOrEqualValue(rangeEnd))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
        .get();
    return [?before, ...inRange, ?after];
  }
}
