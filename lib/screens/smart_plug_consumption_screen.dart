import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/smart_plug_provider.dart';
import '../widgets/dialogs/smart_plug_consumption_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen showing consumption history for a specific smart plug.
class SmartPlugConsumptionScreen extends StatefulWidget {
  final int smartPlugId;

  const SmartPlugConsumptionScreen({super.key, required this.smartPlugId});

  @override
  State<SmartPlugConsumptionScreen> createState() =>
      _SmartPlugConsumptionScreenState();
}

class _SmartPlugConsumptionScreenState
    extends State<SmartPlugConsumptionScreen> {
  SmartPlug? _plug;
  Room? _room;

  @override
  void initState() {
    super.initState();
    _loadPlugAndRoom();
  }

  Future<void> _loadPlugAndRoom() async {
    final provider = context.read<SmartPlugProvider>();
    final plug = await provider.getSmartPlug(widget.smartPlugId);
    final room = await provider.getRoomForSmartPlug(widget.smartPlugId);
    if (mounted) {
      setState(() {
        _plug = plug;
        _room = room;
      });
    }
  }

  String _getIntervalName(AppLocalizations l10n, ConsumptionInterval interval) {
    switch (interval) {
      case ConsumptionInterval.daily:
        return l10n.daily;
      case ConsumptionInterval.weekly:
        return l10n.weekly;
      case ConsumptionInterval.monthly:
        return l10n.monthly;
      case ConsumptionInterval.yearly:
        return l10n.yearly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<SmartPlugProvider>();

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: _room != null
            ? '${_plug?.name ?? '...'} - ${_room!.name}'
            : _plug?.name ?? '...',
      ),
      body: _plug == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ConsumptionWithLabel>>(
              stream: provider.watchConsumptionsForPlug(
                widget.smartPlugId,
                (interval) => _getIntervalName(l10n, interval),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final consumptions = snapshot.data!;
                if (consumptions.isEmpty) {
                  return _buildEmptyState(context, l10n);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: consumptions.length,
                  itemBuilder: (context, index) {
                    final item = consumptions[index];
                    return _ConsumptionCard(
                      consumption: item,
                      getIntervalName: (interval) =>
                          _getIntervalName(l10n, interval),
                      onTap: () =>
                          _editConsumption(context, item.consumption),
                      onDelete: () =>
                          _deleteConsumption(context, item.consumption),
                    );
                  },
                );
              },
            ),
      floatingActionButton: buildGlassFAB(
        context: context,
        icon: Icons.add,
        onPressed: () => _addConsumption(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noConsumption,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addConsumption(BuildContext context) async {
    final provider = context.read<SmartPlugProvider>();

    final result = await SmartPlugConsumptionFormDialog.show(context);
    if (result == null) return;

    await provider.addConsumption(
      widget.smartPlugId,
      result.intervalType,
      result.intervalStart,
      result.valueKwh,
    );
  }

  Future<void> _editConsumption(
    BuildContext context,
    SmartPlugConsumption consumption,
  ) async {
    final provider = context.read<SmartPlugProvider>();

    final result = await SmartPlugConsumptionFormDialog.show(
      context,
      consumption: consumption,
    );
    if (result == null || !context.mounted) return;

    await provider.updateConsumption(
      consumption.id,
      result.intervalType,
      result.intervalStart,
      result.valueKwh,
    );
  }

  Future<void> _deleteConsumption(
    BuildContext context,
    SmartPlugConsumption consumption,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SmartPlugProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConsumption),
        content: Text(l10n.deleteConsumptionConfirm),
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
      await provider.deleteConsumption(consumption.id);
    }
  }
}

class _ConsumptionCard extends StatelessWidget {
  final ConsumptionWithLabel consumption;
  final String Function(ConsumptionInterval) getIntervalName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConsumptionCard({
    required this.consumption,
    required this.getIntervalName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, yyyy');
    final valueFormatter = NumberFormat('#,##0.0', 'en');

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
                    Icons.bar_chart,
                    color: AppColors.electricityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      getIntervalName(consumption.consumption.intervalType),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              const SizedBox(height: 4),
              Text(
                dateFormatter.format(consumption.consumption.intervalStart),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                    '${valueFormatter.format(consumption.consumption.valueKwh)} ${l10n.kWh}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
