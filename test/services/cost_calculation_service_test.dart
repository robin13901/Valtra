import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/cost_calculation_service.dart';

void main() {
  const service = CostCalculationService();

  group('CostCalculationService', () {
    group('calculateMonthlyCost', () {
      test('flat rate calculation', () {
        final result = service.calculateMonthlyCost(
          consumption: 100,
          unitPrice: 0.30,
          standingCharge: 0,
          currencySymbol: '€',
        );

        expect(result.unitCost, closeTo(30.0, 0.01));
        expect(result.standingCost, 0);
        expect(result.totalCost, closeTo(30.0, 0.01));
        expect(result.currencySymbol, '€');
      });

      test('flat rate with standing charge', () {
        final result = service.calculateMonthlyCost(
          consumption: 100,
          unitPrice: 0.30,
          standingCharge: 12.50,
          currencySymbol: '€',
        );

        expect(result.unitCost, closeTo(30.0, 0.01));
        expect(result.standingCost, closeTo(12.50, 0.01));
        expect(result.totalCost, closeTo(42.50, 0.01));
      });

      test('zero consumption returns standing charge only', () {
        final result = service.calculateMonthlyCost(
          consumption: 0,
          unitPrice: 0.30,
          standingCharge: 12.50,
          currencySymbol: '€',
        );

        expect(result.unitCost, 0);
        expect(result.standingCost, closeTo(12.50, 0.01));
        expect(result.totalCost, closeTo(12.50, 0.01));
      });

      test('negative consumption is clamped to zero', () {
        final result = service.calculateMonthlyCost(
          consumption: -50,
          unitPrice: 0.30,
          standingCharge: 5.0,
          currencySymbol: '€',
        );

        expect(result.unitCost, 0);
        expect(result.totalCost, closeTo(5.0, 0.01));
      });

      test('standing charge pro-rated for partial month', () {
        final result = service.calculateMonthlyCost(
          consumption: 100,
          unitPrice: 0.30,
          standingCharge: 30.0,
          currencySymbol: '€',
          daysInPeriod: 15,
          daysInMonth: 30,
        );

        expect(result.standingCost, closeTo(15.0, 0.01));
      });

      test('standing charge not pro-rated for full month', () {
        final result = service.calculateMonthlyCost(
          consumption: 100,
          unitPrice: 0.30,
          standingCharge: 30.0,
          currencySymbol: '€',
          daysInPeriod: 30,
          daysInMonth: 30,
        );

        expect(result.standingCost, closeTo(30.0, 0.01));
      });

      test('tiered pricing overrides unit price', () {
        final result = service.calculateMonthlyCost(
          consumption: 150,
          unitPrice: 0.30,
          standingCharge: 0,
          currencySymbol: '€',
          tiers: [
            const PriceTier(limit: 100, rate: 0.28),
            const PriceTier(rate: 0.35),
          ],
        );

        // 100 * 0.28 + 50 * 0.35 = 28 + 17.5 = 45.5
        expect(result.unitCost, closeTo(45.5, 0.01));
      });
    });

    group('calculateWithTiers', () {
      test('two-tier pricing', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(rate: 0.35),
        ];

        final cost = service.calculateWithTiers(150, tiers);
        // 100 * 0.28 + 50 * 0.35 = 28 + 17.5 = 45.5
        expect(cost, closeTo(45.5, 0.01));
      });

      test('three-tier pricing', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(limit: 300, rate: 0.32),
          const PriceTier(rate: 0.35),
        ];

        final cost = service.calculateWithTiers(350, tiers);
        // 100 * 0.28 + 200 * 0.32 + 50 * 0.35 = 28 + 64 + 17.5 = 109.5
        expect(cost, closeTo(109.5, 0.01));
      });

      test('consumption within first tier', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(rate: 0.35),
        ];

        final cost = service.calculateWithTiers(50, tiers);
        // 50 * 0.28 = 14
        expect(cost, closeTo(14.0, 0.01));
      });

      test('consumption exactly at tier limit', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(rate: 0.35),
        ];

        final cost = service.calculateWithTiers(100, tiers);
        // 100 * 0.28 = 28
        expect(cost, closeTo(28.0, 0.01));
      });

      test('zero consumption returns zero', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(rate: 0.35),
        ];

        final cost = service.calculateWithTiers(0, tiers);
        expect(cost, 0);
      });

      test('empty tiers returns zero', () {
        final cost = service.calculateWithTiers(100, []);
        expect(cost, 0);
      });

      test('single unlimited tier', () {
        final tiers = [
          const PriceTier(rate: 0.30),
        ];

        final cost = service.calculateWithTiers(200, tiers);
        expect(cost, closeTo(60.0, 0.01));
      });
    });

    group('parseTiers', () {
      test('parses valid JSON', () {
        final json =
            '[{"limit": 100, "rate": 0.28}, {"limit": 300, "rate": 0.32}, {"rate": 0.35}]';
        final tiers = service.parseTiers(json);

        expect(tiers.length, 3);
        expect(tiers[0].limit, 100);
        expect(tiers[0].rate, 0.28);
        expect(tiers[1].limit, 300);
        expect(tiers[1].rate, 0.32);
        expect(tiers[2].limit, isNull);
        expect(tiers[2].rate, 0.35);
      });

      test('returns empty list for null input', () {
        expect(service.parseTiers(null), isEmpty);
      });

      test('returns empty list for empty string', () {
        expect(service.parseTiers(''), isEmpty);
      });

      test('returns empty list for malformed JSON', () {
        expect(service.parseTiers('not json'), isEmpty);
      });
    });

    group('serializeTiers', () {
      test('serializes tiers to JSON', () {
        final tiers = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(rate: 0.35),
        ];

        final json = service.serializeTiers(tiers);
        expect(json, isNotNull);

        final parsed = jsonDecode(json!) as List;
        expect(parsed.length, 2);
        expect(parsed[0]['limit'], 100);
        expect(parsed[0]['rate'], 0.28);
        expect(parsed[1].containsKey('limit'), isFalse);
        expect(parsed[1]['rate'], 0.35);
      });

      test('returns null for null input', () {
        expect(service.serializeTiers(null), isNull);
      });

      test('returns null for empty list', () {
        expect(service.serializeTiers([]), isNull);
      });

      test('round-trip parse and serialize', () {
        final original = [
          const PriceTier(limit: 100, rate: 0.28),
          const PriceTier(limit: 300, rate: 0.32),
          const PriceTier(rate: 0.35),
        ];

        final json = service.serializeTiers(original);
        final restored = service.parseTiers(json);

        expect(restored.length, original.length);
        for (int i = 0; i < original.length; i++) {
          expect(restored[i].limit, original[i].limit);
          expect(restored[i].rate, original[i].rate);
        }
      });
    });
  });

  group('PriceTier', () {
    test('fromJson with limit', () {
      final tier = PriceTier.fromJson({'limit': 100.0, 'rate': 0.28});
      expect(tier.limit, 100.0);
      expect(tier.rate, 0.28);
    });

    test('fromJson without limit (unlimited)', () {
      final tier = PriceTier.fromJson({'rate': 0.35});
      expect(tier.limit, isNull);
      expect(tier.rate, 0.35);
    });

    test('toJson with limit', () {
      const tier = PriceTier(limit: 100, rate: 0.28);
      final json = tier.toJson();
      expect(json['limit'], 100);
      expect(json['rate'], 0.28);
    });

    test('toJson without limit', () {
      const tier = PriceTier(rate: 0.35);
      final json = tier.toJson();
      expect(json.containsKey('limit'), isFalse);
      expect(json['rate'], 0.35);
    });
  });

  group('CostResult', () {
    test('stores all fields', () {
      const result = CostResult(
        unitCost: 30.0,
        standingCost: 12.50,
        totalCost: 42.50,
        currencySymbol: '€',
      );

      expect(result.unitCost, 30.0);
      expect(result.standingCost, 12.50);
      expect(result.totalCost, 42.50);
      expect(result.currencySymbol, '€');
    });
  });
}
