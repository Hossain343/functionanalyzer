import 'package:flutter/material.dart';
import '../core/text.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';

/// INPUT: function, domain (Interval / Set), optional condition for a, query points.
class InputScreen extends StatefulWidget {
  const InputScreen({super.key, required this.state, required this.onSolved});
  final AppState state;
  final VoidCallback onSolved;
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  AppState get s => widget.state;
  late final _expr = TextEditingController(text: s.expr);
  late final _set = TextEditingController(text: s.setText);
  late final _lo = TextEditingController(text: s.loText);
  late final _hi = TextEditingController(text: s.hiText);
  late final _query = TextEditingController(text: s.query);
  late final _cond = TextEditingController(text: s.condition);

  @override
  void dispose() {
    for (final c in [_expr, _set, _lo, _hi, _query, _cond]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    _expr.text = s.expr;
    _set.text = s.setText;
    _lo.text = s.loText;
    _hi.text = s.hiText;
    _query.text = s.query;
    _cond.text = s.condition;
  }

  bool get _hasA {
    final body = normalizeInput(s.expr)
        .replaceFirst(RegExp(r'^[A-Za-z]\w*\(\s*x\s*\)\s*=', caseSensitive: false), '');
    return RegExp(r'[aA]').hasMatch(body);
  }

  /// Text field tuned for the Samsung / Wear OS keyboard: plain text keyboard (so - , / ^ are
  /// available), no autocorrect or suggestions, "done" action. Persian digits are normalised later.
  Widget _field(TextEditingController c, ValueChanged<String> onChanged, {String? hint, bool center = false}) {
    final m = Metrics.of(context);
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(m.fs * 1.2),
        border: Border.all(color: C.border),
      ),
      child: TextField(
        controller: c,
        onChanged: (v) {
          onChanged(v);
          s.analyze();
        },
        style: mono(context, scale: 1.05),
        textAlign: center ? TextAlign.center : TextAlign.start,
        cursorColor: C.amber,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        scrollPadding: EdgeInsets.only(bottom: m.side * 0.3),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: mono(context, color: C.dim, scale: 1.05),
          contentPadding: EdgeInsets.symmetric(horizontal: m.fs * 1.1, vertical: m.fs * 1.0),
        ),
      ),
    );
  }

  Widget _boundRow(bool left) {
    final m = Metrics.of(context);
    final closed = left ? s.loClosed : s.hiClosed;
    final inf = left ? s.loInf : s.hiInf;
    final ctl = left ? _lo : _hi;
    final bw = m.fs * 3.4;
    final bracket = DarkBtn(
      label: left ? (closed ? '[' : '(') : (closed ? ']' : ')'),
      active: closed,
      enabled: !inf, // infinity is never included
      width: bw,
      onTap: () {
        setState(() {
          if (left) {
            s.loClosed = !s.loClosed;
          } else {
            s.hiClosed = !s.hiClosed;
          }
        });
        s.analyze();
      },
    );
    final infBtn = DarkBtn(
      label: '∞',
      active: inf,
      width: bw,
      scale: 1.3,
      onTap: () {
        setState(() {
          if (left) {
            s.loInf = !s.loInf;
          } else {
            s.hiInf = !s.hiInf;
          }
        });
        s.analyze();
      },
    );
    final Widget mid = inf
        ? Container(
            height: m.btn,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(m.fs * 1.2),
              border: Border.all(color: C.border),
            ),
            child: Text(left ? '-∞' : '∞', style: mono(context, color: C.dim, scale: 1.1)),
          )
        : _field(ctl, (v) {
            if (left) {
              s.loText = v;
            } else {
              s.hiText = v;
            }
          });
    gap() => SizedBox(width: m.fs * 0.5);
    return Row(children: [
      if (left) ...[bracket, gap()] else ...[infBtn, gap()],
      Expanded(child: mid),
      if (left) ...[gap(), infBtn] else ...[gap(), bracket],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final a = s.analysis;
        final summary = a != null
            ? '${a.f.name}(x) = ${a.f.body} · ${a.rn} = ${a.range.notation}'
            : (s.error ?? '');
        Widget presets(String l1, String l2) => Padding(
              padding: EdgeInsets.only(bottom: m.fs * 0.5),
              child: Row(children: [
                Expanded(child: DarkBtn(label: l1, scale: 0.95, onTap: () => _preset(l1))),
                SizedBox(width: m.fs * 0.5),
                Expanded(child: DarkBtn(label: l2, scale: 0.95, onTap: () => _preset(l2))),
              ]),
            );
        return WatchPage(
          title: 'Input',
          children: [
            const Lbl('Function'),
            _field(_expr, (v) => s.expr = v, hint: 'f(x) = 4x^2 - 3x'),
            if (_hasA) ...[
              const Lbl('Condition for a'),
              _field(_cond, (v) => s.condition = v, hint: 'h(1) = 2'),
            ],
            const Lbl('Domain'),
            Row(children: [
              Expanded(
                child: DarkBtn(
                    label: 'Interval',
                    active: !s.discrete,
                    onTap: () {
                      setState(() => s.discrete = false);
                      s.analyze();
                    }),
              ),
              SizedBox(width: m.fs * 0.5),
              Expanded(
                child: DarkBtn(
                    label: 'Set',
                    active: s.discrete,
                    onTap: () {
                      setState(() => s.discrete = true);
                      s.analyze();
                    }),
              ),
            ]),
            if (s.discrete) ...[
              const Lbl('Discrete set'),
              _field(_set, (v) => s.setText = v, hint: '-2, 0, 1, 2, 4'),
            ] else ...[
              const Lbl('Left bound'),
              _boundRow(true),
              const Lbl('Right bound'),
              _boundRow(false),
            ],
            const Lbl('Query points'),
            _field(_query, (v) => s.query = v, hint: '-2, 1, 5'),
            Padding(
              padding: EdgeInsets.symmetric(vertical: m.fs * 0.8),
              child: Text(summary,
                  style: mono(context, color: a != null ? C.muted : C.amber, scale: 0.85)),
            ),
            presets('Quadratic', 'Solve a'),
            presets('Discrete', 'Half-open'),
            SizedBox(height: m.fs * 0.3),
            SizedBox(
              height: m.btn,
              child: Material(
                color: C.amber,
                borderRadius: BorderRadius.circular(m.fs * 1.2),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    s.analyze();
                    if (s.error == null) widget.onSolved();
                  },
                  child: Center(
                    child: Text('Solve', style: sans(context, color: Colors.black, bold: true, scale: 1.1)),
                  ),
                ),
              ),
            ),
            SizedBox(height: m.fs * 0.6),
          ],
        );
      },
    );
  }

  void _preset(String id) {
    s.preset(id);
    setState(_syncControllers);
  }
}
