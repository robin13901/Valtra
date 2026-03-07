import 'package:drift/drift.dart';

import 'daos/cost_config_dao.dart';
import 'daos/electricity_dao.dart';
import 'daos/gas_dao.dart';
import 'daos/heating_dao.dart';
import 'daos/household_dao.dart';
import 'daos/room_dao.dart';
import 'daos/smart_plug_dao.dart';
import 'daos/water_dao.dart';
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
  CostConfigs,
], daos: [
  HouseholdDao,
  ElectricityDao,
  GasDao,
  HeatingDao,
  RoomDao,
  SmartPlugDao,
  WaterDao,
  CostConfigDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(costConfigs);
          }
        },
      );

  /// Provides access to household CRUD operations.
  @override
  HouseholdDao get householdDao => HouseholdDao(this);

  /// Provides access to electricity reading CRUD operations.
  @override
  ElectricityDao get electricityDao => ElectricityDao(this);

  /// Provides access to room CRUD operations.
  @override
  RoomDao get roomDao => RoomDao(this);

  /// Provides access to smart plug CRUD operations.
  @override
  SmartPlugDao get smartPlugDao => SmartPlugDao(this);

  /// Provides access to water meter and reading CRUD operations.
  @override
  WaterDao get waterDao => WaterDao(this);

  /// Provides access to gas reading CRUD operations.
  @override
  GasDao get gasDao => GasDao(this);

  /// Provides access to heating meter and reading CRUD operations.
  @override
  HeatingDao get heatingDao => HeatingDao(this);

  /// Provides access to cost configuration CRUD operations.
  @override
  CostConfigDao get costConfigDao => CostConfigDao(this);
}
