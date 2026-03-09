import 'package:intl/intl.dart';

/// Centralized locale-aware number, time, and date formatting for Valtra.
///
/// All methods accept a locale string ('de' or 'en') to produce
/// correctly formatted output for the user's selected language.
class ValtraNumberFormat {
  ValtraNumberFormat._();

  /// Format a consumption value with 1 decimal place.
  ///
  /// DE: "1.234,5" | EN: "1,234.5"
  static String consumption(double value, String locale) {
    final formatter = NumberFormat('#,##0.0', locale);
    return formatter.format(value);
  }

  /// Format a water meter reading with 3 decimal places.
  ///
  /// DE: "12,345" | EN: "12.345"
  static String waterReading(double value, String locale) {
    final formatter = NumberFormat('#,##0.000', locale);
    return formatter.format(value);
  }

  /// Format a currency value with 2 decimal places.
  ///
  /// DE: "78,50" | EN: "78.50"
  static String currency(double value, String locale) {
    final formatter = NumberFormat('#,##0.00', locale);
    return formatter.format(value);
  }

  /// Format a time value.
  ///
  /// DE: "9:43 Uhr" | EN: "09:43"
  static String time(DateTime dt, String locale) {
    if (locale == 'de') {
      final formatter = DateFormat('H:mm', locale);
      return '${formatter.format(dt)} Uhr';
    } else {
      final formatter = DateFormat('HH:mm', locale);
      return formatter.format(dt);
    }
  }

  /// Format a date with full month name and year.
  ///
  /// DE: "März 2026" | EN: "March 2026"
  static String date(DateTime dt, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    return formatter.format(dt);
  }

  /// Format month and year (same as date).
  ///
  /// DE: "März 2026" | EN: "March 2026"
  static String monthYear(DateTime dt, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    return formatter.format(dt);
  }

  /// Format a date and time value.
  ///
  /// DE: "09.03.2026, 14:30 Uhr" | EN: "09.03.2026, 14:30"
  static String dateTime(DateTime dt, String locale) {
    final datePart = DateFormat('dd.MM.yyyy', locale).format(dt);
    final timePart = DateFormat('HH:mm', locale).format(dt);
    if (locale == 'de') {
      return '$datePart, $timePart Uhr';
    } else {
      return '$datePart, $timePart';
    }
  }
}
