// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gas_dao.dart';

// ignore_for_file: type=lint
mixin _$GasDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $GasReadingsTable get gasReadings => attachedDatabase.gasReadings;
  GasDaoManager get managers => GasDaoManager(this);
}

class GasDaoManager {
  final _$GasDaoMixin _db;
  GasDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$GasReadingsTableTableManager get gasReadings =>
      $$GasReadingsTableTableManager(_db.attachedDatabase, _db.gasReadings);
}
