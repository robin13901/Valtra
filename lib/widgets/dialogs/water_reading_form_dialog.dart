import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Dialog for creating or editing a water reading.
///
/// When [reading] is null, the dialog operates in create mode.
/// When [reading] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
///
/// [previousValue] shows the previous reading as reference and enables
/// real-time validation (value must be >= previous).
/// [nextValue] is used in edit mode to validate the upper bound.
class WaterReadingFormDialog extends StatefulWidget {
  final WaterReading? reading;
  final double? previousValue;
  final double? nextValue;
  final Future<void> Function(WaterReadingFormData data)? onSaveCallback;

  const WaterReadingFormDialog({
    super.key,
    this.reading,
    this.previousValue,
    this.nextValue,
    this.onSaveCallback,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<WaterReadingFormData?> show(
    BuildContext context, {
    WaterReading? reading,
    double? previousValue,
    double? nextValue,
    Future<void> Function(WaterReadingFormData data)? onSaveCallback,
  }) {
    return showDialog<WaterReadingFormData>(
      context: context,
      builder: (context) => WaterReadingFormDialog(
        reading: reading,
        previousValue: previousValue,
        nextValue: nextValue,
        onSaveCallback: onSaveCallback,
      ),
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
  String? _validationError;

  bool get _isEditMode => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.reading?.valueCubicMeters.toString() ?? '',
    );
    _valueController.addListener(_onValueChanged);
    _selectedDateTime = widget.reading?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _valueController.removeListener(_onValueChanged);
    _valueController.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    final text = _valueController.text.trim();
    if (text.isEmpty) {
      setState(() => _validationError = null);
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) return;

    final l10n = AppLocalizations.of(context)!;
    String? error;

    if (widget.previousValue != null && parsed < widget.previousValue!) {
      error = l10n.readingTooLow('${widget.previousValue!} m\u00B3');
    }
    if (widget.nextValue != null && parsed > widget.nextValue!) {
      error = 'Must be <= ${widget.nextValue!} m\u00B3';
    }

    setState(() => _validationError = error);
  }

  bool get _hasValidationError => _validationError != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        _isEditMode ? l10n.editWaterReading : l10n.addWaterReading,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time picker
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateAndTime,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(_formatDateTime(_selectedDateTime)),
              ),
            ),
            const SizedBox(height: 16),
            // Previous value reference
            if (widget.previousValue != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.previousReading('${widget.previousValue!} m\u00B3'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            // Value input
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.meterValue,
                suffixText: l10n.cubicMeters,
                errorText: _validationError ?? _externalError,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: !_isEditMode,
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
          onPressed: _hasValidationError ? null : _onSave,
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

  Future<void> _onSave() async {
    setState(() => _externalError = null);

    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text.trim());
      final data = WaterReadingFormData(
        timestamp: _selectedDateTime,
        valueCubicMeters: value,
      );

      if (widget.onSaveCallback != null) {
        await widget.onSaveCallback!(data);
      }

      if (mounted) {
        Navigator.of(context).pop(data);
      }
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
