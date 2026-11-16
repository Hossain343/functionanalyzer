import 'package:flutter/material.dart';
import '../core/analysis.dart';
import '../core/text.dart';
import '../ui/theme.dart';
import 'paint_utils.dart';

class GraphPainter extends CustomPainter {
  GraphPainter({required this.a, required this.cx, required this.cy, required this.ppu, required this.fs});
  final Analysis a;
  final double cx, cy, ppu, fs;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(w / 2 + (x - cx) * ppu, h / 2 - (y - cy) * ppu);
    final left = cx - w / 2 / ppu, right = cx + w / 2 / ppu;
    final bottom = cy - h / 2 / ppu, top = cy + h / 2 / ppu;
    final step = niceStep(55 / ppu);

    final grid = Paint()..color = C.grid..strokeWidth = 1;
    for (var k = (left / step).floor(); k * step <= right; k++) {
      final xp = p(k * step, 0).dx;
      canvas.drawLine(Offset(xp, 0), Offset(xp, h), grid);
    }
    for (var k = (bottom / step).floor(); k * step <= top; k++) {
      final yp = p(0, k * step).dy;
      canvas.drawLine(Offset(0, yp), Offset(w, yp), grid);
    }

    final o = p(0, 0);
    final axX = clampD(o.dx, 12, w - 12), axY = clampD(o.dy, 12, h - 12);
    final axis = Paint()..color = C.axis..strokeWidth = 2;
    canvas.drawLine(Offset(6, axY), Offset(w - 10, axY), axis);
    canvas.drawLine(Offset(axX, h - 6), Offset(axX, 10), axis);
    arrowHead(canvas, Offset(w - 4, axY), 1, 0, C.axis, 4);
    arrowHead(canvas, Offset(axX, 4), 0, -1, C.axis, 4);

    for (var k = (left / step).floor(); k * step <= right; k++) {
      if (k == 0) continue;
      final xp = p(k * step, 0).dx;
      if (xp < 14 || xp > w - 14) continue;
      drawText(canvas, fmtAxis(k * step), Offset(xp, clampD(axY + 5, 4, h - fs * 1.4)), color: C.muted, size: fs * 0.85);
    }
    for (var k = (bottom / step).floor(); k * step <= top; k++) {
      if (k == 0) continue;
      final yp = p(0, k * step).dy;
      if (yp < 14 || yp > h - 8) continue;
      drawText(canvas, fmtAxis(k * step), Offset(8, yp - 2), color: C.muted, size: fs * 0.85, ax: 0, above: true);
    }

    final d = a.domain;
    final f = a.f;
    final r = a.range;

    if (d.discrete) {
      for (final xr in d.points) {
        final x = xr.toDouble(), y = f.evalD(x);
        if (!y.isFinite) continue;
        final pt = p(x, y);
        canvas.drawCircle(pt, fs * 0.5, Paint()..color = C.amber);
        drawText(canvas, '${f.eval(xr)}', pt + Offset(fs * 0.8, -fs * 0.3),
            color: C.text, size: fs * 0.9, ax: 0, above: true, weight: FontWeight.w700);
      }
    } else {
      // range bounds
      final dash = Paint()..color = C.amber.withAlpha(120)..strokeWidth = 1.2;
      void hline(String label, double? yv) {
        if (yv == null || !yv.isFinite) return;
        final yp = p(0, yv).dy;
        if (yp < 0 || yp > h) return;
        dashedHLine(canvas, yp, w, dash);
        drawText(canvas, 'y=$label', Offset(w - 8, yp - 2), color: C.amber.withAlpha(200), size: fs * 0.8, ax: 1, above: true);
      }

      hline('${r.minY}', r.minY?.toDouble());
      if (r.maxY != r.minY) hline('${r.maxY}', r.maxY?.toDouble());

      final lo = d.lo?.toDouble(), hi = d.hi?.toDouble();
      final xa = (lo != null && lo > left) ? lo : left;
      final xb = (hi != null && hi < right) ? hi : right;
      if (xa < xb) {
        final path = Path();
        var pen = false;
        final n = (w / 2).ceil();
        for (var i = 0; i <= n; i++) {
          final x = xa + (xb - xa) * i / n;
          final y = f.evalD(x);
          if (!y.isFinite) {
            pen = false;
            continue;
          }
          final pt = p(x, y);
          if (!pen) {
            path.moveTo(pt.dx, pt.dy);
            pen = true;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.save();
        canvas.clipRect(Offset.zero & size);
        canvas.drawPath(
            path,
            Paint()
              ..color = C.amber
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round);
        canvas.restore();
      }
      void end(double? x, bool closed) {
        if (x == null) return;
        final pt = p(x, f.evalD(x));
        if (pt.dx < -8 || pt.dx > w + 8 || pt.dy < -8 || pt.dy > h + 8) return;
        boundDot(canvas, pt, closed, fs * 0.45, C.amber, C.card);
      }

      end(lo, d.loClosed);
      end(hi, d.hiClosed);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter o) => true;
}
