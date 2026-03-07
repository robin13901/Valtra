import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/services/gas_conversion_service.dart';

void main() {
  group('InterpolationSettingsProvider', () {
    late InterpolationSettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = InterpolationSettingsProvider();
      await provider.init();
    });

    test('default gas factor is 10.3', () {
      expect(provider.gasKwhFactor, GasConversionService.defaultFactor);
    });

    test('set and get custom gas factor', () async {
      await provider.setGasKwhFactor(11.5);

      expect(provider.gasKwhFactor, 11.5);
    });

    test('notifyListeners called on gas factor change', () async {
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setGasKwhFactor(12.0);

      expect(notified, true);
    });

    test('notifyListeners called on init', () async {
      var notified = false;
      final newProvider = InterpolationSettingsProvider();
      newProvider.addListener(() => notified = true);

      await newProvider.init();

      expect(notified, true);
    });
  });
}
