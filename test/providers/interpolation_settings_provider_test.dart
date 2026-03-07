import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  group('InterpolationSettingsProvider', () {
    late InterpolationSettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = InterpolationSettingsProvider();
      await provider.init();
    });

    test('default method is linear for all meter types', () {
      expect(
        provider.getMethodForMeterType('electricity'),
        InterpolationMethod.linear,
      );
      expect(
        provider.getMethodForMeterType('gas'),
        InterpolationMethod.linear,
      );
      expect(
        provider.getMethodForMeterType('water'),
        InterpolationMethod.linear,
      );
      expect(
        provider.getMethodForMeterType('heating'),
        InterpolationMethod.linear,
      );
    });

    test('set and get method for electricity', () async {
      await provider.setMethodForMeterType(
          'electricity', InterpolationMethod.step);

      expect(
        provider.getMethodForMeterType('electricity'),
        InterpolationMethod.step,
      );
    });

    test('set and get method for gas', () async {
      await provider.setMethodForMeterType('gas', InterpolationMethod.step);

      expect(
        provider.getMethodForMeterType('gas'),
        InterpolationMethod.step,
      );
    });

    test('methods are independent per meter type', () async {
      await provider.setMethodForMeterType(
          'electricity', InterpolationMethod.step);

      expect(
        provider.getMethodForMeterType('electricity'),
        InterpolationMethod.step,
      );
      expect(
        provider.getMethodForMeterType('gas'),
        InterpolationMethod.linear,
      );
    });

    test('default gas factor is 10.3', () {
      expect(provider.gasKwhFactor, GasConversionService.defaultFactor);
    });

    test('set and get custom gas factor', () async {
      await provider.setGasKwhFactor(11.5);

      expect(provider.gasKwhFactor, 11.5);
    });

    test('notifyListeners called on method change', () async {
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setMethodForMeterType(
          'electricity', InterpolationMethod.step);

      expect(notified, true);
    });

    test('notifyListeners called on gas factor change', () async {
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setGasKwhFactor(12.0);

      expect(notified, true);
    });
  });
}
