import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/charts/month_selector.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  Widget buildTestWidget({
    required DateTime selectedMonth,
    required ValueChanged<DateTime> onMonthChanged,
    String locale = 'de',
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(
        body: MonthSelector(
          selectedMonth: selectedMonth,
          onMonthChanged: onMonthChanged,
          locale: locale,
        ),
      ),
    );
  }

  group('MonthSelector', () {
    testWidgets('displays formatted month and year text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2026, 4, 1),
        onMonthChanged: (_) {},
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      // DateFormat.yMMMM('en') for April 2026 -> "April 2026"
      expect(find.text('April 2026'), findsOneWidget);
    });

    testWidgets('displays German month name with locale de', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2026, 3, 1),
        onMonthChanged: (_) {},
        locale: 'de',
      ));
      await tester.pumpAndSettle();

      // DateFormat.yMMMM('de') for March 2026 -> "März 2026"
      expect(find.text('März 2026'), findsOneWidget);
    });

    testWidgets('tapping left chevron navigates to previous month',
        (tester) async {
      DateTime? receivedMonth;
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2026, 4, 1),
        onMonthChanged: (month) => receivedMonth = month,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(receivedMonth, DateTime(2026, 3, 1));
    });

    testWidgets('tapping right chevron navigates to next month',
        (tester) async {
      DateTime? receivedMonth;
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2025, 6, 1), // Not current month
        onMonthChanged: (month) => receivedMonth = month,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(receivedMonth, DateTime(2025, 7, 1));
    });

    testWidgets('right chevron is disabled when at current month',
        (tester) async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      DateTime? receivedMonth;
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: currentMonth,
        onMonthChanged: (month) => receivedMonth = month,
      ));
      await tester.pumpAndSettle();

      // The right chevron IconButton should have null onPressed
      final rightButton = tester
          .widgetList<IconButton>(
            find.byType(IconButton),
          )
          .last;
      expect(rightButton.onPressed, isNull);

      // Tapping it should not trigger callback
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(receivedMonth, isNull);
    });

    testWidgets('left chevron correctly rolls over year boundary',
        (tester) async {
      DateTime? receivedMonth;
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2026, 1, 1), // January
        onMonthChanged: (month) => receivedMonth = month,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(receivedMonth, DateTime(2025, 12, 1)); // December previous year
    });

    testWidgets('right chevron correctly rolls over year boundary',
        (tester) async {
      DateTime? receivedMonth;
      await tester.pumpWidget(buildTestWidget(
        selectedMonth: DateTime(2024, 12, 1), // December (not current month)
        onMonthChanged: (month) => receivedMonth = month,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(receivedMonth, DateTime(2025, 1, 1)); // January next year
    });

    testWidgets('left chevron is always enabled', (tester) async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      await tester.pumpWidget(buildTestWidget(
        selectedMonth: currentMonth,
        onMonthChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      final leftButton = tester
          .widgetList<IconButton>(
            find.byType(IconButton),
          )
          .first;
      expect(leftButton.onPressed, isNotNull);
    });
  });
}
