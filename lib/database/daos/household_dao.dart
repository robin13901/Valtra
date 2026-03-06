import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'household_dao.g.dart';

@DriftAccessor(tables: [
  Households,
  ElectricityReadings,
  GasReadings,
  WaterMeters,
  HeatingMeters,
  Rooms,
])
class HouseholdDao extends DatabaseAccessor<AppDatabase>
    with _$HouseholdDaoMixin {
  HouseholdDao(super.db);

  /// Inserts a new household and returns its ID.
  Future<int> insert(HouseholdsCompanion entry) {
    return into(households).insert(entry);
  }

  /// Retrieves a household by its ID.
  Future<Household> getHousehold(int id) {
    return (select(households)..where((h) => h.id.equals(id))).getSingle();
  }

  /// Retrieves all households ordered by creation date (newest first).
  Future<List<Household>> getAllHouseholds() {
    return (select(households)..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .get();
  }

  /// Watches all households for reactive updates.
  Stream<List<Household>> watchAllHouseholds() {
    return (select(households)..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .watch();
  }

  /// Updates an existing household. Returns true if a row was updated.
  Future<bool> updateHousehold(HouseholdsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('Household ID is required for update');
    }
    final rows = await (update(households)
          ..where((h) => h.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Deletes a household by ID.
  Future<void> deleteHousehold(int id) async {
    await (delete(households)..where((h) => h.id.equals(id))).go();
  }

  /// Checks if a household has related data (readings, meters, rooms).
  /// Returns true if any related records exist.
  Future<bool> hasRelatedData(int householdId) async {
    // Check electricity readings
    final electricityCount = await (select(electricityReadings)
          ..where((r) => r.householdId.equals(householdId)))
        .get();
    if (electricityCount.isNotEmpty) return true;

    // Check gas readings
    final gasCount = await (select(gasReadings)
          ..where((r) => r.householdId.equals(householdId)))
        .get();
    if (gasCount.isNotEmpty) return true;

    // Check water meters
    final waterCount = await (select(waterMeters)
          ..where((m) => m.householdId.equals(householdId)))
        .get();
    if (waterCount.isNotEmpty) return true;

    // Check heating meters
    final heatingCount = await (select(heatingMeters)
          ..where((m) => m.householdId.equals(householdId)))
        .get();
    if (heatingCount.isNotEmpty) return true;

    // Check rooms
    final roomCount = await (select(rooms)
          ..where((r) => r.householdId.equals(householdId)))
        .get();
    if (roomCount.isNotEmpty) return true;

    return false;
  }
}
