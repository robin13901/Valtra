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
  static const int _startYear = 2020;
  static const double _kItemExtent = 40.0;
  static const double _kWheelHeight = 130.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final FixedExtentScrollController _monthScrollController;
  late final FixedExtentScrollController _yearScrollController;
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
    _monthScrollController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearScrollController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  /// Checks for duplicate month entry when month/year selection changes.
  Future<void> _checkDuplicate() async {
    if (widget.onCheckDuplicate == null) {
      setState(() => _duplicateWarning = false);
      return;
    }

    final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);

    if (isEditing && widget.consumption!.month == selectedDate) {
      setState(() => _duplicateWarning = false);
      return;
    }

    final isDuplicate = await widget.onCheckDuplicate!(selectedDate);
    if (mounted) {
      setState(() => _duplicateWarning = isDuplicate);
    }
  }

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) labelBuilder,
    required ValueChanged<int> onSelectedItemChanged,
    required int selectedIndex,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogBg =
        theme.dialogTheme.backgroundColor ?? colorScheme.surface;

    return Container(
      height: _kWheelHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        color: colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: _kItemExtent,
              diameterRatio: 1.5,
              perspective: 0.003,
              magnification: 1.05,
              useMagnifier: true,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onSelectedItemChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: itemCount,
                builder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return Center(
                    child: Text(
                      labelBuilder(index),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                    ),
                  );
                },
              ),
            ),
            // Selection highlight band
            IgnorePointer(
              child: Center(
                child: Container(
                  height: _kItemExtent,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top fade
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: _kWheelHeight * 0.35,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [dialogBg, dialogBg.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom fade
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: _kWheelHeight * 0.35,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [dialogBg, dialogBg.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final yearCount = DateTime.now().year - _startYear + 2;

    return AlertDialog(
      title: Text(isEditing ? l10n.editConsumption : l10n.addConsumption),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectMonth,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildWheelPicker(
                    controller: _monthScrollController,
                    itemCount: 12,
                    selectedIndex: _selectedMonth - 1,
                    labelBuilder: (index) {
                      final date = DateTime(2024, index + 1, 15);
                      return DateFormat.MMMM(locale).format(date);
                    },
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMonth = index + 1);
                      _checkDuplicate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildWheelPicker(
                    controller: _yearScrollController,
                    itemCount: yearCount,
                    selectedIndex: _selectedYear - _startYear,
                    labelBuilder: (index) => (_startYear + index).toString(),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedYear = _startYear + index);
                      _checkDuplicate();
                    },
                  ),
                ),
              ],
            ),
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
