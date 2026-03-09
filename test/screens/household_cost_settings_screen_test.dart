import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/locale_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/household_cost_settings_screen.dart';

class MockCostConfigProvider extends Mock implements CostConfigProvider {}

class MockLocaleProvider extends ChangeNotifier implements LocaleProvider {
  String _localeString = 'en';
  @override
  String get localeString => _localeString;
  @override
  Locale? get locale => Locale(_localeString);
  @override
  Future<void> init() async {}
  @override
  Future<void> setLocale(Locale l) async {
    _localeString = l.languageCode;
    notifyListeners();
  }
}

void main() {
  late MockCostConfigProvider costProvider;
  late MockLocaleProvider localeProvider;
  late ThemeProvider themeProvider;

  setUpAll(() {
    registerFallbackValue(CostMeterType.electricity);
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(CostConfigsCompanion.insert(
      householdId: 1,
      meterType: CostMeterType.electricity,
      unitPrice: 0.30,
      validFrom: DateTime(2024, 1, 1),
    ));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    costProvider = MockCostConfigProvider();
    localeProvider = MockLocaleProvider();
    themeProvider = ThemeProvider();
    await themeProvider.init();
    when(() => costProvider.householdId).thenReturn(1);
    when(() => costProvider.configs).thenReturn([]);
    when(() => costProvider.hasCostConfigs).thenReturn(false);
    when(() => costProvider.getConfigsForMeterType(any())).thenReturn([]);
    when(() => costProvider.getActiveConfig(any(), any())).thenReturn(null);
  });

  Widget buildScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CostConfigProvider>.value(value: costProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const HouseholdCostSettingsScreen(),
      ),
    );
  }

  // Test data factory
  List<CostConfig> createTestConfigs({
    CostMeterType meterType = CostMeterType.electricity,
  }) {
    return [
      CostConfig(
        id: 1,
        householdId: 1,
        meterType: meterType,
        unitPrice: 0.30,
        standingCharge: 120.0,
        priceTiers: null,
        currencySymbol: '\u20AC',
        validFrom: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      ),
      CostConfig(
        id: 2,
        householdId: 1,
        meterType: meterType,
        unitPrice: 0.28,
        standingCharge: 100.0,
        priceTiers: null,
        currencySymbol: '\u20AC',
        validFrom: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ];
  }

  group('HouseholdCostSettingsScreen', () {
    group('rendering', () {
      testWidgets('renders one card per meter type', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Electricity'), findsOneWidget);
        expect(find.text('Gas'), findsOneWidget);
        expect(find.text('Water'), findsOneWidget);
        expect(find.text('Heating'), findsOneWidget);
      });

      testWidgets('renders app bar with Cost Profiles title', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Cost Profiles'), findsOneWidget);
      });

      testWidgets('renders correct icons for each meter type', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.electric_bolt), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
        expect(find.byIcon(Icons.thermostat), findsOneWidget);
      });

      testWidgets('all cards start collapsed', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // All cards should show expand_more (collapsed)
        expect(find.byIcon(Icons.expand_more), findsNWidgets(4));
        expect(find.byIcon(Icons.expand_less), findsNothing);
      });

      testWidgets('each card has an add button', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsNWidgets(4));
      });
    });

    group('expand/collapse', () {
      testWidgets('expand/collapse toggles profile list', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Tap the Electricity card to expand
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Should show expand_less for Electricity, expand_more for others
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsNWidgets(3));

        // Tap again to collapse
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // All collapsed again
        expect(find.byIcon(Icons.expand_more), findsNWidgets(4));
        expect(find.byIcon(Icons.expand_less), findsNothing);
      });
    });

    group('empty state', () {
      testWidgets('shows no profiles message when expanded with no configs',
          (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        expect(
          find.text('No cost profiles configured'),
          findsOneWidget,
        );
      });
    });

    group('profile list', () {
      testWidgets('shows correct data for profiles', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Verify profile data is shown
        expect(find.text('Valid from 01.01.2025'), findsOneWidget);
        expect(find.text('Valid from 01.01.2024'), findsOneWidget);
      });

      testWidgets('active profile badge shown on correct profile',
          (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // The first config (id=1, validFrom=2025-01-01) should be active
        // since it is <= now and configs are ordered DESC
        expect(find.text('Active'), findsOneWidget);
      });

      testWidgets('profiles ordered by validFrom DESC', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Find the two profile tiles
        final tile2025 = find.text('Valid from 01.01.2025');
        final tile2024 = find.text('Valid from 01.01.2024');

        expect(tile2025, findsOneWidget);
        expect(tile2024, findsOneWidget);

        // 2025 should appear before 2024 (DESC order)
        final pos2025 = tester.getTopLeft(tile2025);
        final pos2024 = tester.getTopLeft(tile2024);
        expect(pos2025.dy, lessThan(pos2024.dy));
      });

      testWidgets('shows annual base price and unit price', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Check subtitle contains price information
        // For en locale: "120.00" and "0.30" with kWh unit
        expect(
          find.textContaining('Annual Base Price'),
          findsAtLeast(1),
        );
        expect(
          find.textContaining('Energy Price'),
          findsAtLeast(1),
        );
      });

      testWidgets('water profile shows m3 unit', (tester) async {
        final waterConfigs =
            createTestConfigs(meterType: CostMeterType.water);
        when(() => costProvider.getConfigsForMeterType(CostMeterType.water))
            .thenReturn(waterConfigs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Water card
        await tester.tap(find.text('Water'));
        await tester.pumpAndSettle();

        // Water profiles should show m3 unit
        expect(find.textContaining('m\u00B3'), findsAtLeast(1));
      });

      testWidgets('electricity profile shows kWh unit', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Electricity profiles should show kWh unit
        expect(find.textContaining('kWh'), findsAtLeast(1));
      });
    });

    group('popup menu', () {
      testWidgets('edit via popup menu shows edit option', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Tap the first popup menu button (there will be one per profile)
        final popupButtons = find.byType(PopupMenuButton<String>);
        expect(popupButtons, findsAtLeast(1));

        await tester.tap(popupButtons.first);
        await tester.pumpAndSettle();

        // Verify Edit and Delete options are shown
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('delete via popup menu shows confirmation dialog',
          (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);
        when(() => costProvider.deleteConfig(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Tap the first popup menu button
        final popupButtons = find.byType(PopupMenuButton<String>);
        await tester.tap(popupButtons.first);
        await tester.pumpAndSettle();

        // Tap Delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Delete Pricing'), findsOneWidget);
        expect(find.text('This action cannot be undone.'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        // Delete appears in dialog actions
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('confirming delete calls deleteConfig', (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);
        when(() => costProvider.deleteConfig(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Tap the first popup menu button
        final popupButtons = find.byType(PopupMenuButton<String>);
        await tester.tap(popupButtons.first);
        await tester.pumpAndSettle();

        // Tap Delete from popup menu
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Confirm deletion in dialog - find the Delete button in the dialog
        // The dialog has Cancel and Delete buttons
        final deleteButtons = find.widgetWithText(TextButton, 'Delete');
        await tester.tap(deleteButtons.last);
        await tester.pumpAndSettle();

        // Verify deleteConfig was called with the config id
        verify(() => costProvider.deleteConfig(1)).called(1);
      });

      testWidgets('cancelling delete does not call deleteConfig',
          (tester) async {
        final configs = createTestConfigs();
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(configs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Tap the first popup menu button
        final popupButtons = find.byType(PopupMenuButton<String>);
        await tester.tap(popupButtons.first);
        await tester.pumpAndSettle();

        // Tap Delete from popup menu
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Cancel deletion
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify deleteConfig was NOT called
        verifyNever(() => costProvider.deleteConfig(any()));
      });
    });

    group('add button', () {
      testWidgets('add button has correct tooltip', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Find add buttons - should have tooltips
        final addButtons = find.byIcon(Icons.add);
        expect(addButtons, findsNWidgets(4));

        // Verify tooltip on first add button
        final iconButton =
            tester.widget<IconButton>(find.byType(IconButton).first);
        expect(iconButton.tooltip, 'Add Cost Profile');
      });
    });

    group('no active profile', () {
      testWidgets('no active badge when all profiles are in the future',
          (tester) async {
        final futureConfigs = [
          CostConfig(
            id: 1,
            householdId: 1,
            meterType: CostMeterType.electricity,
            unitPrice: 0.30,
            standingCharge: 120.0,
            priceTiers: null,
            currencySymbol: '\u20AC',
            validFrom: DateTime(2099, 1, 1),
            createdAt: DateTime.now(),
          ),
        ];
        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(futureConfigs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand the Electricity card
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // No active badge should be shown
        expect(find.text('Active'), findsNothing);
      });
    });

    group('multiple meter types', () {
      testWidgets('different meter types show independently', (tester) async {
        final elecConfigs = createTestConfigs();
        final gasConfigs =
            createTestConfigs(meterType: CostMeterType.gas);

        when(() => costProvider.getConfigsForMeterType(
              CostMeterType.electricity,
            )).thenReturn(elecConfigs);
        when(() => costProvider.getConfigsForMeterType(CostMeterType.gas))
            .thenReturn(gasConfigs);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Expand Electricity
        await tester.tap(find.text('Electricity'));
        await tester.pumpAndSettle();

        // Should show profiles for electricity
        expect(find.text('Valid from 01.01.2025'), findsOneWidget);

        // Gas should still be collapsed
        // Expand Gas
        await tester.tap(find.text('Gas'));
        await tester.pumpAndSettle();

        // Now both should show profiles
        expect(find.text('Valid from 01.01.2025'), findsNWidgets(2));
      });
    });
  });
}
