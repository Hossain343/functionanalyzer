import 'domain.dart';
import 'engine.dart';
import 'range.dart';
import 'rational.dart';
import 'text.dart';

class EvalResult {
  const EvalResult({required this.x, required this.inDomain, required this.label, required this.steps, this.y});
  final Rational x;
  final bool inDomain;
  final String label; // f(-2)
  final List<String> steps; // right-hand sides, one per line
  final Rational? y;
}

/// A mark on the number line.
class Mark {
  const Mark(this.x, this.kind, {this.closed = true});
  final Rational x;
  final String kind; // point | bound | query | outside
  final bool closed;
}

class Analysis {
  Analysis(this.f, this.domain, this.paramLines, this.evals, this.table, this.range);

  final FunctionModel f;
  final Domain domain;
  final List<String> paramLines;
  final List<EvalResult> evals;
  final List<KeyRow> table;
  final RangeInfo range;

  String get dn => 'D${f.name}';
  String get rn => 'R${f.name}';
  String label(Rational x) => '${f.name}($x)';

  List<Mark> get marks {
    final out = <Mark>[];
    final l = domain.lo, h = domain.hi;
    if (domain.discrete) {
      for (final p in domain.points) {
        out.add(Mark(p, 'point'));
      }
    } else {
      if (l != null) out.add(Mark(l, 'bound', closed: domain.loClosed));
      if (h != null) out.add(Mark(h, 'bound', closed: domain.hiClosed));
    }
    for (final e in evals) {
      if (!e.inDomain) {
        out.add(Mark(e.x, 'outside'));
      } else if (!domain.discrete) {
        out.add(Mark(e.x, 'query'));
      }
    }
    return out;
  }

  static Analysis run({
    required String exprText,
    required Domain domain,
    required String condition,
    required String queryText,
  }) {
    final fn = ExprParser.parseFunction(exprText);
    var poly = fn.poly;
    var paramLines = <String>[];
    if (poly.hasA) {
      if (condition.trim().isEmpty) {
        throw const FormatException('Unknown constant a: enter a condition like h(1) = 2');
      }
      final sol = solveParam(fn.name, poly, condition);
      poly = sol.poly;
      paramLines = sol.lines;
    }
    final f = FunctionModel(fn.name, poly.xCoeffs());

    final queries = <Rational>[];
    for (final part in normalizeInput(queryText).split(RegExp(r'[,;]'))) {
      final t = part.trim();
      if (t.isEmpty) continue;
      try {
        queries.add(parseConstant(t));
      } on FormatException {
        throw FormatException('Bad query point "$t"');
      }
    }

    final evals = <EvalResult>[];
    for (final x in queries) {
      final label = '${f.name}($x)';
      if (!domain.contains(x)) {
        evals.add(EvalResult(x: x, inDomain: false, label: label, steps: const []));
      } else {
        evals.add(EvalResult(x: x, inDomain: true, label: label, steps: f.stepsAt(x), y: f.eval(x)));
      }
    }
    return Analysis(f, domain, paramLines, evals, keyPoints(domain, f), computeRange(domain, f));
  }
}
