import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';

/// Data returned from [SmartPlugConsumptionFormDialog] when saved.
class SmartPlugConsumptionFormData {
  final DateTime month;
  final double valueKwh;

  const SmartPlugConsumptionFormData({
    required this.month,
    required this.valueKwh,
  });
}

/// Callback to check if an entry already exists for the selected month.
/// Returns true if a duplicate exists.
typedef DuplicateMonthChecker = Future<bool> Function(DateTime month);

/// Dialog for creating or editing a smart plug consumption entry.
///
/// When [consumption] is null, the dialog operates in create mode.
/// When [consumption] is provided, the dialog operates in edit mode
/// and pre-fills the form with existing values.
class SmartPlugConsumptionFormDialog extends StatefulWidget {
  final SmartPlugConsumption? consumption;
  final DuplicateMonthChecker? onCheckDuplicate;

  const SmartPlugConsumptionFormDialog({
    super.key,
    this.consumption,
    this.onCheckDuplicate,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<SmartPlugConsumptionFormData?> show(
    BuildContext context, {
    SmartPlugConsumption? consumption,
    DuplicateMonthChecker? onCheckDuplicate,
  }) {
    return showDialog<SmartPlugConsumptionFormData>(
      context: context,
      builder: (context) => SmartPlugConsumptionFormDialog(
        consumption: consumption,
        onCheckDuplicate: onCheckDuplicate,
      ),
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
  late int _selectedMonth;
  late int _selectedYear;
  bool _duplicateWarning = false;

  bool get isEditing => widget.consumption != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.consumption?.valueKwh.toString() ?? '',
    );
    if (widget.consumption != null) {
      _selectedMonth = widget.consumption!.month.month;
      _selectedYear = widget.consumption!.month.year;
    } else {
      final now = DateTime.now();
      _selectedMonth = now.month;
      _selectedYear = now.year;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Generates localized month names for the dropdown.
  List<DropdownMenuItem<int>> _buildMonthItems(String locale) {
    return List.generate(12, (index) {
      final month = index + 1;
      // Create a date for the 15th of each month to format the month name
      final date = DateTime(2024, month, 15);
      final formatter = DateFormat.MMMM(locale);
      return DropdownMenuItem<int>(
        value: month,
        child: Text(formatter.format(date)),
      );
    });
  }

  /// Generates year items for the dropdown: 2020 to current year + 1.
  List<DropdownMenuItem<int>> _buildYearItems() {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - 2020 + 2,
      (index) {
        final year = 2020 + index;
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString()),
        );
      },
    );
  }

  /// Checks for duplicate month entry when month/year selection changes.
  Future<void> _checkDuplicate() async {
    if (widget.onCheckDuplicate == null) {
      setState(() => _duplicateWarning = false);
      return;
    }

    final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);

    // Don't warn when editing the same month
    if (isEditing && widget.consumption!.month == selectedDate) {
      setState(() => _duplicateWarning = false);
      return;
    }

    final isDuplicate = await widget.onCheckDuplicate!(selectedDate);
    if (mounted) {
      setState(() => _duplicateWarning = isDuplicate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return AlertDialog(
      title: Text(isEditing ? l10n.editConsumption : l10n.addConsumption),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month/Year picker label
            Text(
              l10n.selectMonth,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            // Month and Year dropdowns in a row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    items: _buildMonthItems(locale),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedMonth = value;
                        _checkDuplicate();
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    items: _buildYearItems(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedYear = value;
                        _checkDuplicate();
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Duplicate warning
            if (_duplicateWarning) ...[
              const SizedBox(height: 8),
              Text(
                l10n.entryExistsForMonth,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text.trim());

      Navigator.of(context).pop(SmartPlugConsumptionFormData(
        month: DateTime(_selectedYear, _selectedMonth, 1),
        valueKwh: value,
      ));
    }
  }
}
