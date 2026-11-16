import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/function_problem.dart';

class NumberLinePainter extends CustomPainter {
  final DomainSpec domain;
  final List<EvaluationStepResult> evaluations;

  const NumberLinePainter({
    required this.domain,
    this.evaluations = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <double>[0];
    if (domain.mode == DomainMode.discrete) {
      pts.addAll(domain.discreteValues);
    } else {
      if (domain.lowerBound != null) pts.add(domain.lowerBound!);
      if (domain.upperBound != null) pts.add(domain.upperBound!);
      pts.addAll(domain.excludedValues);
    }
    for (final ev in evaluations) {
      if (ev.x.isFinite) pts.add(ev.x);
    }

    double minX = -5;
    double maxX = 5;
    if (pts.length > 1) {
      final rawMin = pts.reduce(math.min);
      final rawMax = pts.reduce(math.max);
      final span = math.max(4.0, rawMax - rawMin);
      final pad = math.max(1.5, span * 0.25);
      minX = (rawMin - pad).floorToDouble();
      maxX = (rawMax + pad).ceilToDouble();
    } else if (domain.lowerBound != null) {
      minX = domain.lowerBound! - 2;
      maxX = domain.lowerBound! + 5;
    } else if (domain.upperBound != null) {
      minX = domain.upperBound! - 5;
      maxX = domain.upperBound! + 2;
    }

    final centerY = size.height * 0.68;
    const padX = 18.0;
    final trackW = math.max(30.0, size.width - padX * 2);
    double toScreenX(double x) =>
        padX + ((x - minX) / (maxX - minX)) * trackW;

    final axisPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.6;

    canvas.drawLine(
      Offset(padX - 6, centerY),
      Offset(size.width - padX + 6, centerY),
      axisPaint,
    );

    // Axis end arrows
    _drawArrowHead(canvas, Offset(padX - 9, centerY), pointingRight: false, color: const Color(0xFF64748B));
    _drawArrowHead(canvas, Offset(size.width - padX + 9, centerY), pointingRight: true, color: const Color(0xFF64748B));

    // Tick marks & cleanly spaced integer labels
    final span = maxX - minX;
    final step = span <= 10 ? 1 : span <= 20 ? 2 : (span / 6).ceil();
    for (int i = minX.ceil(); i <= maxX.floor(); i += step) {
      final sx = toScreenX(i.toDouble());
      canvas.drawLine(
        Offset(sx, centerY - 3.5),
        Offset(sx, centerY + 3.5),
        axisPaint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: i == 0 ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 9,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx - tp.width / 2, centerY + 7));
    }

    final intervalPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    if (domain.mode == DomainMode.discrete) {
      for (final x in domain.discreteValues) {
        _drawEndpoint(canvas, Offset(toScreenX(x), centerY), closed: true);
      }
    } else {
      final loX = domain.lowerBound != null ? toScreenX(domain.lowerBound!) : padX - 4;
      final hiX = domain.upperBound != null ? toScreenX(domain.upperBound!) : size.width - padX + 4;

      // Diagonal hatching bar above interval (matching textbook & whiteboard notation)
      final hatchPaint = Paint()
        ..color = const Color(0x5538BDF8)
        ..strokeWidth = 1.4;
      const hatchTop = 9.0;
      for (double hx = loX; hx <= hiX; hx += 6.0) {
        canvas.drawLine(
          Offset(hx, centerY - 1),
          Offset(math.min(hiX + 3, hx + 5), centerY - hatchTop),
          hatchPaint,
        );
      }
      canvas.drawLine(
        Offset(loX, centerY - hatchTop),
        Offset(hiX, centerY - hatchTop),
        hatchPaint,
      );

      canvas.drawLine(
        Offset(loX, centerY),
        Offset(hiX, centerY),
        intervalPaint,
      );

      if (domain.lowerBound == null) {
        _drawArrowHead(canvas, Offset(padX - 9, centerY), pointingRight: false, color: const Color(0xFF38BDF8));
      } else {
        _drawEndpoint(
          canvas,
          Offset(loX, centerY),
          closed: domain.lowerInclusive,
        );
      }

      if (domain.upperBound == null) {
        _drawArrowHead(canvas, Offset(size.width - padX + 9, centerY), pointingRight: true, color: const Color(0xFF38BDF8));
      } else {
        _drawEndpoint(
          canvas,
          Offset(hiX, centerY),
          closed: domain.upperInclusive,
        );
      }

      for (final ex in domain.excludedValues) {
        _drawEndpoint(
          canvas,
          Offset(toScreenX(ex), centerY),
          closed: false,
        );
      }
    }

    // Query point indicators above the hatched interval with staggered labels
    for (int i = 0; i < evaluations.length; i++) {
      final ev = evaluations[i];
      if (ev.x < minX || ev.x > maxX) continue;
      final sx = toScreenX(ev.x);
      final markerY = math.max(14.0, centerY - 20 - (i % 2) * 12);
      final color =
          ev.inDomain ? const Color(0xFF34D399) : const Color(0xFFF87171);

      final stemPaint = Paint()
        ..color = color
        ..strokeWidth = 1.1;
      canvas.drawLine(Offset(sx, markerY + 3.5), Offset(sx, centerY - 5), stemPaint);

      canvas.drawCircle(Offset(sx, markerY), 3.0, Paint()..color = color);

      final tp = TextPainter(
        text: TextSpan(
          text: formatCompactNum(ev.x),
          style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx - tp.width / 2, markerY - 12));
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip, {
    required bool pointingRight,
    required Color color,
  }) {
    final dir = pointingRight ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + dir * 6, tip.dy - 3.5)
      ..lineTo(tip.dx + dir * 6, tip.dy + 3.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawEndpoint(Canvas canvas, Offset center, {required bool closed}) {
    final fill = Paint()
      ..color = closed ? const Color(0xFF38BDF8) : const Color(0xFF0B0F17)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 5.0, fill);
    canvas.drawCircle(center, 5.0, stroke);
  }

  @override
  bool shouldRepaint(covariant NumberLinePainter oldDelegate) => true;
}
