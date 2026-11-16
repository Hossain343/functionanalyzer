import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import '../engines/parser_solver_engine.dart';
import '../models/function_problem.dart';

class CartesianGraphPainter extends CustomPainter {
  final FunctionInputMode inputMode;
  final Expression? expression;
  final List<TableEntry> tableEntries;
  final DomainSpec domain;
  final RangeSpec range;
  final double parameterA;
  final double parameterB;
  final ParserSolverEngine engine;

  CartesianGraphPainter({
    required this.inputMode,
    required this.expression,
    required this.tableEntries,
    required this.domain,
    required this.range,
    required this.parameterA,
    this.parameterB = 0,
    required this.engine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final xs = <double>[0];
    final ys = <double>[0];

    if (inputMode == FunctionInputMode.table) {
      for (final e in tableEntries) {
        xs.add(e.x);
        ys.add(e.y);
      }
    } else if (expression != null) {
      if (domain.mode == DomainMode.discrete) {
        for (final x in domain.discreteValues) {
          xs.add(x);
          final y = engine.evaluate(expression!, x, a: parameterA, b: parameterB);
          if (y.isFinite) ys.add(y);
        }
      } else {
        final lo = domain.lowerBound ??
            (domain.upperBound != null ? domain.upperBound! - 5.0 : -4.0);
        final hi = domain.upperBound ??
            (domain.lowerBound != null ? domain.lowerBound! + 5.0 : 4.0);
        xs.addAll([lo, hi]);
        for (int i = 0; i <= 60; i++) {
          final x = lo + (hi - lo) * i / 60;
          final y = engine.evaluate(expression!, x, a: parameterA, b: parameterB);
          if (y.isFinite && y.abs() < 30) ys.add(y);
        }
      }
    }

    double xMin = xs.reduce(math.min);
    double xMax = xs.reduce(math.max);
    double yMin = ys.reduce(math.min);
    double yMax = ys.reduce(math.max);

    final xSpan = math.max(4.0, xMax - xMin);
    final ySpan = math.max(4.0, yMax - yMin);
    xMin -= xSpan * 0.25;
    xMax += xSpan * 0.25;
    yMin -= ySpan * 0.22;
    yMax += ySpan * 0.22;

    double toX(double x) => ((x - xMin) / (xMax - xMin)) * size.width;
    double toY(double y) =>
        size.height - ((y - yMin) / (yMax - yMin)) * size.height;

    // Range Rf horizontal band for bounded continuous mode
    if (inputMode == FunctionInputMode.formula &&
        domain.mode == DomainMode.continuous &&
        range.min != null &&
        range.max != null) {
      final bandPaint = Paint()..color = const Color(0x1634D399);
      final topY = toY(range.max!);
      final botY = toY(range.min!);
      canvas.drawRect(
        Rect.fromLTRB(0, topY, size.width, math.max(topY + 2, botY)),
        bandPaint,
      );
    }

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 0.8;

    final xStep = math.max(1, ((xMax - xMin) / 5).ceil());
    final yStep = math.max(1, ((yMax - yMin) / 5).ceil());

    for (int gx = xMin.ceil(); gx <= xMax.floor(); gx += xStep) {
      final px = toX(gx.toDouble());
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), gridPaint);
    }
    for (int gy = yMin.ceil(); gy <= yMax.floor(); gy += yStep) {
      final py = toY(gy.toDouble());
      canvas.drawLine(Offset(0, py), Offset(size.width, py), gridPaint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.4;
    final ox = toX(0);
    final oy = toY(0);
    if (oy >= 0 && oy <= size.height) {
      canvas.drawLine(Offset(0, oy), Offset(size.width, oy), axisPaint);
    }
    if (ox >= 0 && ox <= size.width) {
      canvas.drawLine(Offset(ox, 0), Offset(ox, size.height), axisPaint);
    }

    // Minimal clean numeric tick labels on axes
    final labelY = oy.clamp(8.0, size.height - 14.0);
    for (int gx = xMin.ceil(); gx <= xMax.floor(); gx += xStep) {
      if (gx == 0) continue;
      final sx = toX(gx.toDouble());
      if (sx < 14 || sx > size.width - 14) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: '$gx',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx - tp.width / 2, labelY + 3));
    }

    final labelX = ox.clamp(16.0, size.width - 14.0);
    for (int gy = yMin.ceil(); gy <= yMax.floor(); gy += yStep) {
      if (gy == 0) continue;
      final sy = toY(gy.toDouble());
      if (sy < 10 || sy > size.height - 10) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: '$gy',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelX - tp.width - 4, sy - tp.height / 2));
    }

    // Highlight Range Rf on Y-axis
    if (inputMode == FunctionInputMode.formula &&
        domain.mode == DomainMode.continuous &&
        ox >= 0 &&
        ox <= size.width &&
        range.min != null &&
        range.max != null) {
      final rangePaint = Paint()
        ..color = const Color(0xFF34D399)
        ..strokeWidth = 2.8;
      canvas.drawLine(
        Offset(ox, toY(range.min!)),
        Offset(ox, toY(range.max!)),
        rangePaint,
      );
    }

    // Helper for dashed projection lines to axes (just like teacher's whiteboard)
    void drawDashedProjections(double x, double y) {
      final sx = toX(x);
      final sy = toY(y);
      final projPaint = Paint()
        ..color = const Color(0x6694A3B8)
        ..strokeWidth = 1.0;

      if (oy >= 0 && oy <= size.height) {
        _drawDashedLine(canvas, Offset(sx, sy), Offset(sx, oy), projPaint);
      }
      if (ox >= 0 && ox <= size.width) {
        _drawDashedLine(canvas, Offset(sx, sy), Offset(ox, sy), projPaint);
      }
    }

    if (inputMode == FunctionInputMode.table) {
      for (final e in tableEntries) {
        drawDashedProjections(e.x, e.y);
        _drawMarker(canvas, Offset(toX(e.x), toY(e.y)), closed: true);
      }
      canvas.restore();
      return;
    }

    if (expression == null) {
      canvas.restore();
      return;
    }

    if (domain.mode == DomainMode.discrete) {
      for (final x in domain.discreteValues) {
        final y = engine.evaluate(expression!, x, a: parameterA, b: parameterB);
        if (y.isFinite) {
          drawDashedProjections(x, y);
          _drawMarker(canvas, Offset(toX(x), toY(y)), closed: true);
        }
      }
      canvas.restore();
      return;
    }

    final lo = domain.lowerBound ?? xMin;
    final hi = domain.upperBound ?? xMax;
    final path = Path();
    bool started = false;
    double prevSy = 0;

    const samples = 240;
    for (int i = 0; i <= samples; i++) {
      final x = lo + (hi - lo) * i / samples;
      final y = engine.evaluate(expression!, x, a: parameterA, b: parameterB);
      if (!y.isFinite || y.abs() > 1e5) {
        started = false;
        continue;
      }
      final pt = Offset(toX(x), toY(y));
      if (!started || (pt.dy - prevSy).abs() > size.height * 0.65) {
        path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
      prevSy = pt.dy;
    }

    final curvePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);

    if (domain.lowerBound != null) {
      final yLo = engine.evaluate(expression!, lo, a: parameterA, b: parameterB);
      if (yLo.isFinite) {
        drawDashedProjections(lo, yLo);
        _drawMarker(
          canvas,
          Offset(toX(lo), toY(yLo)),
          closed: domain.lowerInclusive && domain.contains(lo),
        );
      }
    }
    if (domain.upperBound != null) {
      final yHi = engine.evaluate(expression!, hi, a: parameterA, b: parameterB);
      if (yHi.isFinite) {
        drawDashedProjections(hi, yHi);
        _drawMarker(
          canvas,
          Offset(toX(hi), toY(yHi)),
          closed: domain.upperInclusive && domain.contains(hi),
        );
      }
    }

    for (final ex in domain.excludedValues) {
      final ey = engine.evaluate(expression!, ex, a: parameterA, b: parameterB);
      if (ey.isFinite) {
        _drawMarker(canvas, Offset(toX(ex), toY(ey)), closed: false);
      } else {
        final sx = toX(ex);
        _drawDashedLine(
          canvas,
          Offset(sx, 0),
          Offset(sx, size.height),
          Paint()
            ..color = const Color(0x88F87171)
            ..strokeWidth = 1.2,
        );
      }
    }
    canvas.restore();
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 2) return;
    const dashLen = 3.5;
    const gapLen = 3.0;
    final steps = (dist / (dashLen + gapLen)).floor();
    for (int i = 0; i <= steps; i++) {
      final t1 = (i * (dashLen + gapLen)) / dist;
      final t2 = math.min(1.0, (i * (dashLen + gapLen) + dashLen) / dist);
      canvas.drawLine(
        Offset(p1.dx + dx * t1, p1.dy + dy * t1),
        Offset(p1.dx + dx * t2, p1.dy + dy * t2),
        paint,
      );
    }
  }

  void _drawMarker(Canvas canvas, Offset pt, {required bool closed}) {
    final fill = Paint()
      ..color = closed ? const Color(0xFF38BDF8) : const Color(0xFF0B0F17);
    final border = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pt, 4.6, fill);
    canvas.drawCircle(pt, 4.6, border);
  }

  @override
  bool shouldRepaint(covariant CartesianGraphPainter oldDelegate) => true;
}
