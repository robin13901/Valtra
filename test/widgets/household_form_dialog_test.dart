import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/household_form_dialog.dart';

void main() {
  Widget buildTestWidget({Household? household}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              HouseholdFormDialog.show(context, household: household);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('HouseholdFormDialog', () {
    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Create Household'), findsOneWidget);

      // Try to save with empty name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Household name is required'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      HouseholdFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HouseholdFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Household Name'), 'My Home');
      await tester.pumpAndSettle();

      // Enter description
      final descriptionField =
          find.widgetWithText(TextFormField, 'Description (optional)');
      await tester.enterText(descriptionField, 'Main residence');
      await tester.pumpAndSettle();

      // Enter person count
      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. 2'), '3');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.name, 'My Home');
      expect(result!.description, 'Main residence');
      expect(result!.personCount, 3);
    });

    testWidgets('cancel closes dialog without saving', (tester) async {
      HouseholdFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HouseholdFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Household Name'), 'My Home');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed and result should be null
      expect(find.text('Create Household'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edit mode pre-fills fields including person count',
        (tester) async {
      final household = Household(
        id: 1,
        name: 'Existing Home',
        description: 'My existing home',
        personCount: 2,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                HouseholdFormDialog.show(context, household: household);
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
      expect(find.text('Edit Household'), findsOneWidget);

      // Verify fields are pre-filled
      expect(find.text('Existing Home'), findsOneWidget);
      expect(find.text('My existing home'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('returns null description when empty', (tester) async {
      HouseholdFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HouseholdFormDialog.show(context);
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

      // Enter only name and person count (no description)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Household Name'), 'My Home');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. 2'), '1');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result with null description
      expect(result, isNotNull);
      expect(result!.name, 'My Home');
      expect(result!.description, isNull);
      expect(result!.personCount, 1);
    });

    testWidgets('shows person count field in dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Number of persons'), findsOneWidget);
    });

    testWidgets('validates empty person count', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill in valid name
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Household Name'), 'Test Home');
      await tester.pumpAndSettle();

      // Leave person count empty
      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error for person count
      expect(find.text('Number of persons is required (min. 1)'),
          findsOneWidget);
    });

    testWidgets('person count only accepts digits', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Try to enter non-digit characters (filtered by inputFormatters)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. 2'), 'abc');
      await tester.pumpAndSettle();

      // Field should be empty (digits only filter)
      final textField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'e.g. 2'),
      );
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('valid submission includes personCount in result',
        (tester) async {
      HouseholdFormData? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await HouseholdFormDialog.show(context);
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
          find.widgetWithText(TextFormField, 'Household Name'), 'Family Home');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. 2'), '4');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.personCount, 4);
    });
  });
}
