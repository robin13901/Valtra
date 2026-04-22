import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a smart plug.
///
/// When [plug] is null, the dialog operates in create mode.
/// When [plug] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class SmartPlugFormDialog extends StatefulWidget {
  final SmartPlug? plug;
  final List<Room> rooms;
  final int? initialRoomId;

  const SmartPlugFormDialog({
    super.key,
    this.plug,
    required this.rooms,
    this.initialRoomId,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<SmartPlugFormData?> show(
    BuildContext context, {
    SmartPlug? plug,
    required List<Room> rooms,
    int? initialRoomId,
  }) {
    return showDialog<SmartPlugFormData>(
      context: context,
      builder: (context) => SmartPlugFormDialog(
        plug: plug,
        rooms: rooms,
        initialRoomId: initialRoomId,
      ),
    );
  }

  @override
  State<SmartPlugFormDialog> createState() => _SmartPlugFormDialogState();
}

class _SmartPlugFormDialogState extends State<SmartPlugFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedRoomId;

  bool get isEditing => widget.plug != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plug?.name ?? '');
    _selectedRoomId =
        widget.plug?.roomId ?? widget.initialRoomId;
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
      title: Text(isEditing ? l10n.editSmartPlug : l10n.addSmartPlug),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.smartPlugName,
              ),
              maxLength: 100,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.smartPlugNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedRoomId,
              decoration: InputDecoration(
                labelText: l10n.selectRoom,
              ),
              items: widget.rooms.map((room) {
                return DropdownMenuItem(
                  value: room.id,
                  child: Text(room.name),
                );
              }).toList(),
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
      Navigator.of(context).pop(SmartPlugFormData(
        name: name,
        roomId: _selectedRoomId!,
      ));
    }
  }
}

/// Data returned from [SmartPlugFormDialog] when saved.
class SmartPlugFormData {
  final String name;
  final int roomId;

  const SmartPlugFormData({required this.name, required this.roomId});
}
