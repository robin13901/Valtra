import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Mixin for reading form dialog states that adds quick entry ("Save & Next")
/// functionality alongside the normal "Save" button.
///
/// Subclasses must:
/// - Call [quickEntryTitle] to get the dialog title with entry count
/// - Call [buildQuickEntryActions] to get action buttons
/// - Implement [onSave] to handle saving and returning data
/// - Implement [clearValueField] to reset the value input after "Save & Next"
mixin QuickEntryMixin<T extends StatefulWidget> on State<T> {
  int _entryCount = 0;
  bool _showSuccessIndicator = false;

  /// Current count of saved entries in this session.
  int get entryCount => _entryCount;

  /// Whether the success indicator should be shown.
  bool get showSuccessIndicator => _showSuccessIndicator;

  /// Whether the dialog is in edit mode (no quick entry in edit mode).
  bool get isEditMode;

  /// Returns the dialog title with entry count when in add mode.
  ///
  /// [baseAddTitle] is the normal "Add Reading" title.
  /// [editTitle] is the "Edit Reading" title for edit mode.
  String quickEntryTitle(AppLocalizations l10n, String baseAddTitle, String editTitle) {
    if (isEditMode) return editTitle;
    if (_entryCount > 0) {
      return l10n.addReadingCount(_entryCount.toString());
    }
    return baseAddTitle;
  }

  /// Builds the action buttons: Cancel, Save & Next (add mode only), Save.
  List<Widget> buildQuickEntryActions(
    AppLocalizations l10n, {
    required VoidCallback? onSavePressed,
    required VoidCallback? onCancelPressed,
  }) {
    return [
      TextButton(
        onPressed: onCancelPressed,
        child: Text(l10n.cancel),
      ),
      if (!isEditMode)
        TextButton(
          onPressed: onSavePressed != null ? () => _onSaveAndNext(onSavePressed) : null,
          child: Text(l10n.saveAndNext),
        ),
      FilledButton(
        onPressed: onSavePressed,
        child: Text(l10n.save),
      ),
    ];
  }

  void _onSaveAndNext(VoidCallback onSave) {
    // Store the callback - onSave should validate and save
    _pendingSaveAndNext = true;
    onSave();
  }

  bool _pendingSaveAndNext = false;

  /// Call this after a successful save to handle "Save & Next" behavior.
  /// Returns true if the dialog should stay open (Save & Next was pressed).
  bool handlePostSave() {
    if (_pendingSaveAndNext) {
      _pendingSaveAndNext = false;
      setState(() {
        _entryCount++;
        _showSuccessIndicator = true;
      });
      clearValueField();
      // Hide success indicator after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showSuccessIndicator = false);
        }
      });
      return true; // Stay open
    }
    return false; // Close dialog
  }

  /// Clears the value input field for the next entry.
  void clearValueField();

  /// Builds a success indicator widget shown briefly after "Save & Next".
  Widget buildSuccessIndicator(AppLocalizations l10n) {
    if (!_showSuccessIndicator) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            l10n.saved,
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
