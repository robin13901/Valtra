import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/number_format_service.dart';
import '../liquid_glass_widgets.dart';

/// A summary card showing total consumption for a selected month with
/// percentage change vs the previous month.
///
/// Replaces the duplicate `_YearlySummaryCard` from electricity/gas/water/heating screens.
/// Satisfies requirement SUMM-01.
class MonthlySummaryCard extends StatelessWidget {
  /// Total consumption for the selected month (null if no data).
  final double? totalConsumption;

  /// Total consumption for the previous month (used for % change calculation).
  final double? previousMonthTotal;

  /// Display unit (e.g., 'kWh', 'm³').
  final String unit;

  /// The selected month (for display in the card header).
  final DateTime month;

  /// The color accent for the consumption value text.
  final Color color;

  /// Locale for number/date formatting.
  final String locale;

  /// Optional smart plug kWh tracked (for electricity screens).
  /// Renders a coverage line only when both [smartPlugKwh] and [smartPlugPercent] are non-null.
  final double? smartPlugKwh;

  /// Optional smart plug coverage percentage (0-100).
  /// Renders a coverage line only when both [smartPlugKwh] and [smartPlugPercent] are non-null.
  final double? smartPlugPercent;

  const MonthlySummaryCard({
    super.key,
    required this.totalConsumption,
    required this.previousMonthTotal,
    required this.unit,
    required this.month,
    required this.color,
    this.locale = 'de',
    this.smartPlugKwh,
    this.smartPlugPercent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthName = DateFormat.yMMMM(locale).format(month);

    return GlassCard(
      child: Column(
        children: [
          Text(
            l10n.totalForMonth(monthName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            totalConsumption != null
                ? '${ValtraNumberFormat.consumption(totalConsumption!, locale)} $unit'
                : '\u2014',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (totalConsumption != null &&
              previousMonthTotal != null &&
              previousMonthTotal! > 0) ...[
            const SizedBox(height: 8),
            _buildChangeText(context, l10n),
          ],
          if (smartPlugKwh != null && smartPlugPercent != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.power, size: 14, color: AppColors.electricityColor),
                const SizedBox(width: 4),
                Text(
                  l10n.smartPlugCoverage(
                    ValtraNumberFormat.consumption(smartPlugKwh!, locale),
                    smartPlugPercent!.toStringAsFixed(1),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.electricityColor,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeText(BuildContext context, AppLocalizations l10n) {
    final change =
        ((totalConsumption! - previousMonthTotal!) / previousMonthTotal!) * 100;
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
          l10n.changeFromLastMonth(changeStr),
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
