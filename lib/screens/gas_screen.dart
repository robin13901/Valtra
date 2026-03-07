import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/gas_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/monthly_analytics_screen.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/gas_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying gas readings with add/edit/delete functionality.
class GasScreen extends StatelessWidget {
  const GasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<GasProvider>();
    final readings = provider.readingsWithDeltas;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.gas,
        actions: [
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
          Chip(
            label: Text(l10n.cubicMeters),
            backgroundColor: AppColors.gasColor.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: readings.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final item = readings[index];
                return _GasReadingCard(
                  reading: item.reading,
                  deltaCubicMeters: item.deltaCubicMeters,
                  onTap: () => _editReading(context, item.reading),
                  onDelete: () => _deleteReading(context, item.reading),
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

    // Validate against previous reading
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

  Future<void> _editReading(
    BuildContext context,
    GasReading reading,
  ) async {
    final provider = context.read<GasProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await GasReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null) return;

    // Validate against previous/next readings
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

  Future<void> _deleteReading(
    BuildContext context,
    GasReading reading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<GasProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteGasReading),
        content: Text(l10n.deleteGasReadingConfirm),
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
      await provider.deleteReading(reading.id);
    }
  }
}

/// Card displaying a single gas reading.
class _GasReadingCard extends StatelessWidget {
  final GasReading reading;
  final double? deltaCubicMeters;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GasReadingCard({
    required this.reading,
    this.deltaCubicMeters,
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
                      dateFormatter.format(reading.timestamp),
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
                    '${ValtraNumberFormat.consumption(reading.valueCubicMeters, locale)} ${l10n.cubicMeters}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (deltaCubicMeters != null)
                Text(
                  l10n.gasConsumptionSince(
                      ValtraNumberFormat.consumption(deltaCubicMeters!, locale)),
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
