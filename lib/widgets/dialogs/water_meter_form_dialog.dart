import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/tables.dart';

/// Dialog for creating or editing a water meter.
///
/// When [meter] is null, the dialog operates in create mode.
/// When [meter] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class WaterMeterFormDialog extends StatefulWidget {
  final WaterMeter? meter;

  const WaterMeterFormDialog({super.key, this.meter});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<WaterMeterFormData?> show(
    BuildContext context, {
    WaterMeter? meter,
  }) {
    return showDialog<WaterMeterFormData>(
      context: context,
      builder: (context) => WaterMeterFormDialog(meter: meter),
    );
  }

  @override
  State<WaterMeterFormDialog> createState() => _WaterMeterFormDialogState();
}

class _WaterMeterFormDialogState extends State<WaterMeterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late WaterMeterType _selectedType;

  bool get isEditing => widget.meter != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meter?.name ?? '');
    _selectedType = widget.meter?.type ?? WaterMeterType.cold;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? l10n.editWaterMeter : l10n.addWaterMeter),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.waterMeterName,
                hintText: l10n.waterMeterNameHint,
              ),
              autofocus: !isEditing,
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.waterMeterNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Type selection
            DropdownButtonFormField<WaterMeterType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.waterMeterType,
              ),
              items: [
                DropdownMenuItem(
                  value: WaterMeterType.cold,
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(l10n.coldWater),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: WaterMeterType.hot,
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.hotWater),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: WaterMeterType.other,
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(l10n.otherWater),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
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
      Navigator.of(context).pop(WaterMeterFormData(
        name: _nameController.text.trim(),
        type: _selectedType,
      ));
    }
  }
}

/// Data returned from [WaterMeterFormDialog] when saved.
class WaterMeterFormData {
  final String name;
  final WaterMeterType type;

  const WaterMeterFormData({
    required this.name,
    required this.type,
  });
}
