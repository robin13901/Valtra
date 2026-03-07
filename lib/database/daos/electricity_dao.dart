import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'electricity_dao.g.dart';

@DriftAccessor(tables: [ElectricityReadings])
class ElectricityDao extends DatabaseAccessor<AppDatabase>
    with _$ElectricityDaoMixin {
  ElectricityDao(super.db);

  /// Inserts a new electricity reading and returns its ID.
  Future<int> insertReading(ElectricityReadingsCompanion entry) {
    return into(electricityReadings).insert(entry);
  }

  /// Retrieves a reading by its ID.
  Future<ElectricityReading> getReading(int id) {
    return (select(electricityReadings)..where((r) => r.id.equals(id)))
        .getSingle();
  }

  /// Retrieves all readings for a household, ordered by timestamp descending.
  Future<List<ElectricityReading>> getReadingsForHousehold(int householdId) {
    return (select(electricityReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }

  /// Watches all readings for a household for reactive updates.
  Stream<List<ElectricityReading>> watchReadingsForHousehold(int householdId) {
    return (select(electricityReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .watch();
  }

  /// Updates an existing reading. Returns true if a row was updated.
  Future<bool> updateReading(ElectricityReadingsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Reading ID is required for update');
    }
    final rows = await (update(electricityReadings)
          ..where((r) => r.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a reading by ID.
  Future<void> deleteReading(int id) async {
    await (delete(electricityReadings)..where((r) => r.id.equals(id))).go();
  }

  /// Gets the reading immediately before the given timestamp for a household.
  /// Returns null if no previous reading exists.
  Future<ElectricityReading?> getPreviousReading(
    int householdId,
    DateTime timestamp,
  ) async {
    return (select(electricityReadings)
          ..where((r) =>
              r.householdId.equals(householdId) & r.timestamp.isSmallerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the latest reading for a household.
  /// Returns null if no readings exist.
  Future<ElectricityReading?> getLatestReading(int householdId) async {
    return (select(electricityReadings)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets the reading immediately after the given timestamp for a household.
  /// Returns null if no next reading exists.
  Future<ElectricityReading?> getNextReading(
    int householdId,
    DateTime timestamp,
  ) async {
    return (select(electricityReadings)
          ..where((r) =>
              r.householdId.equals(householdId) & r.timestamp.isBiggerThanValue(timestamp))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets all readings within a date range plus the immediately surrounding
  /// readings (one before rangeStart, one after rangeEnd) for interpolation.
  Future<List<ElectricityReading>> getReadingsForRange(
    int householdId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final before = await getPreviousReading(householdId, rangeStart);
    final after = await getNextReading(householdId, rangeEnd);
    final inRange = await (select(electricityReadings)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.timestamp.isBiggerOrEqualValue(rangeStart) &
              r.timestamp.isSmallerOrEqualValue(rangeEnd))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
        .get();
    return [?before, ...inRange, ?after];
  }
}
