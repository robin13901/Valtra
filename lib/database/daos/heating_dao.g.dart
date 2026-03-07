// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heating_dao.dart';

// ignore_for_file: type=lint
mixin _$HeatingDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $HeatingMetersTable get heatingMeters => attachedDatabase.heatingMeters;
  $HeatingReadingsTable get heatingReadings => attachedDatabase.heatingReadings;
  HeatingDaoManager get managers => HeatingDaoManager(this);
}

class HeatingDaoManager {
  final _$HeatingDaoMixin _db;
  HeatingDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$HeatingMetersTableTableManager get heatingMeters =>
      $$HeatingMetersTableTableManager(_db.attachedDatabase, _db.heatingMeters);
  $$HeatingReadingsTableTableManager get heatingReadings =>
      $$HeatingReadingsTableTableManager(
        _db.attachedDatabase,
        _db.heatingReadings,
      );
}
