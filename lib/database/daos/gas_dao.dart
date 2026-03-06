import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'gas_dao.g.dart';

@DriftAccessor(tables: [GasReadings])
class GasDao extends DatabaseAccessor<AppDatabase> with _$GasDaoMixin {
  GasDao(super.db);

  /// Inserts a new gas reading and returns its ID.
  Future<int> insertReading(GasReadingsCompanion entry) {
    return into(gasReadings).insert(entry);
  }

  /// Retrieves a reading by its ID.
  Future<GasReading> getReading(int id) {
    return (select(gasReadings)..where((r) => r.id.equals(id))).getSingle();
  }

  /// Retrieves all readings for a household, ordered by timestamp descending.
  Future<List<GasReading>> getReadingsForHousehold(int householdId) {
    return (select(gasReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }

  /// Watches all readings for a household for reactive updates.
  Stream<List<GasReading>> watchReadingsForHousehold(int householdId) {
    return (select(gasReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .watch();
  }

  /// Updates an existing reading. Returns true if a row was updated.
  Future<bool> updateReading(GasReadingsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Reading ID is required for update');
    }
    final rows = await (update(gasReadings)
          ..where((r) => r.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) async {
    await (delete(gasReadings)..where((r) => r.id.equals(id))).go();
  }

  /// Gets the reading immediately before the given timestamp for a household.
  /// Returns null if no previous reading exists.
  Future<GasReading?> getPreviousReading(
    int householdId,
    DateTime timestamp,
  ) async {
    return (select(gasReadings)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.timestamp.isSmallerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the latest reading for a household.
  /// Returns null if no readings exist.
  Future<GasReading?> getLatestReading(int householdId) async {
    return (select(gasReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the reading immediately after the given timestamp for a household.
  /// Returns null if no next reading exists.
  Future<GasReading?> getNextReading(
    int householdId,
    DateTime timestamp,
  ) async {
    return (select(gasReadings)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.timestamp.isBiggerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }
}
