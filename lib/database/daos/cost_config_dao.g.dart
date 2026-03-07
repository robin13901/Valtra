// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_config_dao.dart';

// ignore_for_file: type=lint
mixin _$CostConfigDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $CostConfigsTable get costConfigs => attachedDatabase.costConfigs;
  CostConfigDaoManager get managers => CostConfigDaoManager(this);
}

class CostConfigDaoManager {
  final _$CostConfigDaoMixin _db;
  CostConfigDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$CostConfigsTableTableManager get costConfigs =>
      $$CostConfigsTableTableManager(_db.attachedDatabase, _db.costConfigs);
}
