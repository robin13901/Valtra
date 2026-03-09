import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/cost_config_dao.dart';
import '../database/tables.dart';
import '../services/cost_calculation_service.dart';

/// Manages cost configuration state per household.
///
/// Subscribes to the database for reactive updates and provides
/// cost calculation convenience methods.
class CostConfigProvider extends ChangeNotifier {
  final CostConfigDao _costConfigDao;
  final CostCalculationService _costCalculationService;

  int? _householdId;
  List<CostConfig> _configs = [];
  StreamSubscription<List<CostConfig>>? _configsSubscription;

  CostConfigProvider({
    required CostConfigDao costConfigDao,
    required CostCalculationService costCalculationService,
  })  : _costConfigDao = costConfigDao,
        _costCalculationService = costCalculationService;

  // Getters
  int? get householdId => _householdId;
  List<CostConfig> get configs => _configs;
  bool get hasCostConfigs => _configs.isNotEmpty;

  void setHouseholdId(int? id) {
    _householdId = id;
    _configsSubscription?.cancel();
    _configsSubscription = null;

    if (id != null) {
      _configsSubscription =
          _costConfigDao.watchConfigsForHousehold(id).listen((configs) {
        _configs = configs;
        notifyListeners();
      });
    } else {
      _configs = [];
      notifyListeners();
    }
  }

  /// Get the active config for a meter type at a given date.
  /// Searches the cached configs for the latest validFrom <= date.
  CostConfig? getActiveConfig(CostMeterType meterType, DateTime date) {
    final matching = _configs
        .where((c) =>
            c.meterType == meterType &&
            !c.validFrom.isAfter(date))
        .toList();
    if (matching.isEmpty) return null;
    // Configs are ordered by validFrom DESC from the DAO
    return matching.first;
  }

  /// Get all configs for a specific meter type.
  List<CostConfig> getConfigsForMeterType(CostMeterType meterType) {
    return _configs.where((c) => c.meterType == meterType).toList();
  }

  /// Calculate cost for a consumption period using active config.
  CostResult? calculateCost({
    required CostMeterType meterType,
    required double consumption,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final config = getActiveConfig(meterType, periodStart);
    if (config == null) return null;

    final tiers = _costCalculationService.parseTiers(config.priceTiers);
    final daysInPeriod = periodEnd.difference(periodStart).inDays;
    final daysInMonth =
        DateUtils.getDaysInMonth(periodStart.year, periodStart.month);

    return _costCalculationService.calculateMonthlyCost(
      consumption: consumption,
      unitPrice: config.unitPrice,
      standingCharge: config.standingCharge / 12,
      currencySymbol: config.currencySymbol,
      tiers: tiers.isNotEmpty ? tiers : null,
      daysInPeriod: daysInPeriod,
      daysInMonth: daysInMonth,
    );
  }

  // CRUD operations

  Future<int> addConfig(CostConfigsCompanion config) =>
      _costConfigDao.insertConfig(config);

  Future<bool> updateConfig(CostConfig config) =>
      _costConfigDao.updateConfig(config);

  Future<void> deleteConfig(int id) => _costConfigDao.deleteConfig(id);

  @override
  void dispose() {
    _configsSubscription?.cancel();
    super.dispose();
  }
}
