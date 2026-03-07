import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/smart_plug_form_dialog.dart';

void main() {
  final testRooms = [
    Room(id: 1, householdId: 1, name: 'Living Room'),
    Room(id: 2, householdId: 1, name: 'Kitchen'),
  ];

  Widget buildTestWidget({SmartPlug? plug, int? initialRoomId}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              SmartPlugFormDialog.show(
                context,
                plug: plug,
                rooms: testRooms,
                initialRoomId: initialRoomId,
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('SmartPlugFormDialog', () {
    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Add Smart Plug'), findsOneWidget);

      // Clear the name field (it might have autofocus)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plug Name'), '');
      await tester.pumpAndSettle();

      // Try to save with empty name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Plug name is required'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      SmartPlugFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await SmartPlugFormDialog.show(
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

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter valid name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plug Name'), 'TV Plug');
      await tester.pumpAndSettle();

      // Select a room from the dropdown (no room pre-selected for new plugs)
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Living Room').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.name, 'TV Plug');
      expect(result!.roomId, 1); // First room
    });

    testWidgets('dropdown shows all rooms', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Open dropdown (no room pre-selected, so tap the dropdown widget)
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Verify all rooms are shown in dropdown
      expect(find.text('Living Room'), findsWidgets);
      expect(find.text('Kitchen'), findsWidgets);
    });

    testWidgets('edit mode pre-fills fields', (tester) async {
      final plug = SmartPlug(
        id: 1,
        roomId: 2, // Kitchen
        name: 'Existing Plug',
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                SmartPlugFormDialog.show(context, plug: plug, rooms: testRooms);
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
      expect(find.text('Edit Smart Plug'), findsOneWidget);

      // Verify fields are pre-filled
      expect(find.text('Existing Plug'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      SmartPlugFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await SmartPlugFormDialog.show(
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

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter some data
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plug Name'), 'Test Plug');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed and result should be null
      expect(find.text('Add Smart Plug'), findsNothing);
      expect(result, isNull);
    });
  });
}
