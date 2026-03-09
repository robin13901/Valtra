import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valtra/services/number_format_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  group('ValtraNumberFormat', () {
    group('consumption (1 decimal place)', () {
      test('formats 1234.5 for de locale', () {
        expect(ValtraNumberFormat.consumption(1234.5, 'de'), '1.234,5');
      });

      test('formats 1234.5 for en locale', () {
        expect(ValtraNumberFormat.consumption(1234.5, 'en'), '1,234.5');
      });

      test('formats zero for de locale', () {
        expect(ValtraNumberFormat.consumption(0.0, 'de'), '0,0');
      });

      test('formats zero for en locale', () {
        expect(ValtraNumberFormat.consumption(0.0, 'en'), '0.0');
      });

      test('formats negative value for de locale', () {
        expect(ValtraNumberFormat.consumption(-42.3, 'de'), '-42,3');
      });

      test('formats negative value for en locale', () {
        expect(ValtraNumberFormat.consumption(-42.3, 'en'), '-42.3');
      });

      test('formats very large number for de locale', () {
        expect(
            ValtraNumberFormat.consumption(1234567.8, 'de'), '1.234.567,8');
      });

      test('formats very large number for en locale', () {
        expect(
            ValtraNumberFormat.consumption(1234567.8, 'en'), '1,234,567.8');
      });

      test('rounds to 1 decimal place', () {
        expect(ValtraNumberFormat.consumption(1.999, 'en'), '2.0');
      });
    });

    group('waterReading (3 decimal places)', () {
      test('formats 12.345 for de locale', () {
        expect(ValtraNumberFormat.waterReading(12.345, 'de'), '12,345');
      });

      test('formats 12.345 for en locale', () {
        expect(ValtraNumberFormat.waterReading(12.345, 'en'), '12.345');
      });

      test('formats zero for de locale', () {
        expect(ValtraNumberFormat.waterReading(0.0, 'de'), '0,000');
      });

      test('formats zero for en locale', () {
        expect(ValtraNumberFormat.waterReading(0.0, 'en'), '0.000');
      });

      test('formats value with trailing zeros for de locale', () {
        expect(ValtraNumberFormat.waterReading(5.1, 'de'), '5,100');
      });

      test('formats large water reading for en locale', () {
        expect(
            ValtraNumberFormat.waterReading(12345.678, 'en'), '12,345.678');
      });

      test('formats large water reading for de locale', () {
        expect(
            ValtraNumberFormat.waterReading(12345.678, 'de'), '12.345,678');
      });
    });

    group('currency (2 decimal places)', () {
      test('formats 78.5 for de locale', () {
        expect(ValtraNumberFormat.currency(78.5, 'de'), '78,50');
      });

      test('formats 78.5 for en locale', () {
        expect(ValtraNumberFormat.currency(78.5, 'en'), '78.50');
      });

      test('formats zero for de locale', () {
        expect(ValtraNumberFormat.currency(0.0, 'de'), '0,00');
      });

      test('formats zero for en locale', () {
        expect(ValtraNumberFormat.currency(0.0, 'en'), '0.00');
      });

      test('formats large currency for de locale', () {
        expect(ValtraNumberFormat.currency(1234.56, 'de'), '1.234,56');
      });

      test('formats large currency for en locale', () {
        expect(ValtraNumberFormat.currency(1234.56, 'en'), '1,234.56');
      });

      test('rounds to 2 decimal places', () {
        expect(ValtraNumberFormat.currency(9.999, 'en'), '10.00');
      });
    });

    group('time', () {
      test('formats 9:43 for de locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 3, 7, 9, 43), 'de'),
          '9:43 Uhr',
        );
      });

      test('formats 9:43 for en locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 3, 7, 9, 43), 'en'),
          '09:43',
        );
      });

      test('formats midnight for de locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 1, 1, 0, 0), 'de'),
          '0:00 Uhr',
        );
      });

      test('formats midnight for en locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 1, 1, 0, 0), 'en'),
          '00:00',
        );
      });

      test('formats 23:59 for de locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 12, 31, 23, 59), 'de'),
          '23:59 Uhr',
        );
      });

      test('formats 23:59 for en locale', () {
        expect(
          ValtraNumberFormat.time(DateTime(2026, 12, 31, 23, 59), 'en'),
          '23:59',
        );
      });
    });

    group('date', () {
      test('formats March 2026 for de locale', () {
        final result = ValtraNumberFormat.date(DateTime(2026, 3, 7), 'de');
        // German month name for March
        expect(result, contains('2026'));
        expect(result, contains('März'));
      });

      test('formats March 2026 for en locale', () {
        final result = ValtraNumberFormat.date(DateTime(2026, 3, 7), 'en');
        expect(result, contains('2026'));
        expect(result, contains('March'));
      });

      test('formats January 2026 for de locale', () {
        final result = ValtraNumberFormat.date(DateTime(2026, 1, 15), 'de');
        expect(result, contains('Januar'));
      });

      test('formats December 2026 for en locale', () {
        final result = ValtraNumberFormat.date(DateTime(2026, 12, 25), 'en');
        expect(result, contains('December'));
      });
    });

    group('monthYear', () {
      test('formats March 2026 for de locale', () {
        final result =
            ValtraNumberFormat.monthYear(DateTime(2026, 3, 7), 'de');
        expect(result, contains('März'));
        expect(result, contains('2026'));
      });

      test('formats March 2026 for en locale', () {
        final result =
            ValtraNumberFormat.monthYear(DateTime(2026, 3, 7), 'en');
        expect(result, contains('March'));
        expect(result, contains('2026'));
      });

      test('formats July 2025 for de locale', () {
        final result =
            ValtraNumberFormat.monthYear(DateTime(2025, 7, 1), 'de');
        expect(result, contains('Juli'));
        expect(result, contains('2025'));
      });

      test('formats July 2025 for en locale', () {
        final result =
            ValtraNumberFormat.monthYear(DateTime(2025, 7, 1), 'en');
        expect(result, contains('July'));
        expect(result, contains('2025'));
      });
    });

    group('dateTime', () {
      test('formats date and time for de locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 3, 9, 14, 30), 'de'),
          '09.03.2026, 14:30 Uhr',
        );
      });

      test('formats date and time for en locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 3, 9, 14, 30), 'en'),
          '09.03.2026, 14:30',
        );
      });

      test('formats midnight for de locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 1, 1, 0, 0), 'de'),
          '01.01.2026, 00:00 Uhr',
        );
      });

      test('formats single-digit hour for de locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 3, 9, 9, 5), 'de'),
          '09.03.2026, 09:05 Uhr',
        );
      });

      test('formats single-digit hour for en locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 3, 9, 9, 5), 'en'),
          '09.03.2026, 09:05',
        );
      });

      test('formats end of day for de locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 12, 31, 23, 59), 'de'),
          '31.12.2026, 23:59 Uhr',
        );
      });

      test('formats end of day for en locale', () {
        expect(
          ValtraNumberFormat.dateTime(DateTime(2026, 12, 31, 23, 59), 'en'),
          '31.12.2026, 23:59',
        );
      });
    });
  });
}
