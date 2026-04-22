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
  int? _selectedRoomId;

  bool get isEditing => widget.meter != null;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.meter?.roomId ??
        (widget.rooms.isNotEmpty ? widget.rooms.first.id : null);
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
      Navigator.of(context).pop(HeatingMeterFormData(
        roomId: _selectedRoomId!,
      ));
    }
  }
}

/// Data returned from [HeatingMeterFormDialog] when saved.
class HeatingMeterFormData {
  final int roomId;

  const HeatingMeterFormData({
    required this.roomId,
  });
}
