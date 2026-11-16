import 'package:flutter/material.dart';
import '../core/analysis.dart';
import '../core/domain.dart';
import '../core/text.dart';
import '../ui/theme.dart';
import 'paint_utils.dart';

class NumberLinePainter extends CustomPainter {
  NumberLinePainter({
    required this.domain,
    required this.marks,
    required this.cx,
    required this.ppu,
    required this.fs,
    this.selected,
  });
  final Domain domain;
  final List<Mark> marks;
  final double cx, ppu, fs;
  final Mark? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, y = size.height * 0.52;
    double px(double x) => w / 2 + (x - cx) * ppu;
    const edge = 18.0;
    final r = fs * 0.5;

    canvas.drawLine(Offset(edge, y), Offset(w - edge, y), Paint()..color = C.dim..strokeWidth = 2);
    arrowHead(canvas, Offset(edge - 8, y), -1, 0, C.label, 4);
    arrowHead(canvas, Offset(w - edge + 8, y), 1, 0, C.label, 4);

    final left = cx - (w / 2) / ppu, right = cx + (w / 2) / ppu;
    final step = niceStep(70 / ppu);
    final tick = Paint()..color = C.dim..strokeWidth = 1.5;
    for (var k = (left / step).floor(); k * step <= right; k++) {
      final t = k * step, xp = px(t);
      if (xp < edge + 12 || xp > w - edge - 12) continue;
      canvas.drawLine(Offset(xp, y - 4), Offset(xp, y + 4), tick);
      drawText(canvas, fmtAxis(t), Offset(xp, y + fs * 0.8), color: C.muted, size: fs * 0.85);
    }

    if (!domain.discrete) {
      final l = domain.lo, h = domain.hi;
      final x0 = l == null ? edge : clampD(px(l.toDouble()), edge, w - edge);
      final x1 = h == null ? w - edge : clampD(px(h.toDouble()), edge, w - edge);
      if (x1 > x0) {
        canvas.drawLine(Offset(x0, y), Offset(x1, y), Paint()..color = C.amber..strokeWidth = 5);
      }
      if (l == null) arrowHead(canvas, Offset(edge - 8, y), -1, 0, C.amber, 4);
      if (h == null) arrowHead(canvas, Offset(w - edge + 8, y), 1, 0, C.amber, 4);
    }

    for (final m in marks) {
      final xp = px(m.x.toDouble());
      if (xp < edge - 4 || xp > w - edge + 4) continue;
      final o = Offset(xp, y);
      if (m.kind == 'outside') {
        final p = Paint()..color = C.muted..strokeWidth = 2..strokeCap = StrokeCap.round;
        canvas.drawLine(o + const Offset(-5, -5), o + const Offset(5, 5), p);
        canvas.drawLine(o + const Offset(-5, 5), o + const Offset(5, -5), p);
      } else if (m.kind == 'query') {
        canvas.drawCircle(o, r * 0.6, Paint()..color = C.text);
        drawText(canvas, '${m.x}', Offset(xp, y - r - 6), color: C.text, size: fs * 0.9, above: true);
      } else {
        boundDot(canvas, o, m.closed, r, C.amber, C.bg);
        drawText(canvas, '${m.x}', Offset(xp, y - r - 6),
            color: C.amber, size: fs * 0.95, above: true, weight: FontWeight.w700);
      }
      if (selected != null && identical(selected, m)) {
        canvas.drawCircle(
            o,
            r + 6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = C.text);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NumberLinePainter o) => true;
}
