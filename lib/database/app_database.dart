import 'package:drift/drift.dart';

import 'daos/household_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Households,
  ElectricityReadings,
  GasReadings,
  WaterMeters,
  WaterReadings,
  HeatingMeters,
  HeatingReadings,
  Rooms,
  SmartPlugs,
  SmartPlugConsumptions,
], daos: [
  HouseholdDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
      );

  /// Provides access to household CRUD operations.
  @override
  HouseholdDao get householdDao => HouseholdDao(this);
}
