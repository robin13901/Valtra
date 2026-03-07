import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/water_meter_form_dialog.dart';

void main() {
  Widget buildTestWidget({WaterMeter? meter}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              WaterMeterFormDialog.show(context, meter: meter);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('WaterMeterFormDialog', () {
    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Add Water Meter'), findsOneWidget);

      // Try to save with empty name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Meter name is required'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      WaterMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await WaterMeterFormDialog.show(context);
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

      // Enter valid name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Kitchen Sink');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result (defaults to cold water type)
      expect(result, isNotNull);
      expect(result!.name, 'Kitchen Sink');
      expect(result!.type, WaterMeterType.cold);
    });

    testWidgets('type selector works', (tester) async {
      WaterMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await WaterMeterFormDialog.show(context);
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

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Test Meter');
      await tester.pumpAndSettle();

      // Select hot water type from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<WaterMeterType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hot Water').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.type, WaterMeterType.hot);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      WaterMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await WaterMeterFormDialog.show(context);
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
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Test');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed and result should be null
      expect(find.text('Add Water Meter'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edit mode pre-fills fields', (tester) async {
      final meter = WaterMeter(
        id: 1,
        householdId: 1,
        name: 'Existing Meter',
        type: WaterMeterType.hot,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                WaterMeterFormDialog.show(context, meter: meter);
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
      expect(find.text('Edit Water Meter'), findsOneWidget);

      // Verify fields are pre-filled
      expect(find.text('Existing Meter'), findsOneWidget);
    });

    testWidgets('can select other water type', (tester) async {
      WaterMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await WaterMeterFormDialog.show(context);
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

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Irrigation');
      await tester.pumpAndSettle();

      // Select other type from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<WaterMeterType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.type, WaterMeterType.other);
    });
  });
}
