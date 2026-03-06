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
            Text(
              l10n.waterMeterType,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<WaterMeterType>(
              segments: [
                ButtonSegment(
                  value: WaterMeterType.cold,
                  label: Text(l10n.coldWater),
                  icon: const Icon(Icons.water_drop_outlined),
                ),
                ButtonSegment(
                  value: WaterMeterType.hot,
                  label: Text(l10n.hotWater),
                  icon: const Icon(Icons.water_drop),
                ),
                ButtonSegment(
                  value: WaterMeterType.other,
                  label: Text(l10n.otherWater),
                  icon: const Icon(Icons.category_outlined),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                });
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
