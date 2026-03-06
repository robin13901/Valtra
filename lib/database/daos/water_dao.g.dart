// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_dao.dart';

// ignore_for_file: type=lint
mixin _$WaterDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $WaterMetersTable get waterMeters => attachedDatabase.waterMeters;
  $WaterReadingsTable get waterReadings => attachedDatabase.waterReadings;
  WaterDaoManager get managers => WaterDaoManager(this);
}

class WaterDaoManager {
  final _$WaterDaoMixin _db;
  WaterDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$WaterMetersTableTableManager get waterMeters =>
      $$WaterMetersTableTableManager(_db.attachedDatabase, _db.waterMeters);
  $$WaterReadingsTableTableManager get waterReadings =>
      $$WaterReadingsTableTableManager(_db.attachedDatabase, _db.waterReadings);
}
