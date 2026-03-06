import 'package:drift/drift.dart';

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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
      );
}
