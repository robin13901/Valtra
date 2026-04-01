import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/widgets/charts/monthly_summary_card.dart';

void main() {
  late ThemeProvider themeProvider;

  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    await themeProvider.init();
  });

  Widget buildTestWidget({
    double? totalConsumption,
    double? previousMonthTotal,
    String unit = 'kWh',
    DateTime? month,
    Color color = Colors.amber,
    String locale = 'en',
    double? smartPlugKwh,
    double? smartPlugPercent,
  }) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: Scaffold(
          body: MonthlySummaryCard(
            totalConsumption: totalConsumption,
            previousMonthTotal: previousMonthTotal,
            unit: unit,
            month: month ?? DateTime(2026, 4, 1),
            color: color,
            locale: locale,
            smartPlugKwh: smartPlugKwh,
            smartPlugPercent: smartPlugPercent,
          ),
        ),
      ),
    );
  }

  group('MonthlySummaryCard', () {
    testWidgets('displays month name in header', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.0,
        month: DateTime(2026, 4, 1),
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      // "Total for April 2026"
      expect(find.textContaining('April 2026'), findsOneWidget);
    });

    testWidgets('displays German month name with locale de', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.0,
        month: DateTime(2026, 3, 1),
        locale: 'de',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('März 2026'), findsOneWidget);
    });

    testWidgets('displays total consumption value with unit', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.5,
        unit: 'kWh',
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      // ValtraNumberFormat.consumption(250.5, 'en') -> "250.5"
      expect(find.textContaining('250.5'), findsOneWidget);
      expect(find.textContaining('kWh'), findsWidgets);
    });

    testWidgets('displays em-dash when totalConsumption is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: null,
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('shows % increase when consumption rose', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 300.0,
        previousMonthTotal: 200.0, // 50% increase
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      // "+50.0% vs last month"
      expect(find.textContaining('+50.0%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('shows % decrease when consumption dropped', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 150.0,
        previousMonthTotal: 200.0, // -25% decrease
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('-25.0%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('does not show change when previousMonthTotal is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.0,
        previousMonthTotal: null,
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('does not show change when previousMonthTotal is zero',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.0,
        previousMonthTotal: 0.0,
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('does not show change when totalConsumption is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: null,
        previousMonthTotal: 200.0,
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('renders with m3 unit for water', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 12.3,
        unit: 'm\u00B3',
        locale: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('m\u00B3'), findsWidgets);
    });
  });

  group('smart plug coverage', () {
    testWidgets('does not show coverage line when smartPlugKwh is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 250.0,
        locale: 'en',
        // smartPlugKwh is null, smartPlugPercent is null -> no coverage line
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.power), findsNothing);
    });

    testWidgets(
        'shows coverage line when smartPlugKwh and smartPlugPercent are provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 200.0,
        locale: 'en',
        smartPlugKwh: 50.0,
        smartPlugPercent: 25.0,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.power), findsOneWidget);
      // "50" should appear in the coverage text
      expect(find.textContaining('50'), findsWidgets);
      // "25.0%" should appear
      expect(find.textContaining('25.0%'), findsOneWidget);
    });

    testWidgets(
        'does not show coverage line when only smartPlugKwh is set (smartPlugPercent null)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        totalConsumption: 200.0,
        locale: 'en',
        smartPlugKwh: 50.0,
        // smartPlugPercent is null -> coverage line should NOT render
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.power), findsNothing);
    });
  });
}
