import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/smart_plug_consumption_form_dialog.dart';

void main() {
  Widget buildTestWidget({SmartPlugConsumption? consumption}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              SmartPlugConsumptionFormDialog.show(
                  context, consumption: consumption);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('SmartPlugConsumptionFormDialog', () {
    testWidgets('validates empty value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Add Consumption'), findsOneWidget);

      // Try to save with empty value
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Value must be positive'), findsOneWidget);
    });

    testWidgets('validates positive value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter zero value
      await tester.enterText(find.widgetWithText(TextFormField, 'Value'), '0');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Value must be positive'), findsOneWidget);
    });

    testWidgets('shows month picker field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Month field should be present with label
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      SmartPlugConsumptionFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await SmartPlugConsumptionFormDialog.show(context);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter valid value
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Value'), '15.5');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.valueKwh, 15.5);
      expect(result!.month, isNotNull);
      // Month should be 1st of current month
      final now = DateTime.now();
      expect(result!.month, DateTime(now.year, now.month, 1));
    });

    testWidgets('edit mode pre-fills fields', (tester) async {
      final consumption = SmartPlugConsumption(
        id: 1,
        smartPlugId: 1,
        month: DateTime(2024, 3, 1),
        valueKwh: 25.0,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                SmartPlugConsumptionFormDialog.show(
                    context, consumption: consumption);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify edit mode title
      expect(find.text('Edit Consumption'), findsOneWidget);

      // Verify value is pre-filled
      expect(find.text('25.0'), findsOneWidget);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      SmartPlugConsumptionFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await SmartPlugConsumptionFormDialog.show(context);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter some data
      await tester.enterText(find.widgetWithText(TextFormField, 'Value'), '10');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed and result should be null
      expect(find.text('Add Consumption'), findsNothing);
      expect(result, isNull);
    });
  });
}
