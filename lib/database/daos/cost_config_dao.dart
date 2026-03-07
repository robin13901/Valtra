import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cost_config_dao.g.dart';

@DriftAccessor(tables: [CostConfigs, Households])
class CostConfigDao extends DatabaseAccessor<AppDatabase>
    with _$CostConfigDaoMixin {
  CostConfigDao(super.db);

  /// Insert a new cost config.
  Future<int> insertConfig(CostConfigsCompanion config) =>
      into(costConfigs).insert(config);

  /// Update an existing cost config.
  Future<bool> updateConfig(CostConfig config) =>
      update(costConfigs).replace(config);

  /// Delete a cost config by ID.
  Future<int> deleteConfig(int id) =>
      (delete(costConfigs)..where((c) => c.id.equals(id))).go();

  /// Get all configs for a household, ordered by validFrom DESC.
  Future<List<CostConfig>> getConfigsForHousehold(int householdId) =>
      (select(costConfigs)
            ..where((c) => c.householdId.equals(householdId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.validFrom),
            ]))
          .get();

  /// Watch all configs for a household (reactive stream).
  Stream<List<CostConfig>> watchConfigsForHousehold(int householdId) =>
      (select(costConfigs)
            ..where((c) => c.householdId.equals(householdId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.validFrom),
            ]))
          .watch();

  /// Get configs for a specific meter type in a household.
  Future<List<CostConfig>> getConfigsForMeterType(
    int householdId,
    CostMeterType meterType,
  ) =>
      (select(costConfigs)
            ..where((c) =>
                c.householdId.equals(householdId) &
                c.meterType.equalsValue(meterType))
            ..orderBy([
              (c) => OrderingTerm.desc(c.validFrom),
            ]))
          .get();

  /// Get the active config for a meter type at a given date.
  /// Returns the config with the latest validFrom <= date.
  Future<CostConfig?> getActiveConfig(
    int householdId,
    CostMeterType meterType,
    DateTime date,
  ) =>
      (select(costConfigs)
            ..where((c) =>
                c.householdId.equals(householdId) &
                c.meterType.equalsValue(meterType) &
                c.validFrom.isSmallerOrEqualValue(date))
            ..orderBy([
              (c) => OrderingTerm.desc(c.validFrom),
            ])
            ..limit(1))
          .getSingleOrNull();
}
