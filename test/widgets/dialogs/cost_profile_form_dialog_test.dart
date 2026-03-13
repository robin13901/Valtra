import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/dialogs/cost_profile_form_dialog.dart';

void main() {
  Widget buildDialog({CostConfig? config}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => CostProfileFormDialog.show(
              context,
              config: config,
              meterType: CostMeterType.electricity,
              householdId: 1,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Widget buildDialogWithResult({
    CostConfig? config,
    CostMeterType meterType = CostMeterType.electricity,
    required void Function(CostProfileFormData?) onResult,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await CostProfileFormDialog.show(
                context,
                config: config,
                meterType: meterType,
                householdId: 1,
              );
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('CostProfileFormDialog', () {
    testWidgets('renders all 3 fields in correct order', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify dialog title (create mode)
      expect(find.text('Add Cost Profile'), findsOneWidget);

      // Verify all 3 fields are present
      expect(find.text('Valid From'), findsOneWidget);
      expect(find.text('Annual Base Price'), findsOneWidget);
      expect(find.text('Energy Price'), findsOneWidget);

      // Verify order: Valid From should be above Annual Base Price,
      // which should be above Energy Price
      final validFromY = tester
          .getTopLeft(find.text('Valid From'))
          .dy;
      final annualBasePriceY = tester
          .getTopLeft(find.text('Annual Base Price'))
          .dy;
      final energyPriceY = tester
          .getTopLeft(find.text('Energy Price'))
          .dy;

      expect(validFromY, lessThan(annualBasePriceY));
      expect(annualBasePriceY, lessThan(energyPriceY));
    });

    testWidgets('date picker opens and updates date', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap on the date field (InkWell wrapping InputDecorator)
      await tester.tap(find.text('Valid From'));
      await tester.pumpAndSettle();

      // Date picker should be visible
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Select the 15th day
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // Confirm the date selection
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify the date display updated to include 15
      final now = DateTime.now();
      expect(
        find.text('15.${now.month.toString().padLeft(2, '0')}.${now.year}'),
        findsOneWidget,
      );
    });

    testWidgets('validation shows error for empty annual base price',
        (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Leave fields empty and tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error(s) - invalidNumber appears for both fields
      expect(find.text('Please enter a valid number'), findsWidgets);
    });

    testWidgets('validation shows error for empty energy price',
        (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill annual base price but leave energy price empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Annual Base Price'),
        '120',
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error for energy price
      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('create mode returns CostProfileFormData on save',
        (tester) async {
      CostProfileFormData? result;

      await tester.pumpWidget(buildDialogWithResult(
        onResult: (data) => result = data,
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter annual base price
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Annual Base Price'),
        '120.0',
      );
      await tester.pumpAndSettle();

      // Enter energy price
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Energy Price'),
        '0.30',
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.annualBasePrice, 120.0);
      expect(result!.energyPrice, 0.30);
      expect(result!.validFrom.day, 1);
      expect(result!.validFrom.month, DateTime.now().month);
      expect(result!.validFrom.year, DateTime.now().year);
    });

    testWidgets('edit mode pre-fills fields from existing config',
        (tester) async {
      final config = CostConfig(
        id: 1,
        householdId: 1,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: 120.0,
        priceTiers: null,
        currencySymbol: '\u20AC',
        validFrom: DateTime(2024, 6, 1),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildDialog(config: config));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify edit mode title
      expect(find.text('Edit Cost Profile'), findsOneWidget);

      // Verify fields are pre-filled
      expect(find.text('120.0'), findsOneWidget); // standingCharge
      expect(find.text('0.3'), findsOneWidget); // unitPrice
      expect(find.text('01.06.2024'), findsOneWidget); // validFrom date zero-padded
    });

    testWidgets('cancel returns null', (tester) async {
      CostProfileFormData? result;
      bool callbackCalled = false;

      await tester.pumpWidget(buildDialogWithResult(
        onResult: (data) {
          result = data;
          callbackCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Add Cost Profile'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Add Cost Profile'), findsNothing);

      // Result should be null
      expect(callbackCalled, isTrue);
      expect(result, isNull);
    });

    testWidgets('shows correct suffix for water meter type', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CostProfileFormDialog.show(
                context,
                meterType: CostMeterType.water,
                householdId: 1,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify water-specific suffix is shown
      expect(find.text('\u20AC/m\u00B3'), findsOneWidget);
    });

    testWidgets('shows correct suffix for electricity meter type',
        (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify electricity-specific suffix is shown
      expect(find.text('\u20AC/kWh'), findsOneWidget);
    });

    testWidgets('date displays with zero-padded day and month', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();

      // Open dialog in create mode
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Default validFrom is first of current month
      final now = DateTime.now();
      final expectedDay = '01';
      final expectedMonth = now.month.toString().padLeft(2, '0');
      final expectedYear = now.year.toString();
      final expectedDate = '$expectedDay.$expectedMonth.$expectedYear';

      // Date must use dd.MM.yyyy format (e.g. '01.03.2026', not '1.3.2026')
      expect(find.text(expectedDate), findsOneWidget);
      // Verify unpadded format is NOT shown
      final unpaddedDate = '1.${now.month}.${now.year}';
      expect(find.text(unpaddedDate), findsNothing);
    });
  });
}
