import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a heating reading.
///
/// When [reading] is null, the dialog operates in create mode.
/// When [reading] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class HeatingReadingFormDialog extends StatefulWidget {
  final HeatingReading? reading;

  const HeatingReadingFormDialog({super.key, this.reading});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<HeatingReadingFormData?> show(
    BuildContext context, {
    HeatingReading? reading,
  }) {
    return showDialog<HeatingReadingFormData>(
      context: context,
      builder: (context) => HeatingReadingFormDialog(reading: reading),
    );
  }

  @override
  State<HeatingReadingFormDialog> createState() =>
      _HeatingReadingFormDialogState();
}

class _HeatingReadingFormDialogState extends State<HeatingReadingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late DateTime _selectedDateTime;
  String? _externalError;

  bool get isEditing => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.reading?.value.toString() ?? '',
    );
    _selectedDateTime = widget.reading?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
          isEditing ? l10n.editHeatingReading : l10n.addHeatingReading),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.dateAndTime),
              subtitle: Text(_formatDateTime(_selectedDateTime)),
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.meterValue,
                hintText: l10n.meterValueHint,
                errorText: _externalError,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: !isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.readingMustBePositive;
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) {
                  return l10n.readingMustBePositive;
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _onSave() {
    setState(() => _externalError = null);

    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text.trim());

      Navigator.of(context).pop(HeatingReadingFormData(
        timestamp: _selectedDateTime,
        value: value,
      ));
    }
  }
}

/// Data returned from [HeatingReadingFormDialog] when saved.
class HeatingReadingFormData {
  final DateTime timestamp;
  final double value;

  const HeatingReadingFormData({
    required this.timestamp,
    required this.value,
  });
}
