import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a water reading.
///
/// When [reading] is null, the dialog operates in create mode.
/// When [reading] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class WaterReadingFormDialog extends StatefulWidget {
  final WaterReading? reading;

  const WaterReadingFormDialog({super.key, this.reading});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<WaterReadingFormData?> show(
    BuildContext context, {
    WaterReading? reading,
  }) {
    return showDialog<WaterReadingFormData>(
      context: context,
      builder: (context) => WaterReadingFormDialog(reading: reading),
    );
  }

  @override
  State<WaterReadingFormDialog> createState() => _WaterReadingFormDialogState();
}

class _WaterReadingFormDialogState extends State<WaterReadingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late DateTime _selectedDateTime;
  String? _externalError;

  bool get isEditing => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.reading?.valueCubicMeters.toString() ?? '',
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
      title: Text(isEditing ? l10n.editWaterReading : l10n.addWaterReading),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.dateAndTime),
              subtitle: Text(_formatDateTime(_selectedDateTime)),
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 16),
            // Value input
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.meterValue,
                hintText: l10n.meterValueHint,
                suffixText: l10n.cubicMeters,
                errorText: _externalError,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

      Navigator.of(context).pop(WaterReadingFormData(
        timestamp: _selectedDateTime,
        valueCubicMeters: value,
      ));
    }
  }

  /// Sets an external error message (e.g., from validation against previous reading).
  void setExternalError(String? error) {
    setState(() => _externalError = error);
  }
}

/// Data returned from [WaterReadingFormDialog] when saved.
class WaterReadingFormData {
  final DateTime timestamp;
  final double valueCubicMeters;

  const WaterReadingFormData({
    required this.timestamp,
    required this.valueCubicMeters,
  });
}
