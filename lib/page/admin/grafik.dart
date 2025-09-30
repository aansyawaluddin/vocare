import 'dart:math' as math;
import 'package:flutter/material.dart';

class PieChartDashboard extends StatelessWidget {
  final double? width;
  final List<double> values;
  final List<Color> colors;

  const PieChartDashboard({
    Key? key,
    this.width,
    this.values = const [30, 35, 35],
    this.colors = const [Colors.red, Colors.yellow, Colors.green],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = width ?? MediaQuery.of(context).size.width;
    final isCompact = w < 380;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monitoring Kelengkapan\nLaporan Perawat',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isCompact ? 160 : 200,
            child: Center(
              child: CustomPaint(
                size: const Size.square(200),
                painter: _PieChartPainter(values: values, colors: colors),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: const [
            Icon(Icons.stop, size: 12, color: Colors.red),
            SizedBox(width: 6),
            Text('Laporan \u2264 5'),
          ],
        ),
        const SizedBox(width: 14),
        Row(
          children: const [
            Icon(Icons.stop, size: 12, color: Colors.yellow),
            SizedBox(width: 6),
            Text('Laporan 6 - 10'),
          ],
        ),
        const SizedBox(width: 14),
        Row(
          children: const [
            Icon(Icons.stop, size: 12, color: Colors.green),
            SizedBox(width: 6),
            Text('Laporan > 10'),
          ],
        ),
      ],
    );
  }
}

// Painter class separated so this file contains everything needed for the pie chart.
class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.colors})
      : assert(values.length == colors.length, 'values and colors length must match');

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width, height: size.height);
    final total = values.fold<double>(0, (a, b) => a + b);

    double startRadian = -math.pi / 2; // start at top
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startRadian, sweep, true, paint);
      startRadian += sweep;
    }

    // draw white hole to make donut
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.28, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
