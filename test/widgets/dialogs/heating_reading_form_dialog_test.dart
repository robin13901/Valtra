import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/heating_reading_form_dialog.dart';

void main() {
  Widget buildTestWidget({HeatingReading? reading}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              HeatingReadingFormDialog.show(context, reading: reading);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('HeatingReadingFormDialog', () {
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
      final reading = HeatingReading(
        id: 1,
        heatingMeterId: 1,
        timestamp: DateTime(2024, 1, 15, 10, 30),
        value: 1234.5,
      );

      await tester.pumpWidget(buildTestWidget(reading: reading));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save & next'), findsNothing);
      expect(find.text('Edit Reading'), findsOneWidget);
    });

    testWidgets('validates empty value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Reading'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Value must be positive'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      HeatingReadingFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingReadingFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Meter Value'), '1234.5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.value, 1234.5);
      expect(result!.timestamp, isNotNull);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      HeatingReadingFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingReadingFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Meter Value'), '100.0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Reading'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edit mode pre-fills value', (tester) async {
      final reading = HeatingReading(
        id: 1,
        heatingMeterId: 1,
        timestamp: DateTime(2024, 1, 15, 10, 30),
        value: 1234.5,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                HeatingReadingFormDialog.show(context, reading: reading);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Reading'), findsOneWidget);
      expect(find.text('1234.5'), findsOneWidget);
      expect(find.textContaining('15.01.2024'), findsOneWidget);
    });

    testWidgets('date time picker is accessible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Date & Time'), findsOneWidget);

      await tester.tap(find.text('Date & Time'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('no unit suffix displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Should NOT show m\u00B3 suffix (unit-less)
      expect(find.text('m\u00B3'), findsNothing);
    });
  });
}
