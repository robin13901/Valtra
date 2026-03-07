import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/gas_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/monthly_analytics_screen.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/models.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/gas_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying gas readings with add/edit/delete functionality.
class GasScreen extends StatelessWidget {
  const GasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<GasProvider>();
    final items = provider.displayItems;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.gas,
        actions: [
          IconButton(
            icon: Icon(
              provider.showInterpolatedValues
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: () => provider.toggleInterpolatedValues(),
            tooltip: provider.showInterpolatedValues
                ? l10n.hideInterpolatedValues
                : l10n.showInterpolatedValues,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.gas);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MonthlyAnalyticsScreen()),
              );
            },
            tooltip: l10n.analyticsHub,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isInterpolated) {
                  return _InterpolatedReadingCard(
                    item: item,
                    unit: l10n.cubicMeters,
                    icon: Icons.local_fire_department,
                  );
                }
                return _GasReadingCard(
                  item: item,
                  onTap: () => _editReading(context, item.readingId!),
                  onDelete: () => _deleteReading(context, item.readingId!),
                );
              },
            ),
      floatingActionButton: buildGlassFAB(
        context: context,
        icon: Icons.add,
        onPressed: () => _addReading(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noGasReadings,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addReading(BuildContext context) async {
    final provider = context.read<GasProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await GasReadingFormDialog.show(context);
    if (result == null) return;

    final validationError = await provider.validateReading(
      result.valueCubicMeters,
      result.timestamp,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content:
              Text(l10n.gasReadingMustBeGreaterOrEqual(
                  ValtraNumberFormat.consumption(validationError, locale))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    await provider.addReading(result.timestamp, result.valueCubicMeters);
  }

  Future<void> _editReading(BuildContext context, int readingId) async {
    final provider = context.read<GasProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final reading = provider.readings.firstWhere((r) => r.id == readingId);

    final result = await GasReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null) return;

    final validationError = await provider.validateReading(
      result.valueCubicMeters,
      result.timestamp,
      excludeId: reading.id,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content:
              Text(l10n.gasReadingMustBeGreaterOrEqual(
                  ValtraNumberFormat.consumption(validationError, locale))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    await provider.updateReading(
        reading.id, result.timestamp, result.valueCubicMeters);
  }

  Future<void> _deleteReading(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<GasProvider>();

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: l10n.gasReading,
    );

    if (confirmed) {
      await provider.deleteReading(readingId);
    }
  }
}

/// Card displaying a single gas reading.
class _GasReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GasReadingCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormatter.format(item.timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.delete,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.gasColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ValtraNumberFormat.consumption(item.value, locale)} ${l10n.cubicMeters}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.delta != null)
                Text(
                  l10n.gasConsumptionSince(
                      ValtraNumberFormat.consumption(item.delta!, locale)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.gasColor,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  l10n.firstReading,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displaying an interpolated reading value (non-editable).
class _InterpolatedReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final String unit;
  final IconData icon;

  const _InterpolatedReadingCard({
    required this.item,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      color: AppColors.ultraViolet.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormatter.format(item.timestamp),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ultraViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.interpolated,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ultraViolet,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.ultraViolet.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${ValtraNumberFormat.consumption(item.value, locale)} $unit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
