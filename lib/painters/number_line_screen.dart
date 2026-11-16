import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/analysis.dart';
import '../painters/number_line_painter.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';

/// NUMBER LINE: drag to pan, tap a mark for details, - / Fit / + to zoom.
class NumberLineScreen extends StatefulWidget {
  const NumberLineScreen({super.key, required this.state});
  final AppState state;
  @override
  State<NumberLineScreen> createState() => _NumberLineScreenState();
}

class _NumberLineScreenState extends State<NumberLineScreen> {
  Analysis? _fitFor;
  double _cx = 0, _ppu = 40;
  Mark? _sel;

  void _fit(Analysis a, double w) {
    final xs = <double>[for (final m in a.marks) m.x.toDouble()];
    if (xs.isEmpty) {
      _cx = 0;
      _ppu = w / 12;
    } else {
      var mn = xs.reduce(math.min), mx = xs.reduce(math.max);
      if (mx - mn < 2) {
        final c = (mn + mx) / 2;
        mn = c - 1;
        mx = c + 1;
      }
      _cx = (mn + mx) / 2;
      _ppu = w / ((mx - mn) * 1.45);
    }
    _fitFor = a;
    _sel = null;
  }

  String _info(Analysis a, Mark m) {
    final x = m.x;
    switch (m.kind) {
      case 'bound':
        return 'x = $x · ${m.closed ? 'included (closed)' : 'excluded (open)'} · ${a.label(x)} = ${a.f.eval(x)}';
      case 'outside':
        return 'x = $x · outside ${a.dn} (undefined)';
      default:
        return 'x = $x · in ${a.dn} · ${a.label(x)} = ${a.f.eval(x)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final a = widget.state.analysis;
        if (a == null) {
          return WatchPage(title: 'Number line', children: [
            Padding(
              padding: EdgeInsets.only(top: m.fs * 2),
              child: Text(widget.state.error ?? 'Nothing to show yet', style: sans(context, color: C.amber)),
            ),
          ]);
        }
        final d = a.domain;
        final marks = a.marks;
        final cardH = m.side * 0.34;
        Widget note(String t) => Text(t, style: mono(context, color: C.muted, scale: 0.9));
        return WatchPage(title: 'Number line', children: [
          Text.rich(TextSpan(style: mono(context), children: [
            TextSpan(text: a.dn, style: mono(context, color: C.amber, bold: true)),
            TextSpan(text: ' = ${d.intervalNotation}'),
          ])),
          note(d.discrete ? 'Roster notation' : 'Interval notation'),
          if (!d.discrete) ...[
            Text(d.setBuilder, style: mono(context)),
            note('Set-builder notation'),
          ],
          SizedBox(height: m.fs * 0.6),
          Container(
            height: cardH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(m.fs * 1.4),
              border: Border.all(color: C.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (context, box) {
              if (!identical(_fitFor, a)) _fit(a, box.maxWidth);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (g) => setState(() => _cx -= g.delta.dx / _ppu),
                onTapUp: (t) {
                  Mark? best;
                  var bd = 28.0;
                  for (final mk in marks) {
                    final xp = box.maxWidth / 2 + (mk.x.toDouble() - _cx) * _ppu;
                    final dist = (xp - t.localPosition.dx).abs();
                    if (dist < bd) {
                      bd = dist;
                      best = mk;
                    }
                  }
                  setState(() => _sel = best);
                },
                child: CustomPaint(
                  size: Size(box.maxWidth, box.maxHeight),
                  painter: NumberLinePainter(
                      domain: d, marks: marks, cx: _cx, ppu: _ppu, fs: m.fs, selected: _sel),
                ),
              );
            }),
          ),
          SizedBox(height: m.fs * 0.6),
          Text(_sel == null ? 'Drag to pan. Tap a mark.' : _info(a, _sel!), style: mono(context, scale: 0.95)),
          SizedBox(height: m.fs * 0.7),
          Row(children: [
            Expanded(flex: 3, child: DarkBtn(label: '−', onTap: () => setState(() => _ppu = (_ppu / 1.3).clamp(2.0, 5000.0).toDouble()))),
            SizedBox(width: m.fs * 0.5),
            Expanded(flex: 4, child: DarkBtn(label: 'Fit', onTap: () => setState(() => _fitFor = null))),
            SizedBox(width: m.fs * 0.5),
            Expanded(flex: 3, child: DarkBtn(label: '+', onTap: () => setState(() => _ppu = (_ppu * 1.3).clamp(2.0, 5000.0).toDouble()))),
          ]),
          SizedBox(height: m.fs * 0.8),
          Wrap(spacing: m.fs, runSpacing: m.fs * 0.4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _legend(context, true, 'Included'),
            if (d.hasOpenBound) _legend(context, false, 'Excluded'),
            Text('Muted cross = outside query', style: sans(context, color: C.muted, scale: 0.85)),
          ]),
        ]);
      },
    );
  }

  Widget _legend(BuildContext c, bool closed, String t) {
    final m = Metrics.of(c);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: m.fs,
        height: m.fs,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: closed ? C.amber : C.bg,
          border: Border.all(color: C.amber, width: 2),
        ),
      ),
      SizedBox(width: m.fs * 0.4),
      Text(t, style: sans(c, color: C.text, scale: 0.9)),
    ]);
  }
}
