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
    testWidgets('renders month and year dropdowns', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Two DropdownButtonFormField<int> widgets: month and year
      expect(
        find.byType(DropdownButtonFormField<int>),
        findsNWidgets(2),
      );

      // "Select month" label
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

      // Current month name should appear in the dropdown
      expect(find.text(monthName), findsOneWidget);
      // Current year should appear in the dropdown
      expect(find.text(now.year.toString()), findsOneWidget);
    });

    testWidgets('validates empty value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Try to save with empty value
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

      // Enter valid value
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '15.5');
      await tester.pumpAndSettle();

      // Save
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

      // Verify edit mode title
      expect(find.text('Edit Consumption'), findsOneWidget);

      // Verify value is pre-filled
      expect(find.text('25.0'), findsOneWidget);

      // Verify month is pre-filled to March
      expect(find.text('March'), findsOneWidget);

      // Verify year is pre-filled to 2024
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

      // Enter some data
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '10');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Add Consumption'), findsNothing);
      expect(resultCalled, true);
      expect(result, isNull);
    });

    testWidgets('shows duplicate warning when onCheckDuplicate returns true',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onCheckDuplicate: (_) async => true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // The duplicate check is triggered on month/year change.
      // Open the year dropdown and select a different year to trigger the check.
      final yearDropdowns = find.byType(DropdownButtonFormField<int>);
      await tester.tap(yearDropdowns.last);
      await tester.pumpAndSettle();

      // Select the first year in the list (2020)
      await tester.tap(find.text('2020').last);
      await tester.pumpAndSettle();

      // Should show duplicate warning
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

      // Trigger month change
      final monthDropdowns = find.byType(DropdownButtonFormField<int>);
      await tester.tap(monthDropdowns.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('January').last);
      await tester.pumpAndSettle();

      // Should NOT show duplicate warning
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

      // Verify no interval type related UI
      expect(find.text('Interval Type'), findsNothing);
      expect(find.text('Daily'), findsNothing);
      expect(find.text('Weekly'), findsNothing);

      // No date picker / start date
      expect(find.text('Start Date'), findsNothing);
    });

    testWidgets('month dropdown shows month names', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Open month dropdown
      final dropdowns = find.byType(DropdownButtonFormField<int>);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      // Verify some months are visible in the dropdown overlay
      // (not all may be visible at once due to scrolling)
      expect(find.text('January'), findsWidgets);
      expect(find.text('February'), findsWidgets);
      expect(find.text('March'), findsWidgets);
      expect(find.text('April'), findsWidgets);
      expect(find.text('May'), findsWidgets);
      expect(find.text('June'), findsWidgets);
    });
  });
}
