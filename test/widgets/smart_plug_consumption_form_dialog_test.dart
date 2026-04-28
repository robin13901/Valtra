import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/smart_plug_consumption_form_dialog.dart';

void main() {
  Widget buildTestWidget({
    SmartPlugConsumption? consumption,
    DuplicateMonthChecker? onCheckDuplicate,
    void Function(SmartPlugConsumptionFormData?)? onResult,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await SmartPlugConsumptionFormDialog.show(
                context,
                consumption: consumption,
                onCheckDuplicate: onCheckDuplicate,
              );
              onResult?.call(result);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('SmartPlugConsumptionFormDialog', () {
    testWidgets('renders month and year wheel pickers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ListWheelScrollView), findsNWidgets(2));
      expect(find.text('Select month'), findsOneWidget);
    });

    testWidgets('defaults to current month and year for new entry',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final monthName = DateFormat.MMMM('en').format(now);

      expect(find.text(monthName), findsOneWidget);
      expect(find.text(now.year.toString()), findsOneWidget);
    });

    testWidgets('validates empty value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Value must be positive'), findsOneWidget);
    });

    testWidgets('validates zero value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Value must be positive'), findsOneWidget);
    });

    testWidgets('submits form with valid data and defaults to current month',
        (tester) async {
      SmartPlugConsumptionFormData? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '15.5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.valueKwh, 15.5);
      final now = DateTime.now();
      expect(result!.month, DateTime(now.year, now.month, 1));
    });

    testWidgets('edit mode pre-fills fields with existing consumption',
        (tester) async {
      final consumption = SmartPlugConsumption(
        id: 1,
        smartPlugId: 1,
        month: DateTime(2024, 3, 1),
        valueKwh: 25.0,
      );

      await tester.pumpWidget(buildTestWidget(consumption: consumption));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Consumption'), findsOneWidget);
      expect(find.text('25.0'), findsOneWidget);
      expect(find.text('March'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      SmartPlugConsumptionFormData? result;
      bool resultCalled = false;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) {
          result = r;
          resultCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '10');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Consumption'), findsNothing);
      expect(resultCalled, true);
      expect(result, isNull);
    });

    testWidgets('shows duplicate warning when scrolling year wheel',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onCheckDuplicate: (_) async => true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Scroll the year wheel (second ListWheelScrollView) down to trigger change
      final yearWheel = find.byType(ListWheelScrollView).last;
      await tester.drag(yearWheel, const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Entry already exists for this month. It will be updated.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show duplicate warning when checker returns false',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onCheckDuplicate: (_) async => false,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Scroll the month wheel to trigger change
      final monthWheel = find.byType(ListWheelScrollView).first;
      await tester.drag(monthWheel, const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Entry already exists for this month. It will be updated.'),
        findsNothing,
      );
    });

    testWidgets('no interval type dropdown in form', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Interval Type'), findsNothing);
      expect(find.text('Daily'), findsNothing);
      expect(find.text('Weekly'), findsNothing);
      expect(find.text('Start Date'), findsNothing);
    });

    testWidgets('month wheel shows month names', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // The wheel shows the current month in the center.
      // Nearby months are visible due to the wheel viewport.
      final now = DateTime.now();
      final currentMonthName = DateFormat.MMMM('en').format(now);
      expect(find.text(currentMonthName), findsOneWidget);
    });

    testWidgets('scrolling month wheel changes selection', (tester) async {
      SmartPlugConsumptionFormData? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Scroll month wheel up (negative Y = scroll forward/down in list)
      final monthWheel = find.byType(ListWheelScrollView).first;
      await tester.drag(monthWheel, const Offset(0, -40));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '10');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final now = DateTime.now();
      final expectedMonth = (now.month % 12) + 1;
      expect(result!.month.month, expectedMonth);
      expect(result!.month.year, now.year);
      expect(result!.valueKwh, 10.0);
    });
  });
}
