import 'package:flutter/material.dart';
import '../core/analysis.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';

/// STEPS: function, domain, range, step-by-step evaluations, key points table.
class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key, required this.state});
  final AppState state;

  Widget _line(BuildContext c, String key, String value) => Text.rich(
        TextSpan(style: mono(c), children: [
          TextSpan(text: key, style: mono(c, color: C.amber, bold: true)),
          TextSpan(text: ' = $value'),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final a = state.analysis;
        if (a == null) {
          return WatchPage(title: 'Steps', children: [
            Padding(
              padding: EdgeInsets.only(top: m.fs * 2),
              child: Text(state.error ?? 'Nothing to solve yet', style: sans(context, color: C.amber)),
            ),
          ]);
        }
        final d = a.domain;
        return WatchPage(title: 'Steps', children: [
          Text('${a.f.name}(x) = ${a.f.body}', style: mono(context)),
          _line(context, a.dn, d.intervalNotation),
          Text(d.discrete ? 'Discrete set' : 'Interval', style: mono(context, color: C.muted, scale: 0.9)),
          _line(context, a.rn, a.range.notation),
          Text('bounds ${a.range.bounds}', style: mono(context, color: C.muted, scale: 0.9)),
          SizedBox(height: m.fs * 0.8),
          if (a.paramLines.isNotEmpty)
            WCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Solve a', style: mono(context, color: C.amber, bold: true)),
                SizedBox(height: m.fs * 0.3),
                for (final l in a.paramLines) Text(l, style: mono(context)),
              ]),
            ),
          if (a.evals.isEmpty) Text('No query points.', style: sans(context, color: C.muted)),
          for (final e in a.evals) _evalCard(context, a, e),
          _table(context, a),
        ]);
      },
    );
  }

  Widget _evalCard(BuildContext c, Analysis a, EvalResult e) {
    final m = Metrics.of(c);
    if (!e.inDomain) {
      return WCard(
        borderColor: C.amber,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.label, style: mono(c, bold: true, scale: 1.1)),
          SizedBox(height: m.fs * 0.5),
          Text('Undefined (Outside Domain)', style: sans(c, color: C.amber, bold: true, scale: 1.1)),
          Text('${e.x} ∉ ${a.dn} = ${a.domain.intervalNotation}', style: sans(c, color: C.muted, scale: 0.95)),
        ]),
      );
    }
    final pad = ' ' * e.label.length;
    final spans = <InlineSpan>[
      TextSpan(text: e.label, style: mono(c, color: C.amber)),
      TextSpan(text: ' = ${e.steps.first}'),
      for (final s in e.steps.skip(1)) TextSpan(text: '\n$pad = $s'),
    ];
    return WCard(child: Text.rich(TextSpan(style: mono(c), children: spans)));
  }

  Widget _table(BuildContext c, Analysis a) {
    final m = Metrics.of(c);
    Widget hdr(String t) => Padding(
          padding: EdgeInsets.symmetric(vertical: m.fs * 0.4),
          child: Text(t, style: sans(c, color: C.muted, bold: true, scale: 0.8, spacing: 1.2)),
        );
    return WCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Key points', style: mono(c, bold: true, scale: 1.1)),
        SizedBox(height: m.fs * 0.4),
        Table(
          columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(1)},
          border: const TableBorder(horizontalInside: BorderSide(color: C.border)),
          children: [
            TableRow(children: [hdr('X'), hdr('Y')]),
            for (final r in a.table)
              TableRow(children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: m.fs * 0.5),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: r.x, style: mono(c, scale: 1.05)),
                    if (r.tag.isNotEmpty) TextSpan(text: '  ${r.tag}', style: sans(c, color: C.muted, scale: 0.75)),
                  ])),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: m.fs * 0.5),
                  child: Text(r.y, style: mono(c, scale: 1.05)),
                ),
              ]),
          ],
        ),
      ]),
    );
  }
}
