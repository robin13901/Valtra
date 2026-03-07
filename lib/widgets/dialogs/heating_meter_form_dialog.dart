import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a heating meter.
///
/// When [meter] is null, the dialog operates in create mode.
/// When [meter] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class HeatingMeterFormDialog extends StatefulWidget {
  final HeatingMeter? meter;

  const HeatingMeterFormDialog({super.key, this.meter});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<HeatingMeterFormData?> show(
    BuildContext context, {
    HeatingMeter? meter,
  }) {
    return showDialog<HeatingMeterFormData>(
      context: context,
      builder: (context) => HeatingMeterFormDialog(meter: meter),
    );
  }

  @override
  State<HeatingMeterFormDialog> createState() =>
      _HeatingMeterFormDialogState();
}

class _HeatingMeterFormDialogState extends State<HeatingMeterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;

  bool get isEditing => widget.meter != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meter?.name ?? '');
    _locationController =
        TextEditingController(text: widget.meter?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title:
          Text(isEditing ? l10n.editHeatingMeter : l10n.addHeatingMeter),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.heatingMeterName,
                hintText: l10n.heatingMeterNameHint,
              ),
              autofocus: !isEditing,
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.heatingMeterNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.heatingMeterLocation,
                hintText: l10n.heatingMeterLocationHint,
              ),
              maxLength: 100,
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
      final location = _locationController.text.trim();
      Navigator.of(context).pop(HeatingMeterFormData(
        name: _nameController.text.trim(),
        location: location.isEmpty ? null : location,
      ));
    }
  }
}

/// Data returned from [HeatingMeterFormDialog] when saved.
class HeatingMeterFormData {
  final String name;
  final String? location;

  const HeatingMeterFormData({
    required this.name,
    this.location,
  });
}
