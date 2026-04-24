import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/household_provider.dart';
import '../widgets/dialogs/household_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen for managing households.
///
/// Displays a list of all households with options to:
/// - Create new households
/// - Edit existing households
/// - Delete households (with confirmation)
class HouseholdsScreen extends StatelessWidget {
  const HouseholdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Consumer<HouseholdProvider>(
            builder: (context, provider, child) {
              final households = provider.households;

              if (households.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: liquidGlassAppBarHeight(context)),
                  child: _buildEmptyState(context, l10n),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, liquidGlassAppBarHeight(context) + 16, 16, 16),
                itemCount: households.length,
                itemBuilder: (context, index) {
                  final household = households[index];
                  return _HouseholdCard(
                    household: household,
                    isSelected: household.id == provider.selectedHouseholdId,
                  );
                },
              );
            },
          ),
          buildLiquidGlassAppBar(context, title: l10n.households),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        tooltip: l10n.createHousehold,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noHouseholds,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createHousehold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await HouseholdFormDialog.show(context);
    if (result != null && context.mounted) {
      final provider = context.read<HouseholdProvider>();
      await provider.createHousehold(
        result.name,
        description: result.description,
        personCount: result.personCount,
      );
    }
  }
}

class _HouseholdCard extends StatelessWidget {
  final Household household;
  final bool isSelected;

  const _HouseholdCard({
    required this.household,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showEditDialog(context),
        onLongPress: () => _showDeleteConfirmation(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                foregroundColor:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                child: const Icon(Icons.home),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                    ),
                    if (household.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        household.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditDialog(context);
                    case 'delete':
                      _showDeleteConfirmation(context);
                    case 'select':
                      _selectHousehold(context);
                  }
                },
                itemBuilder: (context) => [
                  if (!isSelected)
                    PopupMenuItem<String>(
                      value: 'select',
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.selectHousehold),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: colorScheme.error),
                        const SizedBox(width: 12),
                        Text(l10n.delete,
                            style: TextStyle(color: colorScheme.error)),
                      ],
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

  void _selectHousehold(BuildContext context) {
    context.read<HouseholdProvider>().selectHousehold(household.id);
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await HouseholdFormDialog.show(context, household: household);
    if (result != null && context.mounted) {
      final provider = context.read<HouseholdProvider>();
      await provider.updateHousehold(
        household.id,
        result.name,
        description: result.description,
        personCount: result.personCount,
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<HouseholdProvider>();

    // Check for related data first
    final hasData = await provider.hasRelatedData(household.id);

    if (!context.mounted) return;

    if (hasData) {
      // Show error dialog - cannot delete
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cannotDeleteHousehold),
          content: Text(l10n.householdHasRelatedData),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHousehold),
        content: Text(l10n.deleteHouseholdConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteHousehold(household.id);
    }
  }
}
