import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gas_conversion_service.dart';

/// Persists gas kWh conversion factor using SharedPreferences.
/// Interpolation method selection was removed in Phase 15 (linear-only).
class InterpolationSettingsProvider extends ChangeNotifier {
  static const _gasFactorKey = 'gas_kwh_factor';

  SharedPreferences? _prefs;

  /// Initialize the provider with persisted preferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  /// The gas kWh conversion factor.
  double get gasKwhFactor =>
      _prefs?.getDouble(_gasFactorKey) ?? GasConversionService.defaultFactor;

  /// Set the gas kWh conversion factor.
  Future<void> setGasKwhFactor(double factor) async {
    await _prefs?.setDouble(_gasFactorKey, factor);
    notifyListeners();
  }
}
