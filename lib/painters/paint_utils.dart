import 'package:flutter/material.dart';

/// ax: 0 = anchor at left, .5 = centre, 1 = right. above: text bottom sits at o.dy.
void drawText(Canvas c, String t, Offset o,
    {required Color color, double size = 11, double ax = 0.5, bool above = false, FontWeight? weight}) {
  final tp = TextPainter(
    text: TextSpan(
      text: t,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        fontFamily: 'Consolas',
        fontFamilyFallback: const ['monospace', 'Courier New'],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset(o.dx - tp.width * ax, above ? o.dy - tp.height : o.dy));
}

void dashedHLine(Canvas c, double y, double w, Paint p) {
  for (double x = 0; x < w; x += 10) {
    c.drawLine(Offset(x, y), Offset(x + 5, y), p);
  }
}

/// Solid dot = included (≤, ≥). Hollow dot = excluded (<, >).
void boundDot(Canvas c, Offset o, bool closed, double r, Color color, Color surface) {
  c.drawCircle(o, r, Paint()..color = closed ? color : surface);
  c.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color);
}

void arrowHead(Canvas c, Offset tip, double dx, double dy, Color color, double s) {
  // direction (dx, dy) is a unit vector pointing to the tip
  final bx = tip.dx - dx * s * 1.6, by = tip.dy - dy * s * 1.6;
  c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(bx - dy * s, by + dx * s)
        ..lineTo(bx + dy * s, by - dx * s)
        ..close(),
      Paint()..color = color);
}

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
