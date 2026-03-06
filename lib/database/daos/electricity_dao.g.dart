// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'electricity_dao.dart';

// ignore_for_file: type=lint
mixin _$ElectricityDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $ElectricityReadingsTable get electricityReadings =>
      attachedDatabase.electricityReadings;
  ElectricityDaoManager get managers => ElectricityDaoManager(this);
}

class ElectricityDaoManager {
  final _$ElectricityDaoMixin _db;
  ElectricityDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$ElectricityReadingsTableTableManager get electricityReadings =>
      $$ElectricityReadingsTableTableManager(
        _db.attachedDatabase,
        _db.electricityReadings,
      );
}
