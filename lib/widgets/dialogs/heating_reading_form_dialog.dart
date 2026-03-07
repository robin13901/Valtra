import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import 'reading_form_base.dart';

/// Dialog for creating or editing a heating reading.
///
/// When [reading] is null, the dialog operates in create mode.
/// When [reading] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
///
/// [previousValue] shows the previous reading as reference and enables
/// real-time validation (value must be >= previous).
/// [nextValue] is used in edit mode to validate the upper bound.
class HeatingReadingFormDialog extends StatefulWidget {
  final HeatingReading? reading;
  final double? previousValue;
  final double? nextValue;
  final Future<void> Function(HeatingReadingFormData data)? onSaveCallback;

  const HeatingReadingFormDialog({
    super.key,
    this.reading,
    this.previousValue,
    this.nextValue,
    this.onSaveCallback,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<HeatingReadingFormData?> show(
    BuildContext context, {
    HeatingReading? reading,
    double? previousValue,
    double? nextValue,
    Future<void> Function(HeatingReadingFormData data)? onSaveCallback,
  }) {
    return showDialog<HeatingReadingFormData>(
      context: context,
      builder: (context) => HeatingReadingFormDialog(
        reading: reading,
        previousValue: previousValue,
        nextValue: nextValue,
        onSaveCallback: onSaveCallback,
      ),
    );
  }

  @override
  State<HeatingReadingFormDialog> createState() =>
      _HeatingReadingFormDialogState();
}

class _HeatingReadingFormDialogState extends State<HeatingReadingFormDialog>
    with QuickEntryMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late DateTime _selectedDateTime;
  String? _externalError;
  String? _validationError;

  @override
  bool get isEditMode => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.reading?.value.toString() ?? '',
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

  @override
  void clearValueField() {
    _valueController.clear();
    setState(() {
      _validationError = null;
      _externalError = null;
    });
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
      error = l10n.readingTooLow('${widget.previousValue!}');
    }
    if (widget.nextValue != null && parsed > widget.nextValue!) {
      error = 'Must be <= ${widget.nextValue!}';
    }

    setState(() => _validationError = error);
  }

  bool get _hasValidationError => _validationError != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(quickEntryTitle(
        l10n,
        l10n.addHeatingReading,
        l10n.editHeatingReading,
      )),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  l10n.previousReading('${widget.previousValue!}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.meterValue,
                errorText: _validationError ?? _externalError,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: !isEditMode,
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
            buildSuccessIndicator(l10n),
          ],
        ),
      ),
      actions: buildQuickEntryActions(
        l10n,
        onSavePressed: _hasValidationError ? null : _onSave,
        onCancelPressed: () => Navigator.of(context).pop(null),
      ),
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
      final data = HeatingReadingFormData(
        timestamp: _selectedDateTime,
        value: value,
      );

      if (widget.onSaveCallback != null) {
        await widget.onSaveCallback!(data);
      }

      if (handlePostSave()) {
        setState(() {
          _selectedDateTime = DateTime.now();
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pop(data);
      }
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
