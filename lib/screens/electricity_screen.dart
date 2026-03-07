import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/electricity_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/monthly_analytics_screen.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/models.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/electricity_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying electricity readings with add/edit/delete functionality.
class ElectricityScreen extends StatelessWidget {
  const ElectricityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ElectricityProvider>();
    final items = provider.displayItems;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.electricity,
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
              context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.electricity);
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
                    unit: l10n.kWh,
                  );
                }
                return _ReadingCard(
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
            Icons.electric_meter_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noElectricityReadings,
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
    final provider = context.read<ElectricityProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await ElectricityReadingFormDialog.show(context);
    if (result == null) return;

    // Validate against previous reading
    final validationError = await provider.validateReading(
      result.valueKwh,
      result.timestamp,
    );

    if (validationError != null && context.mounted) {
      // Show error dialog
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.readingMustBeGreaterOrEqual(
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

    await provider.addReading(result.timestamp, result.valueKwh);
  }

  Future<void> _editReading(BuildContext context, int readingId) async {
    final provider = context.read<ElectricityProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final reading = provider.readings.firstWhere((r) => r.id == readingId);

    final result = await ElectricityReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null) return;

    // Validate against previous/next readings
    final validationError = await provider.validateReading(
      result.valueKwh,
      result.timestamp,
      excludeId: reading.id,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.readingMustBeGreaterOrEqual(
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

    await provider.updateReading(reading.id, result.timestamp, result.valueKwh);
  }

  Future<void> _deleteReading(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ElectricityProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteElectricityReading),
        content: Text(l10n.deleteReadingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteReading(readingId);
    }
  }
}

/// Card displaying a single electricity reading.
class _ReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReadingCard({
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
                    Icons.electric_bolt,
                    color: AppColors.electricityColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ValtraNumberFormat.consumption(item.value, locale)} ${l10n.kWh}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.delta != null)
                Text(
                  l10n.consumptionSince(ValtraNumberFormat.consumption(item.delta!, locale)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.electricityColor,
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

  const _InterpolatedReadingCard({
    required this.item,
    required this.unit,
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
                  Icons.electric_bolt,
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
