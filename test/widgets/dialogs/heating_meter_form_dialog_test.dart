import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/heating_meter_form_dialog.dart';

void main() {
  Widget buildTestWidget({HeatingMeter? meter}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              HeatingMeterFormDialog.show(context, meter: meter);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('HeatingMeterFormDialog', () {
    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Heating Meter'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Meter name is required'), findsOneWidget);
    });

    testWidgets('submits form with name and location', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingMeterFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Meter Name'),
          'Bedroom Radiator');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Location'), 'Bedroom');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Bedroom Radiator');
      expect(result!.location, 'Bedroom');
    });

    testWidgets('submits form with name only (no location)', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingMeterFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Meter Name'), 'Hall Radiator');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Hall Radiator');
      expect(result!.location, isNull);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingMeterFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Meter Name'), 'Test');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Heating Meter'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edit mode pre-fills fields', (tester) async {
      final meter = HeatingMeter(
        id: 1,
        householdId: 1,
        name: 'Existing Meter',
        location: 'Kitchen',
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                HeatingMeterFormDialog.show(context, meter: meter);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Heating Meter'), findsOneWidget);
      expect(find.text('Existing Meter'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
    });

    testWidgets('edit mode with no location shows empty location field',
        (tester) async {
      final meter = HeatingMeter(
        id: 1,
        householdId: 1,
        name: 'No Location Meter',
        location: null,
      );

      await tester.pumpWidget(buildTestWidget(meter: meter));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Heating Meter'), findsOneWidget);
      expect(find.text('No Location Meter'), findsOneWidget);
    });
  });
}
