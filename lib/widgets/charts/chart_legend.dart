import 'package:flutter/material.dart';

class ChartLegendItem {
  final Color color;
  final String label;
  final bool isDashed;
  const ChartLegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });
}

class ChartLegend extends StatelessWidget {
  final List<ChartLegendItem> items;
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) => _buildItem(context, item)).toList(),
    );
  }

  Widget _buildItem(BuildContext context, ChartLegendItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(24, 3),
          painter:
              _LegendLinePainter(color: item.color, isDashed: item.isDashed),
        ),
        const SizedBox(width: 6),
        Text(item.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _LegendLinePainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (isDashed) {
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      var startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) =>
      color != oldDelegate.color || isDashed != oldDelegate.isDashed;
}
