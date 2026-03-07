// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_dao.dart';

// ignore_for_file: type=lint
mixin _$HouseholdDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $ElectricityReadingsTable get electricityReadings =>
      attachedDatabase.electricityReadings;
  $GasReadingsTable get gasReadings => attachedDatabase.gasReadings;
  $WaterMetersTable get waterMeters => attachedDatabase.waterMeters;
  $RoomsTable get rooms => attachedDatabase.rooms;
  $HeatingMetersTable get heatingMeters => attachedDatabase.heatingMeters;
  HouseholdDaoManager get managers => HouseholdDaoManager(this);
}

class HouseholdDaoManager {
  final _$HouseholdDaoMixin _db;
  HouseholdDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$ElectricityReadingsTableTableManager get electricityReadings =>
      $$ElectricityReadingsTableTableManager(
        _db.attachedDatabase,
        _db.electricityReadings,
      );
  $$GasReadingsTableTableManager get gasReadings =>
      $$GasReadingsTableTableManager(_db.attachedDatabase, _db.gasReadings);
  $$WaterMetersTableTableManager get waterMeters =>
      $$WaterMetersTableTableManager(_db.attachedDatabase, _db.waterMeters);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db.attachedDatabase, _db.rooms);
  $$HeatingMetersTableTableManager get heatingMeters =>
      $$HeatingMetersTableTableManager(_db.attachedDatabase, _db.heatingMeters);
}
