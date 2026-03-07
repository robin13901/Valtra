import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/tables.dart';

/// Dialog for creating or editing a heating meter.
///
/// When [meter] is null, the dialog operates in create mode.
/// When [meter] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class HeatingMeterFormDialog extends StatefulWidget {
  final HeatingMeter? meter;
  final List<Room> rooms;

  const HeatingMeterFormDialog({
    super.key,
    this.meter,
    required this.rooms,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<HeatingMeterFormData?> show(
    BuildContext context, {
    HeatingMeter? meter,
    required List<Room> rooms,
  }) {
    return showDialog<HeatingMeterFormData>(
      context: context,
      builder: (context) => HeatingMeterFormDialog(
        meter: meter,
        rooms: rooms,
      ),
    );
  }

  @override
  State<HeatingMeterFormDialog> createState() =>
      _HeatingMeterFormDialogState();
}

class _HeatingMeterFormDialogState extends State<HeatingMeterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedRoomId;
  HeatingType _heatingType = HeatingType.ownMeter;
  final TextEditingController _ratioController = TextEditingController();

  bool get isEditing => widget.meter != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meter?.name ?? '');
    _selectedRoomId = widget.meter?.roomId ??
        (widget.rooms.isNotEmpty ? widget.rooms.first.id : null);
    if (widget.meter != null) {
      _heatingType = widget.meter!.heatingType;
      if (widget.meter!.heatingRatio != null) {
        _ratioController.text =
            (widget.meter!.heatingRatio! * 100).toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
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
        child: SingleChildScrollView(
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
              if (widget.rooms.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _selectedRoomId,
                  decoration: InputDecoration(
                    labelText: l10n.room,
                  ),
                  items: widget.rooms
                      .map((room) => DropdownMenuItem(
                            value: room.id,
                            child: Text(room.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedRoomId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return l10n.roomRequired;
                    }
                    return null;
                  },
                ),
            ],
          ),
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
      final ratioText = _ratioController.text.trim();
      double? ratio;
      if (ratioText.isNotEmpty) {
        ratio = double.tryParse(ratioText);
        if (ratio != null) ratio = ratio / 100.0;
      }
      Navigator.of(context).pop(HeatingMeterFormData(
        name: _nameController.text.trim(),
        roomId: _selectedRoomId!,
        heatingType: _heatingType,
        heatingRatio: _heatingType == HeatingType.centralMeter ? ratio : null,
      ));
    }
  }
}

/// Data returned from [HeatingMeterFormDialog] when saved.
class HeatingMeterFormData {
  final String name;
  final int roomId;
  final HeatingType heatingType;
  final double? heatingRatio;

  const HeatingMeterFormData({
    required this.name,
    required this.roomId,
    this.heatingType = HeatingType.ownMeter,
    this.heatingRatio,
  });
}
