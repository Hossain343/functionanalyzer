import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/analysis.dart';
import '../painters/graph_painter.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';

/// GRAPH: Set domain -> isolated points only. Interval domain -> curve with solid/hollow ends.
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key, required this.state});
  final AppState state;
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Analysis? _fitFor;
  double _cx = 0, _cy = 0, _ppu = 30;
  bool _dragging = false; // freezes list scrolling while the plane is dragged

  void _fit(Analysis a, Size s) {
    final pts = <Offset>[const Offset(0, 0)];
    final d = a.domain;
    if (d.discrete) {
      for (final x in d.points) {
        pts.add(Offset(x.toDouble(), a.f.eval(x).toDouble()));
      }
    } else {
      final l = d.lo?.toDouble(), h = d.hi?.toDouble();
      final lo = l ?? (h != null ? h - 8 : -5.0);
      final hi = h ?? (l != null ? lo + 8 : 5.0);
      for (var i = 0; i <= 80; i++) {
        final x = lo + (hi - lo) * i / 80;
        final y = a.f.evalD(x);
        if (y.isFinite) pts.add(Offset(x, y));
      }
    }
    final xs = pts.map((p) => p.dx), ys = pts.map((p) => p.dy);
    final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
    final y0 = ys.reduce(math.min), y1 = ys.reduce(math.max);
    final xspan = math.max(x1 - x0, 2.0), yspan = math.max(y1 - y0, 2.0);
    _ppu = math.min(s.width / (xspan * 1.4), s.height / (yspan * 1.4));
    _cx = (x0 + x1) / 2;
    _cy = (y0 + y1) / 2;
    _fitFor = a;
  }

  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final a = widget.state.analysis;
        if (a == null) {
          return WatchPage(title: 'Graph', children: [
            Padding(
              padding: EdgeInsets.only(top: m.fs * 2),
              child: Text(widget.state.error ?? 'Nothing to show yet', style: sans(context, color: C.amber)),
            ),
          ]);
        }
        final d = a.domain;
        Widget note(String t) => Text(t, style: mono(context, color: C.muted, scale: 0.9));
        return WatchPage(
          title: 'Graph',
          physics: _dragging ? const NeverScrollableScrollPhysics() : null,
          children: [
            Text('${a.f.name}(x) = ${a.f.body}', style: mono(context)),
            Text.rich(TextSpan(style: mono(context), children: [
              TextSpan(text: a.rn, style: mono(context, color: C.amber, bold: true)),
              TextSpan(text: ' = ${a.range.notation}'),
            ])),
            note('bounds ${a.range.bounds}'),
            note(d.discrete ? 'Isolated points only. No connecting curve.' : 'Continuous curve. Solid end = included, hollow = excluded.'),
            SizedBox(height: m.fs * 0.7),
            Container(
              height: m.side * 0.62,
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(m.fs * 1.4),
                border: Border.all(color: C.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(builder: (context, box) {
                if (!identical(_fitFor, a)) _fit(a, box.biggest);
                return Listener(
                  onPointerDown: (_) => setState(() => _dragging = true),
                  onPointerUp: (_) => setState(() => _dragging = false),
                  onPointerCancel: (_) => setState(() => _dragging = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (g) => setState(() {
                      _cx -= g.delta.dx / _ppu;
                      _cy += g.delta.dy / _ppu;
                    }),
                    child: CustomPaint(
                      size: box.biggest,
                      painter: GraphPainter(a: a, cx: _cx, cy: _cy, ppu: _ppu, fs: m.fs),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: m.fs * 0.6),
            Text('Drag to pan the plane.', style: mono(context, scale: 0.95)),
            SizedBox(height: m.fs * 0.7),
            Row(children: [
              Expanded(flex: 3, child: DarkBtn(label: '−', onTap: () => setState(() => _ppu = (_ppu / 1.3).clamp(1.0, 5000.0).toDouble()))),
              SizedBox(width: m.fs * 0.5),
              Expanded(flex: 4, child: DarkBtn(label: 'Fit', onTap: () => setState(() => _fitFor = null))),
              SizedBox(width: m.fs * 0.5),
              Expanded(flex: 3, child: DarkBtn(label: '+', onTap: () => setState(() => _ppu = (_ppu * 1.3).clamp(1.0, 5000.0).toDouble()))),
            ]),
            SizedBox(height: m.fs * 0.8),
            Wrap(spacing: m.fs, runSpacing: m.fs * 0.4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _dot(context, true, d.discrete ? 'Set point' : 'Closed end'),
              if (d.hasOpenBound) _dot(context, false, 'Open end'),
            ]),
          ],
        );
      },
    );
  }

  Widget _dot(BuildContext c, bool closed, String t) {
    final m = Metrics.of(c);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: m.fs,
        height: m.fs,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: closed ? C.amber : C.card,
          border: Border.all(color: C.amber, width: 2),
        ),
      ),
      SizedBox(width: m.fs * 0.4),
      Text(t, style: sans(c, color: C.text, scale: 0.9)),
    ]);
  }
}
