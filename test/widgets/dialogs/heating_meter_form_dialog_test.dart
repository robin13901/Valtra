import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
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
    testWidgets('shows add title and room dropdown', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Heating Meter'), findsOneWidget);
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
    });

    testWidgets('submits form with selected room', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // First room is auto-selected, just save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.roomId, 1); // First room selected by default
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Heating Meter'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edit mode pre-fills room selection', (tester) async {
      final meter = const HeatingMeter(
        id: 1,
        householdId: 1,
        roomId: 2,
      );

      await tester.pumpWidget(buildTestWidget(meter: meter));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Heating Meter'), findsOneWidget);
      // Kitchen (room id 2) should be selected
      expect(find.text('Kitchen'), findsOneWidget);
    });

    testWidgets('shows room dropdown with rooms', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
    });

    testWidgets('room dropdown not shown when no rooms', (tester) async {
      await tester.pumpWidget(buildTestWidget(rooms: const []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Room dropdown not rendered when no rooms
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });

    testWidgets('no location/Standort field exists', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsNothing);
      expect(find.text('Standort'), findsNothing);
    });

    testWidgets('no heating type or ratio fields exist', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Heating type'), findsNothing);
      expect(find.text('Own meter'), findsNothing);
      expect(find.text('Central heating'), findsNothing);
      expect(find.text('Heating ratio (%)'), findsNothing);
    });

    testWidgets('no name field exists', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Meter Name'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('selecting different room returns correct roomId',
        (tester) async {
      HeatingMeterFormData? result;

      await tester.pumpWidget(buildTestWidgetWithResult(
        onResult: (r) => result = r,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Select Kitchen (second room)
      await tester.tap(find.text('Kitchen').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.roomId, 2);
    });
  });
}
