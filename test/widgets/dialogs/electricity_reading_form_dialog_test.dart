import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/electricity_reading_form_dialog.dart';

void main() {
  Widget buildTestWidget({
    double? previousValue,
    double? nextValue,
    Future<void> Function(ElectricityReadingFormData)? onSaveCallback,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              ElectricityReadingFormDialog.show(
                context,
                previousValue: previousValue,
                nextValue: nextValue,
                onSaveCallback: onSaveCallback,
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('ElectricityReadingFormDialog - Buttons', () {
    testWidgets('shows only Cancel and Save buttons in add mode',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save & next'), findsNothing);
    });

    testWidgets('shows only Cancel and Save buttons in edit mode',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ElectricityReadingFormDialog(
                    reading: null,
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save & next'), findsNothing);
    });

    testWidgets('Save closes dialog and returns data',
        (tester) => tester.runAsync(() async {
              ElectricityReadingFormData? result;

              await tester.pumpWidget(MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result =
                            await ElectricityReadingFormDialog.show(context);
                      },
                      child: const Text('Open Dialog'),
                    ),
                  ),
                ),
              ));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Open Dialog'));
              await tester.pumpAndSettle();

              await tester.enterText(
                  find.widgetWithText(TextFormField, 'Meter Value'), '500');
              await tester.pumpAndSettle();

              await tester.tap(find.text('Save'));
              await tester.pumpAndSettle();

              expect(result, isNotNull);
              expect(result!.valueKwh, 500.0);

              await tester.pumpWidget(Container());
            }));

    testWidgets('Cancel closes dialog without saving',
        (tester) => tester.runAsync(() async {
              ElectricityReadingFormData? result;

              await tester.pumpWidget(MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result =
                            await ElectricityReadingFormDialog.show(context);
                      },
                      child: const Text('Open Dialog'),
                    ),
                  ),
                ),
              ));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Open Dialog'));
              await tester.pumpAndSettle();

              await tester.enterText(
                  find.widgetWithText(TextFormField, 'Meter Value'), '500');
              await tester.pumpAndSettle();

              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              expect(result, isNull);

              await tester.pumpWidget(Container());
            }));
  });

  group('ElectricityReadingFormDialog - Validation', () {
    testWidgets('shows previous value as reference', (tester) async {
      await tester.pumpWidget(buildTestWidget(previousValue: 1234.5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Previous: 1234.5 kWh'), findsOneWidget);
    });

    testWidgets('shows inline error when value < previous', (tester) async {
      await tester.pumpWidget(buildTestWidget(previousValue: 100.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter value less than previous
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Value'), '50');
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('Must be >= 100.0 kWh'), findsOneWidget);
    });

    testWidgets('no error when value >= previous', (tester) async {
      await tester.pumpWidget(buildTestWidget(previousValue: 100.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter value greater than previous
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Value'), '150');
      await tester.pumpAndSettle();

      // Should NOT show validation error
      expect(find.textContaining('Must be >='), findsNothing);
    });

    testWidgets('save disabled when validation fails', (tester) async {
      await tester.pumpWidget(buildTestWidget(previousValue: 100.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter value less than previous
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Value'), '50');
      await tester.pumpAndSettle();

      // Find the Save FilledButton - it should be disabled (onPressed == null)
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save enabled when validation passes', (tester) async {
      await tester.pumpWidget(buildTestWidget(previousValue: 100.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter valid value
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Value'), '150');
      await tester.pumpAndSettle();

      // Find the Save FilledButton - it should be enabled
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('validates empty field on save', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Try to save empty
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Value must be positive'), findsOneWidget);
    });
  });
}
