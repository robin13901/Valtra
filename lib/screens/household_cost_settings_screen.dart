import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/cost_config_provider.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/cost_profile_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'package:drift/drift.dart' hide Column;

/// Screen for managing cost profiles per meter type (electricity, gas, water).
///
/// Shows expandable cards for each [CostMeterType] with cost profile
/// sub-entries. Users can add, edit, and delete cost profiles.
class HouseholdCostSettingsScreen extends StatelessWidget {
  const HouseholdCostSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(0, liquidGlassAppBarHeight(context) + 8, 0, 8),
            children: CostMeterType.values
                .map((type) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _CostMeterTypeCard(meterType: type),
                    ))
                .toList(),
          ),
          buildLiquidGlassAppBar(context, title: l10n.costProfiles),
        ],
      ),
    );
  }
}

class _CostMeterTypeCard extends StatefulWidget {
  final CostMeterType meterType;
  const _CostMeterTypeCard({required this.meterType});

  @override
  State<_CostMeterTypeCard> createState() => _CostMeterTypeCardState();
}

class _CostMeterTypeCardState extends State<_CostMeterTypeCard> {
  bool _isExpanded = false;

  String _meterTypeLabel(AppLocalizations l10n) {
    switch (widget.meterType) {
      case CostMeterType.electricity:
        return l10n.electricity;
      case CostMeterType.gas:
        return l10n.gas;
      case CostMeterType.water:
        return l10n.water;
    }
  }

  IconData _meterTypeIcon() {
    switch (widget.meterType) {
      case CostMeterType.electricity:
        return Icons.electric_bolt;
      case CostMeterType.gas:
        return Icons.local_fire_department;
      case CostMeterType.water:
        return Icons.water_drop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final costProvider = context.watch<CostConfigProvider>();
    final configs = costProvider.getConfigsForMeterType(widget.meterType);

    return GlassCard(
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(_meterTypeIcon(), color: AppColors.ultraViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _meterTypeLabel(l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addProfile(context, l10n, costProvider),
                  tooltip: l10n.addCostProfile,
                  iconSize: 20,
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (configs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.noCostProfiles,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...configs.map((config) => _buildProfileTile(
                    context, l10n, config, costProvider,
                  )),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    AppLocalizations l10n,
    CostConfig config,
    CostConfigProvider costProvider,
  ) {
    final dateStr =
        '${config.validFrom.day.toString().padLeft(2, '0')}.${config.validFrom.month.toString().padLeft(2, '0')}.${config.validFrom.year}';
    final basePriceStr =
        ValtraNumberFormat.currency(config.standingCharge, 'de');
    final unitPriceStr = ValtraNumberFormat.currency(config.unitPrice, 'de');

    return ListTile(
      title: Text(l10n.profileValidFrom(dateStr)),
      subtitle: Text(
        '${l10n.annualBasePrice}: \u20AC$basePriceStr \u00B7 ${l10n.unitPrice}: \u20AC$unitPriceStr/${widget.meterType == CostMeterType.water ? 'm\u00B3' : 'kWh'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editProfile(context, l10n, costProvider, config);
              } else if (value == 'delete') {
                _deleteProfile(context, l10n, costProvider, config);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(l10n.edit),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addProfile(
    BuildContext context,
    AppLocalizations l10n,
    CostConfigProvider costProvider,
  ) async {
    final result = await CostProfileFormDialog.show(
      context,
      meterType: widget.meterType,
      householdId: costProvider.householdId!,
    );
    if (result != null) {
      await costProvider.addConfig(CostConfigsCompanion.insert(
        householdId: costProvider.householdId!,
        meterType: widget.meterType,
        unitPrice: result.energyPrice,
        standingCharge: Value(result.annualBasePrice),
        validFrom: result.validFrom,
      ));
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    AppLocalizations l10n,
    CostConfigProvider costProvider,
    CostConfig config,
  ) async {
    final result = await CostProfileFormDialog.show(
      context,
      config: config,
      meterType: widget.meterType,
      householdId: costProvider.householdId!,
    );
    if (result != null) {
      await costProvider.updateConfig(config.copyWith(
        unitPrice: result.energyPrice,
        standingCharge: result.annualBasePrice,
        validFrom: result.validFrom,
      ));
    }
  }

  Future<void> _deleteProfile(
    BuildContext context,
    AppLocalizations l10n,
    CostConfigProvider costProvider,
    CostConfig config,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCostConfig),
        content: Text(l10n.deleteCannotUndo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await costProvider.deleteConfig(config.id);
    }
  }
}
