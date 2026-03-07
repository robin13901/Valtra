import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

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
  late DateTime _selectedMonth;

  bool get isEditing => widget.consumption != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.consumption?.valueKwh.toString() ?? '',
    );
    if (widget.consumption != null) {
      _selectedMonth = widget.consumption!.month;
    } else {
      final now = DateTime.now();
      _selectedMonth = DateTime(now.year, now.month, 1);
    }
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
            // Month picker
            InkWell(
              onTap: _selectMonth,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.monthly,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(_formatMonth(_selectedMonth)),
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

  String _formatMonth(DateTime dt) {
    return DateFormat.yMMMM().format(dt);
  }

  Future<void> _selectMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 31)),
    );
    if (date == null || !mounted) return;

    setState(() {
      // Normalize to 1st of month at 00:00
      _selectedMonth = DateTime(date.year, date.month, 1);
    });
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text.trim());

      Navigator.of(context).pop(SmartPlugConsumptionFormData(
        month: _selectedMonth,
        valueKwh: value,
      ));
    }
  }
}

/// Data returned from [SmartPlugConsumptionFormDialog] when saved.
class SmartPlugConsumptionFormData {
  final DateTime month;
  final double valueKwh;

  const SmartPlugConsumptionFormData({
    required this.month,
    required this.valueKwh,
  });
}
