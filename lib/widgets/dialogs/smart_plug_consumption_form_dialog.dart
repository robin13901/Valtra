import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/tables.dart';

/// Dialog for creating or editing a smart plug consumption entry.
///
/// When [consumption] is null, the dialog operates in create mode.
/// When [consumption] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class SmartPlugConsumptionFormDialog extends StatefulWidget {
  final SmartPlugConsumption? consumption;

  const SmartPlugConsumptionFormDialog({super.key, this.consumption});

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<SmartPlugConsumptionFormData?> show(
    BuildContext context, {
    SmartPlugConsumption? consumption,
  }) {
    return showDialog<SmartPlugConsumptionFormData>(
      context: context,
      builder: (context) =>
          SmartPlugConsumptionFormDialog(consumption: consumption),
    );
  }

  @override
  State<SmartPlugConsumptionFormDialog> createState() =>
      _SmartPlugConsumptionFormDialogState();
}

class _SmartPlugConsumptionFormDialogState
    extends State<SmartPlugConsumptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late ConsumptionInterval _selectedInterval;
  late DateTime _selectedDate;

  bool get isEditing => widget.consumption != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.consumption?.valueKwh.toString() ?? '',
    );
    _selectedInterval =
        widget.consumption?.intervalType ?? ConsumptionInterval.monthly;
    _selectedDate = widget.consumption?.intervalStart ?? DateTime.now();
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
      title: Text(isEditing ? l10n.editConsumption : l10n.addConsumption),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interval type dropdown
            DropdownButtonFormField<ConsumptionInterval>(
              initialValue: _selectedInterval,
              decoration: InputDecoration(
                labelText: l10n.intervalType,
              ),
              items: ConsumptionInterval.values.map((interval) {
                return DropdownMenuItem(
                  value: interval,
                  child: Text(_getIntervalLabel(l10n, interval)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedInterval = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.intervalStart,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            // Value input
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                suffixText: l10n.kWh,
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
                if (parsed == null || parsed <= 0) {
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

  String _getIntervalLabel(AppLocalizations l10n, ConsumptionInterval interval) {
    switch (interval) {
      case ConsumptionInterval.daily:
        return l10n.daily;
      case ConsumptionInterval.weekly:
        return l10n.weekly;
      case ConsumptionInterval.monthly:
        return l10n.monthly;
      case ConsumptionInterval.yearly:
        return l10n.yearly;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = date;
    });
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text.trim());

      Navigator.of(context).pop(SmartPlugConsumptionFormData(
        intervalType: _selectedInterval,
        intervalStart: _selectedDate,
        valueKwh: value,
      ));
    }
  }
}

/// Data returned from [SmartPlugConsumptionFormDialog] when saved.
class SmartPlugConsumptionFormData {
  final ConsumptionInterval intervalType;
  final DateTime intervalStart;
  final double valueKwh;

  const SmartPlugConsumptionFormData({
    required this.intervalType,
    required this.intervalStart,
    required this.valueKwh,
  });
}
