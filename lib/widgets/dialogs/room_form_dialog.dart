import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a room.
///
/// When [room] is null, the dialog operates in create mode.
/// When [room] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class RoomFormDialog extends StatefulWidget {
  final Room? room;

  const RoomFormDialog({super.key, this.room});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<RoomFormData?> show(
    BuildContext context, {
    Room? room,
  }) {
    return showDialog<RoomFormData>(
      context: context,
      builder: (context) => RoomFormDialog(room: room),
    );
  }

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool get isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? '');
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
      title: Text(isEditing ? l10n.editRoom : l10n.addRoom),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.roomName,
            hintText: l10n.roomNameHint,
          ),
          maxLength: 100,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.roomNameRequired;
            }
            if (value.length > 100) {
              return l10n.roomNameTooLong;
            }
            return null;
          },
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
      Navigator.of(context).pop(RoomFormData(name: name));
    }
  }
}

/// Data returned from [RoomFormDialog] when saved.
class RoomFormData {
  final String name;

  const RoomFormData({required this.name});
}
