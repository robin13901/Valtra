import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/number_format_service.dart';
import '../liquid_glass_widgets.dart';

class YearlySummaryCard extends StatelessWidget {
  final int year;
  final double? totalConsumption;
  final double? totalCost;
  final double? extrapolatedTotal;
  final int? extrapolationBasisMonths;
  final double? previousYearTotal;
  final double? previousYearTotalCost;
  final String unit;
  final String? currencySymbol;
  final Color color;
  final String locale;

  const YearlySummaryCard({
    super.key,
    required this.year,
    this.totalConsumption,
    this.totalCost,
    this.extrapolatedTotal,
    this.extrapolationBasisMonths,
    this.previousYearTotal,
    this.previousYearTotalCost,
    required this.unit,
    this.currencySymbol,
    required this.color,
    this.locale = 'de',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        children: [
          Text(
            l10n.totalForYear(year.toString()),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          // Total consumption
          Text(
            totalConsumption != null
                ? '${ValtraNumberFormat.consumption(totalConsumption!, locale)} $unit'
                : '—',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Total cost
          if (totalCost != null && currencySymbol != null) ...[
            const SizedBox(height: 4),
            Text(
              '${ValtraNumberFormat.consumption(totalCost!, locale)} $currencySymbol',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          // Extrapolated year-end projection
          if (extrapolatedTotal != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_flat, size: 16, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  l10n.projectedTotal(
                    '${ValtraNumberFormat.consumption(extrapolatedTotal!, locale)} $unit',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (extrapolationBasisMonths != null) ...[
              const SizedBox(height: 2),
              Text(
                l10n.basedOnMonths(extrapolationBasisMonths!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
          // Year-over-year change
          if (totalConsumption != null &&
              previousYearTotal != null &&
              previousYearTotal! > 0) ...[
            const SizedBox(height: 8),
            _buildYoyChange(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildYoyChange(BuildContext context, AppLocalizations l10n) {
    final change =
        ((totalConsumption! - previousYearTotal!) / previousYearTotal!) * 100;
    final changeStr = change >= 0
        ? '+${change.toStringAsFixed(1)}'
        : change.toStringAsFixed(1);
    final isIncrease = change > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIncrease ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: isIncrease
              ? Theme.of(context).colorScheme.error
              : Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          l10n.changeFromLastYear(changeStr),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isIncrease
                    ? Theme.of(context).colorScheme.error
                    : Colors.green,
              ),
        ),
      ],
    );
  }
}
