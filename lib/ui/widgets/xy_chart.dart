import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';

class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.color,
    this.line = true,
    this.dots = false,
    this.bars = false,
    this.width = 2.5,
  });

  final List<Offset> points;
  final Color color;
  final bool line;
  final bool dots;

  /// Vertical sticks from the x axis (mass spectra).
  final bool bars;
  final double width;
}

/// A marked point (e.g. the equivalence point) with a label.
class ChartMarker {
  const ChartMarker(this.point, this.label, this.color);

  final Offset point;
  final String label;
  final Color color;
}

/// Minimal, dependency-free x–y chart with nice axis ticks.
class XyChart extends StatelessWidget {
  const XyChart({
    super.key,
    required this.series,
    this.markers = const [],
    this.xLabel = '',
    this.yLabel = '',
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.formatter = const NumberFormatter(significantDigits: 4),
    this.height = 260,
  });

  final List<ChartSeries> series;
  final List<ChartMarker> markers;
  final String xLabel;
  final String yLabel;
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final NumberFormatter formatter;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _ChartPainter(
          series: series,
          markers: markers,
          xLabel: xLabel,
          yLabel: yLabel,
          xMinOverride: xMin,
          xMaxOverride: xMax,
          yMinOverride: yMin,
          yMaxOverride: yMax,
          formatter: formatter,
          axisColor: scheme.onSurfaceVariant,
          gridColor: scheme.outlineVariant.withValues(alpha: 0.5),
          textStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// "Nice" tick step (1, 2, 5 × 10ⁿ) for about [count] intervals.
double niceStep(double range, int count) {
  if (range <= 0 || !range.isFinite) return 1;
  final raw = range / count;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / mag;
  final nice = f < 1.5 ? 1 : (f < 3 ? 2 : (f < 7 ? 5 : 10));
  return nice * mag;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.markers,
    required this.xLabel,
    required this.yLabel,
    required this.xMinOverride,
    required this.xMaxOverride,
    required this.yMinOverride,
    required this.yMaxOverride,
    required this.formatter,
    required this.axisColor,
    required this.gridColor,
    required this.textStyle,
  });

  final List<ChartSeries> series;
  final List<ChartMarker> markers;
  final String xLabel;
  final String yLabel;
  final double? xMinOverride;
  final double? xMaxOverride;
  final double? yMinOverride;
  final double? yMaxOverride;
  final NumberFormatter formatter;
  final Color axisColor;
  final Color gridColor;
  final TextStyle textStyle;

  TextPainter _text(String s) =>
      TextPainter(text: TextSpan(text: s, style: textStyle), textDirection: TextDirection.ltr)..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final s in series) ...s.points, for (final m in markers) m.point]
        .where((p) => p.dx.isFinite && p.dy.isFinite)
        .toList();
    if (pts.isEmpty) return;
    var xMin = xMinOverride ?? pts.map((p) => p.dx).reduce(math.min);
    var xMax = xMaxOverride ?? pts.map((p) => p.dx).reduce(math.max);
    var yMin = yMinOverride ?? pts.map((p) => p.dy).reduce(math.min);
    var yMax = yMaxOverride ?? pts.map((p) => p.dy).reduce(math.max);
    if (xMax == xMin) {
      xMin -= 1;
      xMax += 1;
    }
    if (yMax == yMin) {
      yMin -= 1;
      yMax += 1;
    }
    final xStep = niceStep(xMax - xMin, 5);
    final yStep = niceStep(yMax - yMin, 5);
    if (yMinOverride == null) yMin = (yMin / yStep).floor() * yStep;
    if (yMaxOverride == null) yMax = (yMax / yStep).ceil() * yStep;
    xMin = (xMin / xStep).floor() * xStep;
    xMax = (xMax / xStep).ceil() * xStep;

    final yTicks = <double>[for (var y = yMin; y <= yMax + yStep * 1e-9; y += yStep) y];
    final labelWidth = yTicks.map((y) => _text(formatter.format(y)).width).fold(0.0, math.max);
    final left = labelWidth + 10 + (yLabel.isEmpty ? 0 : 14);
    const top = 8.0;
    const right = 12.0;
    final bottom = 22.0 + (xLabel.isEmpty ? 0 : 16);
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (plot.width <= 0 || plot.height <= 0) return;

    double px(double x) => plot.left + (x - xMin) / (xMax - xMin) * plot.width;
    double py(double y) => plot.bottom - (y - yMin) / (yMax - yMin) * plot.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final y in yTicks) {
      canvas.drawLine(Offset(plot.left, py(y)), Offset(plot.right, py(y)), grid);
      final t = _text(formatter.format(y));
      t.paint(canvas, Offset(plot.left - t.width - 6, py(y) - t.height / 2));
    }
    for (var x = xMin; x <= xMax + xStep * 1e-9; x += xStep) {
      canvas.drawLine(Offset(px(x), plot.top), Offset(px(x), plot.bottom), grid);
      final t = _text(formatter.format(x));
      t.paint(canvas, Offset(px(x) - t.width / 2, plot.bottom + 4));
    }
    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1.2;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axis);
    if (xLabel.isNotEmpty) {
      final t = _text(xLabel);
      t.paint(canvas, Offset(plot.center.dx - t.width / 2, size.height - t.height));
    }
    if (yLabel.isNotEmpty) {
      final t = _text(yLabel);
      canvas.save();
      canvas.translate(0, plot.center.dy + t.width / 2);
      canvas.rotate(-math.pi / 2);
      t.paint(canvas, Offset.zero);
      canvas.restore();
    }

    canvas.save();
    canvas.clipRect(plot.inflate(4));
    for (final s in series) {
      final visible = s.points.where((p) => p.dx.isFinite && p.dy.isFinite).toList();
      if (s.line && !s.bars && visible.length > 1) {
        final path = Path()..moveTo(px(visible.first.dx), py(visible.first.dy));
        for (final p in visible.skip(1)) {
          path.lineTo(px(p.dx), py(p.dy));
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s.width
            ..strokeJoin = StrokeJoin.round,
        );
      }
      if (s.bars) {
        final stick = Paint()
          ..color = s.color
          ..strokeWidth = s.width
          ..strokeCap = StrokeCap.round;
        for (final p in visible) {
          canvas.drawLine(Offset(px(p.dx), py(math.max(yMin, 0))), Offset(px(p.dx), py(p.dy)), stick);
        }
      }
      if (s.dots) {
        for (final p in visible) {
          canvas.drawCircle(Offset(px(p.dx), py(p.dy)), 4.5, Paint()..color = s.color);
          canvas.drawCircle(
            Offset(px(p.dx), py(p.dy)),
            4.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
    for (final m in markers) {
      final c = Offset(px(m.point.dx), py(m.point.dy));
      canvas.drawCircle(c, 6, Paint()..color = m.color);
      canvas.drawCircle(
        c,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final t = _text(m.label);
      final dx = c.dx + 8 + t.width > plot.right ? c.dx - 8 - t.width : c.dx + 8;
      t.paint(canvas, Offset(dx, c.dy - t.height - 4));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
