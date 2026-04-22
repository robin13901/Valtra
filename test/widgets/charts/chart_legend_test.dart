import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/widgets/charts/chart_legend.dart';

void main() {
  Widget buildTestWidget({required List<ChartLegendItem> items}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 300,
          width: 400,
          child: ChartLegend(items: items),
        ),
      ),
    );
  }

  group('ChartLegend', () {
    testWidgets('renders correct number of legend items', (tester) async {
      final items = [
        const ChartLegendItem(color: Colors.blue, label: 'Electricity'),
        const ChartLegendItem(color: Colors.red, label: 'Gas'),
        const ChartLegendItem(color: Colors.green, label: 'Water'),
      ];

      await tester.pumpWidget(buildTestWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Gas'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('shows correct labels', (tester) async {
      final items = [
        const ChartLegendItem(color: Colors.orange, label: 'Actual'),
        const ChartLegendItem(
            color: Colors.orange, label: 'Interpolated', dashPattern: [4, 3]),
      ];

      await tester.pumpWidget(buildTestWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Interpolated'), findsOneWidget);
    });

    testWidgets('renders both solid and dashed items', (tester) async {
      final items = [
        const ChartLegendItem(color: Colors.blue, label: 'Solid'),
        const ChartLegendItem(
            color: Colors.blue, label: 'Dashed', dashPattern: [4, 3]),
      ];

      await tester.pumpWidget(buildTestWidget(items: items));
      await tester.pumpAndSettle();

      // Both items render - verify by checking labels and the legend line painters
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Dashed'), findsOneWidget);
      // Each legend item has a CustomPaint with Size(24, 3)
      final legendPaints = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.size == const Size(24, 3),
      );
      expect(legendPaints, findsNWidgets(2));
    });

    testWidgets('renders empty legend without error', (tester) async {
      await tester.pumpWidget(buildTestWidget(items: const []));
      await tester.pumpAndSettle();

      expect(find.byType(ChartLegend), findsOneWidget);
    });

    testWidgets('renders single item correctly', (tester) async {
      final items = [
        const ChartLegendItem(color: Colors.purple, label: 'Single'),
      ];

      await tester.pumpWidget(buildTestWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('Single'), findsOneWidget);
    });
  });
}
