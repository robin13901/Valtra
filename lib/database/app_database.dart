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
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(costConfigs);
          }
          if (from < 3) {
            // Step 1: Create rooms from heating meter locations.
            // Each distinct (household_id, location) pair becomes a room.
            // NULL/empty locations default to 'Standard'.
            await customStatement('''
              INSERT OR IGNORE INTO rooms (household_id, name)
              SELECT DISTINCT hm.household_id,
                CASE
                  WHEN hm.location IS NULL OR TRIM(hm.location) = '' THEN 'Standard'
                  ELSE hm.location
                END
              FROM heating_meters hm
              WHERE NOT EXISTS (
                SELECT 1 FROM rooms r
                WHERE r.household_id = hm.household_id
                AND r.name = CASE
                  WHEN hm.location IS NULL OR TRIM(hm.location) = '' THEN 'Standard'
                  ELSE hm.location
                END
              )
            ''');

            // Step 2: Recreate heating_meters with new schema
            // (room_id FK, heating_type, heating_ratio; location removed)
            await customStatement('''
              CREATE TABLE heating_meters_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                household_id INTEGER NOT NULL REFERENCES households(id),
                room_id INTEGER NOT NULL REFERENCES rooms(id),
                name TEXT NOT NULL,
                heating_type INTEGER NOT NULL DEFAULT 0,
                heating_ratio REAL
              )
            ''');
            await customStatement('''
              INSERT INTO heating_meters_new (id, household_id, room_id, name)
              SELECT hm.id, hm.household_id, r.id, hm.name
              FROM heating_meters hm
              JOIN rooms r ON r.household_id = hm.household_id
                AND r.name = CASE
                  WHEN hm.location IS NULL OR TRIM(hm.location) = '' THEN 'Standard'
                  ELSE hm.location
                END
            ''');
            await customStatement('DROP TABLE heating_meters');
            await customStatement(
                'ALTER TABLE heating_meters_new RENAME TO heating_meters');

            // Step 3: Recreate smart_plug_consumptions without intervalType.
            // Aggregate by (smart_plug_id, month) with SUM for duplicates.
            // Drift stores DateTime as seconds-since-epoch (local time).
            // SQLite's 'unixepoch' interprets as UTC, so we apply the
            // local timezone offset to get correct year-month grouping.
            final tzOffset = DateTime.now().timeZoneOffset.inSeconds;
            await customStatement('''
              CREATE TABLE smart_plug_consumptions_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                smart_plug_id INTEGER NOT NULL REFERENCES smart_plugs(id),
                month INTEGER NOT NULL,
                value_kwh REAL NOT NULL
              )
            ''');
            await customStatement('''
              INSERT INTO smart_plug_consumptions_new (smart_plug_id, month, value_kwh)
              SELECT smart_plug_id,
                CAST(strftime('%s',
                  strftime('%Y', interval_start + $tzOffset, 'unixepoch') || '-' ||
                  strftime('%m', interval_start + $tzOffset, 'unixepoch') || '-01 00:00:00'
                ) AS INTEGER) - $tzOffset,
                SUM(value_kwh)
              FROM smart_plug_consumptions
              GROUP BY smart_plug_id,
                strftime('%Y-%m', interval_start + $tzOffset, 'unixepoch')
            ''');
            await customStatement('DROP TABLE smart_plug_consumptions');
            await customStatement(
                'ALTER TABLE smart_plug_consumptions_new RENAME TO smart_plug_consumptions');
          }
          if (from < 4) {
            await customStatement(
              "ALTER TABLE households ADD COLUMN person_count INTEGER NOT NULL DEFAULT 1",
            );
          }
          if (from < 5) {
            // Remove name, heating_type, heating_ratio columns from heating_meters
            await customStatement('''
              CREATE TABLE heating_meters_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                household_id INTEGER NOT NULL REFERENCES households(id),
                room_id INTEGER NOT NULL REFERENCES rooms(id)
              )
            ''');
            await customStatement('''
              INSERT INTO heating_meters_new (id, household_id, room_id)
              SELECT id, household_id, room_id FROM heating_meters
            ''');
            await customStatement('DROP TABLE heating_meters');
            await customStatement(
                'ALTER TABLE heating_meters_new RENAME TO heating_meters');
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
