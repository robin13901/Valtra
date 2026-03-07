import 'dart:convert';

/// A single pricing tier for tiered cost calculation.
class PriceTier {
  final double? limit;
  final double rate;

  const PriceTier({this.limit, required this.rate});

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
        limit: (json['limit'] as num?)?.toDouble(),
        rate: (json['rate'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (limit != null) 'limit': limit,
        'rate': rate,
      };
}

/// Result of a cost calculation for a period.
class CostResult {
  final double unitCost;
  final double standingCost;
  final double totalCost;
  final String currencySymbol;

  const CostResult({
    required this.unitCost,
    required this.standingCost,
    required this.totalCost,
    required this.currencySymbol,
  });
}

/// Pure business logic for cost calculation.
///
/// Takes consumption + config, returns cost. No DB or UI dependencies.
class CostCalculationService {
  const CostCalculationService();

  /// Calculate cost for a consumption period.
  CostResult calculateMonthlyCost({
    required double consumption,
    required double unitPrice,
    required double standingCharge,
    required String currencySymbol,
    List<PriceTier>? tiers,
    int daysInPeriod = 30,
    int daysInMonth = 30,
  }) {
    final clampedConsumption = consumption < 0 ? 0.0 : consumption;

    final double unitCost;
    if (tiers != null && tiers.isNotEmpty) {
      unitCost = calculateWithTiers(clampedConsumption, tiers);
    } else {
      unitCost = clampedConsumption * unitPrice;
    }

    final double standingCost;
    if (daysInMonth > 0 && daysInPeriod != daysInMonth) {
      standingCost = standingCharge * (daysInPeriod / daysInMonth);
    } else {
      standingCost = standingCharge;
    }

    return CostResult(
      unitCost: unitCost,
      standingCost: standingCost,
      totalCost: unitCost + standingCost,
      currencySymbol: currencySymbol,
    );
  }

  /// Apply tiered pricing to consumption.
  ///
  /// Tiers are cumulative: first X units at rate A, next Y at rate B, rest at rate C.
  /// Example: tiers = [{limit: 100, rate: 0.28}, {limit: 300, rate: 0.32}, {rate: 0.35}]
  /// For 350 kWh: (100 × 0.28) + (200 × 0.32) + (50 × 0.35) = €109.50
  double calculateWithTiers(double consumption, List<PriceTier> tiers) {
    if (tiers.isEmpty || consumption <= 0) return 0.0;

    var remaining = consumption;
    var cost = 0.0;
    var previousLimit = 0.0;

    for (final tier in tiers) {
      if (remaining <= 0) break;

      if (tier.limit != null) {
        final tierSize = tier.limit! - previousLimit;
        final consumed = remaining < tierSize ? remaining : tierSize;
        cost += consumed * tier.rate;
        remaining -= consumed;
        previousLimit = tier.limit!;
      } else {
        // Last tier (unlimited)
        cost += remaining * tier.rate;
        remaining = 0;
      }
    }

    // If there's remaining consumption beyond all tiers with limits,
    // use the last tier's rate
    if (remaining > 0 && tiers.isNotEmpty) {
      cost += remaining * tiers.last.rate;
    }

    return cost;
  }

  /// Parse price tiers from JSON string.
  List<PriceTier> parseTiers(String? tiersJson) {
    if (tiersJson == null || tiersJson.isEmpty) return [];
    try {
      final list = jsonDecode(tiersJson) as List<dynamic>;
      return list
          .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Serialize price tiers to JSON string.
  String? serializeTiers(List<PriceTier>? tiers) {
    if (tiers == null || tiers.isEmpty) return null;
    return jsonEncode(tiers.map((t) => t.toJson()).toList());
  }
}
