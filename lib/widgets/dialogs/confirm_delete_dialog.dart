import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A shared delete confirmation dialog used across all screens.
///
/// Displays a localized "Delete {item}?" title with a warning message,
/// and returns `true` if the user confirms deletion.
class ConfirmDeleteDialog extends StatelessWidget {
  final String itemLabel;

  const ConfirmDeleteDialog({super.key, required this.itemLabel});

  /// Shows the confirmation dialog and returns `true` if confirmed.
  static Future<bool> show(BuildContext context, {required String itemLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(itemLabel: itemLabel),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.deleteConfirmTitle(itemLabel)),
      content: Text(l10n.deleteCannotUndo),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
