import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// A month navigation widget with left/right chevrons and formatted month text.
///
/// Replaces the duplicate `_YearNavigationHeader` from electricity/gas/water/heating screens.
/// Defaults to current month, disables forward navigation past the current month.
class MonthSelector extends StatelessWidget {
  /// The currently selected month (day component is ignored; only year+month matter).
  final DateTime selectedMonth;

  /// Called when the user taps the left or right chevron.
  /// Receives a DateTime with the first day of the newly selected month.
  final ValueChanged<DateTime> onMonthChanged;

  /// Locale string for formatting the month name (e.g., 'de', 'en').
  final String locale;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    this.locale = 'de',
  });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // DateFormat.yMMMM produces "April 2026" (en) or "April 2026" (de)
    final monthText = DateFormat.yMMMM(locale).format(selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onMonthChanged(
            DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
          ),
          tooltip: l10n.previousMonth,
        ),
        Expanded(
          child: Text(
            monthText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _isCurrentMonth
              ? null
              : () => onMonthChanged(
                    DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
                  ),
          tooltip: l10n.nextMonth,
        ),
      ],
    );
  }
}
