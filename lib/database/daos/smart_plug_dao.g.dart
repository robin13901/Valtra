// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_plug_dao.dart';

// ignore_for_file: type=lint
mixin _$SmartPlugDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $RoomsTable get rooms => attachedDatabase.rooms;
  $SmartPlugsTable get smartPlugs => attachedDatabase.smartPlugs;
  $SmartPlugConsumptionsTable get smartPlugConsumptions =>
      attachedDatabase.smartPlugConsumptions;
  SmartPlugDaoManager get managers => SmartPlugDaoManager(this);
}

class SmartPlugDaoManager {
  final _$SmartPlugDaoMixin _db;
  SmartPlugDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db.attachedDatabase, _db.rooms);
  $$SmartPlugsTableTableManager get smartPlugs =>
      $$SmartPlugsTableTableManager(_db.attachedDatabase, _db.smartPlugs);
  $$SmartPlugConsumptionsTableTableManager get smartPlugConsumptions =>
      $$SmartPlugConsumptionsTableTableManager(
        _db.attachedDatabase,
        _db.smartPlugConsumptions,
      );
}
