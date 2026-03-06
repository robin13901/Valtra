import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/electricity_provider.dart';
import '../widgets/dialogs/electricity_reading_form_dialog.dart';

/// Screen displaying electricity readings with add/edit/delete functionality.
class ElectricityScreen extends StatelessWidget {
  const ElectricityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ElectricityProvider>();
    final readings = provider.readingsWithDeltas;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.electricity),
        actions: [
          Chip(
            label: Text(l10n.kWh),
            backgroundColor: AppColors.electricityColor.withValues(alpha: 0.2),
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
                return _ReadingCard(
                  reading: item.reading,
                  deltaKwh: item.deltaKwh,
                  onTap: () => _editReading(context, item.reading),
                  onDelete: () => _deleteReading(context, item.reading),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addReading(context),
        child: const Icon(Icons.add),
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
          content: Text(l10n.readingMustBeGreaterOrEqual(validationError)),
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

  Future<void> _editReading(
    BuildContext context,
    ElectricityReading reading,
  ) async {
    final provider = context.read<ElectricityProvider>();
    final l10n = AppLocalizations.of(context)!;

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
          content: Text(l10n.readingMustBeGreaterOrEqual(validationError)),
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

  Future<void> _deleteReading(
    BuildContext context,
    ElectricityReading reading,
  ) async {
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
      await provider.deleteReading(reading.id);
    }
  }
}

/// Card displaying a single electricity reading.
class _ReadingCard extends StatelessWidget {
  final ElectricityReading reading;
  final double? deltaKwh;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReadingCard({
    required this.reading,
    this.deltaKwh,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    final valueFormatter = NumberFormat('#,##0.0', 'en');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    Icons.electric_bolt,
                    color: AppColors.electricityColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${valueFormatter.format(reading.valueKwh)} ${l10n.kWh}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (deltaKwh != null)
                Text(
                  l10n.consumptionSince(valueFormatter.format(deltaKwh)),
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
