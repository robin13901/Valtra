import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/heating_meter_form_dialog.dart';

void main() {
  final testRooms = [
    const Room(id: 1, householdId: 1, name: 'Living Room'),
    const Room(id: 2, householdId: 1, name: 'Kitchen'),
  ];

  Widget buildTestWidget({HeatingMeter? meter, List<Room>? rooms}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              HeatingMeterFormDialog.show(
                context,
                meter: meter,
                rooms: rooms ?? testRooms,
              );
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

    testWidgets('submits form with name and room', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HeatingMeterFormDialog.show(
                  context,
                  rooms: testRooms,
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

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'),
          'Bedroom Radiator');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Bedroom Radiator');
      expect(result!.roomId, 1); // First room selected by default
      expect(result!.heatingType, HeatingType.ownMeter);
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
                result = await HeatingMeterFormDialog.show(
                  context,
                  rooms: testRooms,
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
        roomId: 2,
        name: 'Existing Meter',
        heatingType: HeatingType.ownMeter,
        heatingRatio: null,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                HeatingMeterFormDialog.show(
                  context,
                  meter: meter,
                  rooms: testRooms,
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

      expect(find.text('Edit Heating Meter'), findsOneWidget);
      expect(find.text('Existing Meter'), findsOneWidget);
    });

    testWidgets('shows room dropdown with rooms', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
    });
  });
}
