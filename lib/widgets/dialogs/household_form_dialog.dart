import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a household.
///
/// When [household] is null, the dialog operates in create mode.
/// When [household] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class HouseholdFormDialog extends StatefulWidget {
  final Household? household;

  const HouseholdFormDialog({super.key, this.household});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<HouseholdFormData?> show(
    BuildContext context, {
    Household? household,
  }) {
    return showDialog<HouseholdFormData>(
      context: context,
      builder: (context) => HouseholdFormDialog(household: household),
    );
  }

  @override
  State<HouseholdFormDialog> createState() => _HouseholdFormDialogState();
}

class _HouseholdFormDialogState extends State<HouseholdFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool get isEditing => widget.household != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.household?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.household?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? l10n.editHousehold : l10n.createHousehold),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.householdName,
                hintText: l10n.householdName,
              ),
              maxLength: 100,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.householdRequired;
                }
                if (value.length > 100) {
                  return l10n.householdNameTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.householdDescription,
                hintText: l10n.householdDescription,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      Navigator.of(context).pop(HouseholdFormData(
        name: name,
        description: description.isEmpty ? null : description,
      ));
    }
  }
}

/// Data returned from [HouseholdFormDialog] when saved.
class HouseholdFormData {
  final String name;
  final String? description;

  const HouseholdFormData({required this.name, this.description});
}
