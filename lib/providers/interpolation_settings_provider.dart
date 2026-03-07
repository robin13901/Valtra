import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gas_conversion_service.dart';
import '../services/interpolation/models.dart';

/// Persists user's preferred interpolation method per meter type
/// and gas kWh conversion factor using SharedPreferences.
class InterpolationSettingsProvider extends ChangeNotifier {
  static const _prefix = 'interpolation_';
  static const _gasFactorKey = 'gas_kwh_factor';

  SharedPreferences? _prefs;

  /// Initialize the provider with persisted preferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  /// Get the interpolation method for a meter type.
  InterpolationMethod getMethodForMeterType(String meterType) {
    final value = _prefs?.getString('$_prefix$meterType');
    return value == 'step'
        ? InterpolationMethod.step
        : InterpolationMethod.linear;
  }

  /// Set the interpolation method for a meter type.
  Future<void> setMethodForMeterType(
    String meterType,
    InterpolationMethod method,
  ) async {
    await _prefs?.setString('$_prefix$meterType', method.name);
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
