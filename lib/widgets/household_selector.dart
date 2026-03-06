import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/household_provider.dart';
import '../screens/households_screen.dart';

/// A dropdown widget for selecting the active household.
///
/// Shows the current selection and allows switching between households.
/// Also provides an option to add a new household.
class HouseholdSelector extends StatelessWidget {
  const HouseholdSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<HouseholdProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final households = provider.households;
        final selected = provider.selectedHousehold;

        if (households.isEmpty) {
          return TextButton.icon(
            onPressed: () => _navigateToHouseholds(context),
            icon: const Icon(Icons.add_home),
            label: Text(l10n.addHousehold),
          );
        }

        return PopupMenuButton<_HouseholdAction>(
          tooltip: l10n.selectHousehold,
          onSelected: (action) => _handleAction(context, action, provider),
          itemBuilder: (context) => [
            // Household list
            ...households.map((h) => PopupMenuItem<_HouseholdAction>(
                  value: _HouseholdAction.select(h.id),
                  child: Row(
                    children: [
                      Icon(
                        h.id == selected?.id
                            ? Icons.home
                            : Icons.home_outlined,
                        size: 20,
                        color: h.id == selected?.id
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h.name,
                          overflow: TextOverflow.ellipsis,
                          style: h.id == selected?.id
                              ? TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                      if (h.id == selected?.id)
                        Icon(
                          Icons.check,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                )),
            const PopupMenuDivider(),
            // Manage households option
            PopupMenuItem<_HouseholdAction>(
              value: const _HouseholdAction.manage(),
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.households),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    selected?.name ?? l10n.selectHousehold,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    _HouseholdAction action,
    HouseholdProvider provider,
  ) {
    switch (action) {
      case _SelectHousehold(id: final id):
        provider.selectHousehold(id);
      case _ManageHouseholds():
        _navigateToHouseholds(context);
    }
  }

  void _navigateToHouseholds(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HouseholdsScreen()),
    );
  }
}

/// Action types for the household selector popup menu.
sealed class _HouseholdAction {
  const _HouseholdAction();

  const factory _HouseholdAction.select(int id) = _SelectHousehold;
  const factory _HouseholdAction.manage() = _ManageHouseholds;
}

class _SelectHousehold extends _HouseholdAction {
  final int id;
  const _SelectHousehold(this.id);
}

class _ManageHouseholds extends _HouseholdAction {
  const _ManageHouseholds();
}
