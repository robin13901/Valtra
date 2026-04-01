import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/widgets/charts/chart_axis_style.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ChartAxisStyle', () {
    group('borderData', () {
      testWidgets('has bottom border only (no left border / AXIS-01)',
          (tester) async {
        late FlBorderData result;
        await tester.pumpWidget(buildTestApp(
          Builder(builder: (context) {
            result = ChartAxisStyle.borderData(context);
            return const SizedBox();
          }),
        ));

        expect(result.show, isTrue);
        expect(result.border.bottom, isNot(BorderSide.none));
        expect(result.border.left, BorderSide.none);
        expect(result.border.top, BorderSide.none);
        expect(result.border.right, BorderSide.none);
      });
    });

    group('gridData', () {
      testWidgets('shows horizontal grid lines, no vertical', (tester) async {
        late FlGridData result;
        await tester.pumpWidget(buildTestApp(
          Builder(builder: (context) {
            result = ChartAxisStyle.gridData(context);
            return const SizedBox();
          }),
        ));

        expect(result.show, isTrue);
        expect(result.drawVerticalLine, isFalse);
      });

      testWidgets('horizontal lines are dashed', (tester) async {
        late FlGridData result;
        await tester.pumpWidget(buildTestApp(
          Builder(builder: (context) {
            result = ChartAxisStyle.gridData(context);
            return const SizedBox();
          }),
        ));

        final line = result.getDrawingHorizontalLine(50);
        expect(line.dashArray, isNotNull);
        expect(line.dashArray, [4, 4]);
      });
    });

    group('leftTitles', () {
      testWidgets('shows titles with unit suffix', (tester) async {
        late AxisTitles result;
        await tester.pumpWidget(buildTestApp(
          Builder(builder: (context) {
            result = ChartAxisStyle.leftTitles(context: context, unit: 'kWh');
            return const SizedBox();
          }),
        ));

        expect(result.sideTitles.showTitles, isTrue);
        expect(result.sideTitles.reservedSize, 48);
      });

      testWidgets('hides min and max values', (tester) async {
        late AxisTitles result;
        await tester.pumpWidget(buildTestApp(
          Builder(builder: (context) {
            result = ChartAxisStyle.leftTitles(context: context, unit: 'kWh');
            return const SizedBox();
          }),
        ));

        final getTitlesWidget = result.sideTitles.getTitlesWidget;
        final meta = TitleMeta(
          min: 0,
          max: 100,
          parentAxisSize: 300,
          axisPosition: 50,
          appliedInterval: 25,
          sideTitles: SideTitles(),
          formattedValue: '50',
          axisSide: AxisSide.left,
        );

        // Min value (0) should return SizedBox.shrink
        final minMeta = TitleMeta(
          min: 0,
          max: 100,
          parentAxisSize: 300,
          axisPosition: 0,
          appliedInterval: 25,
          sideTitles: SideTitles(),
          formattedValue: '0',
          axisSide: AxisSide.left,
        );
        final minWidget = getTitlesWidget(0, minMeta);
        expect(minWidget, isA<SizedBox>());

        // Max value (100) should return SizedBox.shrink
        final maxMeta = TitleMeta(
          min: 0,
          max: 100,
          parentAxisSize: 300,
          axisPosition: 100,
          appliedInterval: 25,
          sideTitles: SideTitles(),
          formattedValue: '100',
          axisSide: AxisSide.left,
        );
        final maxWidget = getTitlesWidget(100, maxMeta);
        expect(maxWidget, isA<SizedBox>());

        // Middle value (50) should return a SideTitleWidget
        final midWidget = getTitlesWidget(50, meta);
        expect(midWidget, isA<SideTitleWidget>());
      });
    });

    group('hiddenTitles', () {
      test('does not show titles', () {
        expect(ChartAxisStyle.hiddenTitles.sideTitles.showTitles, isFalse);
      });
    });
  });
}
