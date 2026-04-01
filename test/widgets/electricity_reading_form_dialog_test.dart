import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/electricity_reading_form_dialog.dart';

import '../helpers/test_database.dart';

void main() {
  Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) => child)),
    );
  }

  group('ElectricityReadingFormDialog', () {
    testWidgets('form validates empty value',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithMaterialApp(
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () => ElectricityReadingFormDialog.show(context),
                    child: const Text('Open'),
                  );
                }),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Clear the value field and try to save
              final valueField = find.byType(TextFormField);
              expect(valueField, findsOneWidget);

              await tester.tap(find.text('Save'));
              await tester.pumpAndSettle();

              // Should show validation error
              expect(find.textContaining('positive'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('form submits with valid data',
        (tester) => tester.runAsync(() async {
              ElectricityReadingFormData? result;

              await tester.pumpWidget(wrapWithMaterialApp(
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result =
                          await ElectricityReadingFormDialog.show(context);
                    },
                    child: const Text('Open'),
                  );
                }),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Enter value
              await tester.enterText(find.byType(TextFormField), '1234.5');
              await tester.pumpAndSettle();

              // Save
              await tester.tap(find.text('Save'));
              await tester.pumpAndSettle();

              expect(result, isNotNull);
              expect(result!.valueKwh, 1234.5);

              await tester.pumpWidget(Container());
            }));

    testWidgets('cancel closes dialog without saving',
        (tester) => tester.runAsync(() async {
              ElectricityReadingFormData? result;

              await tester.pumpWidget(wrapWithMaterialApp(
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result =
                          await ElectricityReadingFormDialog.show(context);
                    },
                    child: const Text('Open'),
                  );
                }),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Enter value
              await tester.enterText(find.byType(TextFormField), '1234.5');
              await tester.pumpAndSettle();

              // Cancel
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              expect(result, isNull);

              await tester.pumpWidget(Container());
            }));

    testWidgets('edit mode pre-fills fields',
        (tester) => tester.runAsync(() async {
              // Create a real reading from the database
              final database = createTestDatabase();
              final dao = ElectricityDao(database);

              // Create household first
              final householdId = await database
                  .into(database.households)
                  .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));

              // Create a reading
              final readingId =
                  await dao.insertReading(ElectricityReadingsCompanion.insert(
                householdId: householdId,
                timestamp: DateTime(2024, 3, 15, 10, 30),
                valueKwh: 1234.5,
              ));

              final existingReading = await dao.getReading(readingId);

              await tester.pumpWidget(MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Builder(builder: (context) {
                    return ElevatedButton(
                      onPressed: () =>
                          showDialog<ElectricityReadingFormData>(
                        context: context,
                        builder: (context) => ElectricityReadingFormDialog(
                          reading: existingReading,
                        ),
                      ),
                      child: const Text('Open'),
                    );
                  }),
                ),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Value should be pre-filled
              final textField =
                  tester.widget<TextFormField>(find.byType(TextFormField));
              expect(textField.controller?.text, '1234.5');

              // Dialog title should indicate edit mode
              expect(find.text('Edit Reading'), findsOneWidget);

              await database.close();
              await tester.pumpWidget(Container());
            }));

    testWidgets('date/time picker displays',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithMaterialApp(
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () => ElectricityReadingFormDialog.show(context),
                    child: const Text('Open'),
                  );
                }),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Should show date/time label
              expect(find.text('Date & Time'), findsOneWidget);

              // Should show date picker tile
              expect(find.byIcon(Icons.calendar_today), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('validates non-numeric input as invalid',
        (tester) => tester.runAsync(() async {
              await tester.pumpWidget(wrapWithMaterialApp(
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () => ElectricityReadingFormDialog.show(context),
                    child: const Text('Open'),
                  );
                }),
              ));
              await tester.pumpAndSettle();

              // Open dialog
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();

              // Try to enter non-numeric value (filtered by input formatter)
              await tester.enterText(find.byType(TextFormField), 'abc');
              await tester.pumpAndSettle();

              // The input formatter should have prevented the text entry
              final textField =
                  tester.widget<TextFormField>(find.byType(TextFormField));
              expect(textField.controller?.text, '');

              // Try to save empty
              await tester.tap(find.text('Save'));
              await tester.pumpAndSettle();

              expect(find.textContaining('positive'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
