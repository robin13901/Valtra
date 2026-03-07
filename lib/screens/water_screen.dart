import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/water_provider.dart';
import '../screens/monthly_analytics_screen.dart';
import '../services/analytics/analytics_models.dart';
import '../widgets/dialogs/water_meter_form_dialog.dart';
import '../widgets/dialogs/water_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying water meters with their readings.
class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<WaterProvider>();
    final meters = provider.meters;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.waterMeters,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.water);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MonthlyAnalyticsScreen()),
              );
            },
            tooltip: l10n.analyticsHub,
          ),
          Chip(
            label: Text(l10n.cubicMeters),
            backgroundColor: AppColors.waterColor.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: meters.isEmpty
          ? _buildEmptyState(context, l10n)
          : _WaterMetersList(meters: meters),
      floatingActionButton: buildGlassFAB(
        context: context,
        icon: Icons.add,
        onPressed: () => _addMeter(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noWaterMeters,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMeter(BuildContext context) async {
    final provider = context.read<WaterProvider>();

    final result = await WaterMeterFormDialog.show(context);
    if (result == null || !context.mounted) return;

    await provider.addMeter(result.name, result.type);
  }
}

class _WaterMetersList extends StatelessWidget {
  final List<WaterMeter> meters;

  const _WaterMetersList({required this.meters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meters.length,
      itemBuilder: (context, index) {
        return _WaterMeterCard(meter: meters[index]);
      },
    );
  }
}

class _WaterMeterCard extends StatefulWidget {
  final WaterMeter meter;

  const _WaterMeterCard({required this.meter});

  @override
  State<_WaterMeterCard> createState() => _WaterMeterCardState();
}

class _WaterMeterCardState extends State<_WaterMeterCard> {
  bool _isExpanded = false;

  String _getTypeName(AppLocalizations l10n, WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return l10n.coldWater;
      case WaterMeterType.hot:
        return l10n.hotWater;
      case WaterMeterType.other:
        return l10n.otherWater;
    }
  }

  Color _getTypeColor(WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return AppColors.waterColor;
      case WaterMeterType.hot:
        return AppColors.heatingColor;
      case WaterMeterType.other:
        return AppColors.otherColor;
    }
  }

  IconData _getTypeIcon(WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return Icons.water_drop_outlined;
      case WaterMeterType.hot:
        return Icons.water_drop;
      case WaterMeterType.other:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<WaterProvider>();
    final readings = provider.getReadingsWithDeltas(widget.meter.id);
    final valueFormatter = NumberFormat('#,##0.000', 'en');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Meter header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.meter.type),
                    color: _getTypeColor(widget.meter.type),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meter.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(widget.meter.type)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getTypeName(l10n, widget.meter.type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getTypeColor(widget.meter.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (readings.isNotEmpty)
                              Text(
                                '${valueFormatter.format(readings.first.reading.valueCubicMeters)} m³',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMeter(context);
                      } else if (value == 'delete') {
                        _deleteMeter(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
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
            ),
          ),
          // Expanded readings section
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildReadingsSection(context, l10n, readings),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<WaterReadingWithDelta> readings,
  ) {
    final theme = Theme.of(context);
    final valueFormatter = NumberFormat('#,##0.000', 'en');
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      children: [
        // Add reading button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.waterReadings,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addReading(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addWaterReading),
              ),
            ],
          ),
        ),
        if (readings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noWaterReadings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final readingWithDelta = readings[index];
              final reading = readingWithDelta.reading;
              final delta = readingWithDelta.deltaCubicMeters;

              return ListTile(
                leading: Icon(
                  Icons.water_drop,
                  color: _getTypeColor(widget.meter.type),
                ),
                title: Text(
                  '${valueFormatter.format(reading.valueCubicMeters)} m³',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatter.format(reading.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (delta != null)
                      Text(
                        l10n.waterConsumptionSince(valueFormatter.format(delta)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.waterColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        l10n.firstReading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReading(context, reading);
                    } else if (value == 'delete') {
                      _deleteReading(context, reading);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
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
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _editMeter(BuildContext context) async {
    final provider = context.read<WaterProvider>();

    final result = await WaterMeterFormDialog.show(
      context,
      meter: widget.meter,
    );
    if (result == null || !context.mounted) return;

    await provider.updateMeter(widget.meter.id, result.name, result.type);
  }

  Future<void> _deleteMeter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<WaterProvider>();

    // Get reading count for warning message
    final readingCount = await provider.getReadingCountForMeter(widget.meter.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWaterMeter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteWaterMeterConfirm),
            if (readingCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.waterMeterHasReadings(readingCount),
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
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

    if (confirmed == true && context.mounted) {
      await provider.deleteMeter(widget.meter.id);
    }
  }

  Future<void> _addReading(BuildContext context) async {
    final provider = context.read<WaterProvider>();
    final l10n = AppLocalizations.of(context)!;

    final result = await WaterReadingFormDialog.show(context);
    if (result == null || !context.mounted) return;

    // Validate against previous reading
    final error = await provider.validateReading(
      widget.meter.id,
      result.valueCubicMeters,
      result.timestamp,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waterReadingMustBeGreaterOrEqual(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.addReading(
      widget.meter.id,
      result.timestamp,
      result.valueCubicMeters,
    );
  }

  Future<void> _editReading(BuildContext context, WaterReading reading) async {
    final provider = context.read<WaterProvider>();
    final l10n = AppLocalizations.of(context)!;

    final result = await WaterReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null || !context.mounted) return;

    // Validate against surrounding readings
    final error = await provider.validateReading(
      widget.meter.id,
      result.valueCubicMeters,
      result.timestamp,
      excludeId: reading.id,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waterReadingMustBeGreaterOrEqual(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.updateReading(
      reading.id,
      result.timestamp,
      result.valueCubicMeters,
    );
  }

  Future<void> _deleteReading(BuildContext context, WaterReading reading) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<WaterProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWaterReading),
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

    if (confirmed == true && context.mounted) {
      await provider.deleteReading(reading.id);
    }
  }
}
