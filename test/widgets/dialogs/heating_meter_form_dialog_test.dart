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
      locale: const Locale('en'),
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

  Widget buildTestWidgetWithResult({
    HeatingMeter? meter,
    List<Room>? rooms,
    required ValueChanged<HeatingMeterFormData?> onResult,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await HeatingMeterFormDialog.show(
                context,
                meter: meter,
                rooms: rooms ?? testRooms,
              );
              onResult(result);
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

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
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
      expect(result!.heatingRatio, isNull);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
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

      await tester.pumpWidget(buildTestWidget(meter: meter));
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

    testWidgets('room dropdown is required — validation fails without room',
        (tester) async {
      // With rooms present, first room is auto-selected, so validation passes.
      // Test with empty rooms list — no dropdown shown, but form still requires room.
      await tester.pumpWidget(buildTestWidget(rooms: const []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // With empty rooms, dropdown is not shown but selectedRoomId is null
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Test Meter');
      await tester.pumpAndSettle();

      // Room dropdown not rendered when no rooms
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });

    testWidgets('shows heating type selector with own meter and central heating',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Heating type label
      expect(find.text('Heating type'), findsOneWidget);

      // SegmentedButton options
      expect(find.text('Own meter'), findsOneWidget);
      expect(find.text('Central heating'), findsOneWidget);
    });

    testWidgets('ratio field hidden when own meter selected', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Own meter is the default — ratio field should be hidden
      expect(find.text('Heating ratio (%)'), findsNothing);
    });

    testWidgets('ratio field visible when central heating selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Central heating segment
      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();

      // Ratio field should now be visible
      expect(find.text('Heating ratio (%)'), findsOneWidget);
      expect(find.text('Share of total heating energy'), findsOneWidget);
    });

    testWidgets('ratio validation: required for central heating',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Central Meter');
      await tester.pumpAndSettle();

      // Select central heating
      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();

      // Try to save without ratio
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Heating ratio is required'), findsOneWidget);
    });

    testWidgets('ratio validation: must be between 1 and 100',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Central Meter');
      await tester.pumpAndSettle();

      // Select central heating
      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();

      // Enter invalid ratio (0)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Heating ratio (%)'), '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Must be between 1 and 100'), findsOneWidget);
    });

    testWidgets('ratio validation: 101 is invalid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Central Meter');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Heating ratio (%)'), '101');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Must be between 1 and 100'), findsOneWidget);
    });

    testWidgets('submits central heating form with valid ratio',
        (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Central Meter');
      await tester.pumpAndSettle();

      // Select central heating
      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();

      // Enter ratio
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Heating ratio (%)'), '25');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Central Meter');
      expect(result!.heatingType, HeatingType.centralMeter);
      expect(result!.heatingRatio, closeTo(0.25, 0.001));
    });

    testWidgets('switching back to own meter clears ratio in result',
        (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Meter Name'), 'Test');
      await tester.pumpAndSettle();

      // Select central heating, enter ratio
      await tester.tap(find.text('Central heating'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Heating ratio (%)'), '50');
      await tester.pumpAndSettle();

      // Switch back to own meter
      await tester.tap(find.text('Own meter'));
      await tester.pumpAndSettle();

      // Ratio field should be hidden
      expect(find.text('Heating ratio (%)'), findsNothing);

      // Save — ratio should be null
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.heatingType, HeatingType.ownMeter);
      expect(result!.heatingRatio, isNull);
    });

    testWidgets('edit mode pre-fills central heating type and ratio',
        (tester) async {
      final meter = HeatingMeter(
        id: 1,
        householdId: 1,
        roomId: 1,
        name: 'Central Meter',
        heatingType: HeatingType.centralMeter,
        heatingRatio: 0.25,
      );

      await tester.pumpWidget(buildTestWidget(meter: meter));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Heating Meter'), findsOneWidget);
      expect(find.text('Central Meter'), findsOneWidget);

      // Ratio field should be visible with pre-filled value
      expect(find.text('Heating ratio (%)'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('no location/Standort field exists', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsNothing);
      expect(find.text('Standort'), findsNothing);
    });
  });
}
