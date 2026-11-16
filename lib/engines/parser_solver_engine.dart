import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';
import '../models/function_problem.dart';

class ParsedFunctionResult {
  final String fnName;
  final String rhsText;
  final Expression? expression;
  final bool hasParameterA;
  final bool hasParameterB;
  final String? error;

  const ParsedFunctionResult({
    required this.fnName,
    required this.rhsText,
    required this.expression,
    required this.hasParameterA,
    this.hasParameterB = false,
    this.error,
  });
}

class ParameterSolveOutput {
  final double? solvedA;
  final double? solvedB;
  final List<String> steps;
  final String? error;

  const ParameterSolveOutput({
    required this.solvedA,
    this.solvedB,
    required this.steps,
    this.error,
  });
}

class ParsedDomainExpression {
  final DomainMode domainMode;
  final String lo;
  final bool loInc;
  final String hi;
  final bool hiInc;
  final String excluded;
  final String discrete;
  final String? error;

  const ParsedDomainExpression({
    required this.domainMode,
    required this.lo,
    required this.loInc,
    required this.hi,
    required this.hiInc,
    this.excluded = '',
    this.discrete = '',
    this.error,
  });
}

class TargetConditionResult {
  final String op; // '=', '<', '<=', '>', '>='
  final double targetY;
  final List<InverseSolution> equalitySolutions;
  final String notation;

  const TargetConditionResult({
    required this.op,
    required this.targetY,
    required this.equalitySolutions,
    required this.notation,
  });
}

class ParserSolverEngine {
  final ExpressionParser _parser = GrammarParser();

  String normalizeDigitsAndSymbols(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      final pIdx = persian.indexOf(ch);
      final aIdx = arabic.indexOf(ch);
      if (pIdx != -1) {
        buf.write(pIdx);
      } else if (aIdx != -1) {
        buf.write(aIdx);
      } else if (ch == '،') {
        buf.write(',');
      } else if (ch == '×') {
        buf.write('*');
      } else if (ch == '÷') {
        buf.write('/');
      } else if (ch == '−') {
        buf.write('-');
      } else if (ch == '²') {
        buf.write('^2');
      } else if (ch == '³') {
        buf.write('^3');
      } else {
        buf.write(ch);
      }
    }
    return buf.toString().replaceAll('√(', 'sqrt(');
  }

  ParsedFunctionResult tryParseFunction(String rawInput) {
    final trimmed = normalizeDigitsAndSymbols(rawInput).trim();
    if (trimmed.isEmpty) {
      return const ParsedFunctionResult(
        fnName: 'f',
        rhsText: '',
        expression: null,
        hasParameterA: false,
        hasParameterB: false,
        error: 'Enter a function (e.g. g(x)=4*x^2-3*x)',
      );
    }

    String fnName = 'f';
    String rhs = trimmed;

    final eqIdx = trimmed.indexOf('=');
    if (eqIdx != -1) {
      final lhs = trimmed.substring(0, eqIdx).trim();
      rhs = trimmed.substring(eqIdx + 1).trim();
      final match = RegExp(r'^([a-zA-Z])\s*\(\s*x\s*\)$').firstMatch(lhs);
      if (match == null) {
        return const ParsedFunctionResult(
          fnName: 'f',
          rhsText: '',
          expression: null,
          hasParameterA: false,
          hasParameterB: false,
          error: 'Format left side like f(x) = ... or enter expression only.',
        );
      }
      fnName = match.group(1)!;
    }

    if (rhs.isEmpty) {
      return ParsedFunctionResult(
        fnName: fnName,
        rhsText: '',
        expression: null,
        hasParameterA: false,
        hasParameterB: false,
        error: 'Right-hand side cannot be empty.',
      );
    }

    try {
      final expr = parseExpression(rhs);
      final cleaned = rhs.replaceAll('abs', '   ');
      final hasA = RegExp(r'(?<![a-zA-Z])a(?![a-zA-Z])').hasMatch(cleaned) ||
          RegExp(r'\da|\ba\d|ax|xa|ab|ba').hasMatch(cleaned);
      final hasB = RegExp(r'(?<![a-zA-Z])b(?![a-zA-Z])').hasMatch(cleaned) ||
          RegExp(r'\db|\bb\d|bx|xb|ab|ba').hasMatch(cleaned);
      return ParsedFunctionResult(
        fnName: fnName,
        rhsText: rhs,
        expression: expr,
        hasParameterA: hasA,
        hasParameterB: hasB,
      );
    } catch (_) {
      return ParsedFunctionResult(
        fnName: fnName,
        rhsText: rhs,
        expression: null,
        hasParameterA: false,
        hasParameterB: false,
        error: 'Invalid expression syntax.',
      );
    }
  }

  Expression parseExpression(String rawInput) {
    String rhs = rawInput.contains('=')
        ? rawInput.split('=').last.trim()
        : rawInput.trim();
    rhs = normalizeDigitsAndSymbols(rhs);

    // Convert |...| to abs(...)
    while (rhs.contains('|')) {
      final first = rhs.indexOf('|');
      final second = rhs.indexOf('|', first + 1);
      if (second == -1) {
        throw const FormatException('Unclosed absolute value bar');
      }
      rhs =
          '${rhs.substring(0, first)}abs(${rhs.substring(first + 1, second)})${rhs.substring(second + 1)}';
    }

    // Protect built-in function names before splitting implicit multiplications
    var normalized = rhs
        .replaceAll(' ', '')
        .replaceAll('abs(', '__ABS__(')
        .replaceAll('sqrt(', '__SQRT__(')
        .replaceAllMapped(RegExp(r'(\d)([xabXAB(])'), (m) => '${m[1]}*${m[2]}')
        .replaceAllMapped(RegExp(r'([\dxabXAB)])(__ABS__|__SQRT__)'), (m) => '${m[1]}*${m[2]}')
        .replaceAllMapped(RegExp(r'(\))([\dxabXAB(])'), (m) => '${m[1]}*${m[2]}')
        .replaceAllMapped(RegExp(r'([xabXAB])(\()'), (m) => '${m[1]}*${m[2]}')
        .replaceAll('ax', 'a*x')
        .replaceAll('xa', 'x*a')
        .replaceAll('bx', 'b*x')
        .replaceAll('xb', 'x*b')
        .replaceAll('ab', 'a*b')
        .replaceAll('ba', 'b*a')
        .replaceAll('__ABS__(', 'abs(')
        .replaceAll('__SQRT__(', 'sqrt(');
    return _parser.parse(normalized);
  }

  double evaluate(Expression expr, double x, {double a = 0, double b = 0}) {
    final cm = ContextModel()
      ..bindVariable(Variable('x'), Number(x))
      ..bindVariable(Variable('a'), Number(a))
      ..bindVariable(Variable('b'), Number(b));
    final val = expr.evaluate(EvaluationType.REAL, cm);
    if (val is num) return val.toDouble();
    return double.nan;
  }

  double? solveParameterA(Expression expr, double x0, double y0) {
    final f0 = evaluate(expr, x0, a: 0);
    final f1 = evaluate(expr, x0, a: 1);
    if (!f0.isFinite || !f1.isFinite) return null;
    final slope = f1 - f0;
    if (slope.abs() > 1e-9) {
      return (y0 - f0) / slope;
    }
    return null;
  }

  String _formatLinearCombo(double p, double q) {
    final parts = <String>[];
    if (p.abs() >= 1e-9) {
      parts.add((p - 1).abs() < 1e-9
          ? 'a'
          : (p + 1).abs() < 1e-9
              ? '-a'
              : '${formatCompactNum(p)}a');
    }
    if (q.abs() >= 1e-9) {
      final absQ = q.abs();
      final term = (absQ - 1).abs() < 1e-9 ? 'b' : '${formatCompactNum(absQ)}b';
      if (parts.isEmpty) {
        parts.add(q < 0 ? '-$term' : term);
      } else {
        parts.add(q < 0 ? ' - $term' : ' + $term');
      }
    }
    return parts.isEmpty ? '0' : parts.join();
  }

  ParameterSolveOutput solveParameterAWithSteps({
    required String fnName,
    required Expression expr,
    required String rawRhs,
    required double? x0,
    required double? y0,
  }) {
    return solveParametersWithSteps(
      fnName: fnName,
      expr: expr,
      rawRhs: rawRhs,
      hasA: true,
      hasB: false,
      x1: x0,
      y1: y0,
    );
  }

  ParameterSolveOutput solveParametersWithSteps({
    required String fnName,
    required Expression expr,
    required String rawRhs,
    required bool hasA,
    required bool hasB,
    required double? x1,
    required double? y1,
    double? x2,
    double? y2,
  }) {
    if (!hasA && !hasB) {
      return const ParameterSolveOutput(solvedA: null, solvedB: null, steps: []);
    }

    // Two-unknown system solver (a & b)
    if (hasA && hasB) {
      if (x1 == null || y1 == null || x2 == null || y2 == null) {
        return const ParameterSolveOutput(
          solvedA: null,
          solvedB: null,
          steps: [],
          error: 'Provide 2 conditions f(x₁)=y₁ and f(x₂)=y₂.',
        );
      }

      final c1 = evaluate(expr, x1, a: 0, b: 0);
      final p1 = evaluate(expr, x1, a: 1, b: 0) - c1;
      final q1 = evaluate(expr, x1, a: 0, b: 1) - c1;
      final chk1 = evaluate(expr, x1, a: 2, b: 3) - (c1 + 2 * p1 + 3 * q1);

      final c2 = evaluate(expr, x2, a: 0, b: 0);
      final p2 = evaluate(expr, x2, a: 1, b: 0) - c2;
      final q2 = evaluate(expr, x2, a: 0, b: 1) - c2;
      final chk2 = evaluate(expr, x2, a: 2, b: 3) - (c2 + 2 * p2 + 3 * q2);

      if (!c1.isFinite || !p1.isFinite || !q1.isFinite || !c2.isFinite || !p2.isFinite || !q2.isFinite) {
        return const ParameterSolveOutput(
          solvedA: null,
          solvedB: null,
          steps: [],
          error: 'Expression undefined at condition points.',
        );
      }
      if (chk1.abs() > 1e-6 || chk2.abs() > 1e-6) {
        return const ParameterSolveOutput(
          solvedA: null,
          solvedB: null,
          steps: [],
          error: '2-unknown solver expects linear combinations in (a, b).',
        );
      }

      final det = p1 * q2 - p2 * q1;
      if (det.abs() <= 1e-9) {
        return const ParameterSolveOutput(
          solvedA: null,
          solvedB: null,
          steps: [],
          error: 'Equations are dependent (Δ=0). Pick distinct x₁ ≠ x₂.',
        );
      }

      final rhs1 = y1 - c1;
      final rhs2 = y2 - c2;
      final aVal = (rhs1 * q2 - rhs2 * q1) / det;
      final bVal = (p1 * rhs2 - p2 * rhs1) / det;

      final x1s = formatCompactNum(x1);
      final y1s = formatCompactNum(y1);
      final x2s = formatCompactNum(x2);
      final y2s = formatCompactNum(y2);

      return ParameterSolveOutput(
        solvedA: aVal,
        solvedB: bVal,
        steps: [
          'Given: $fnName($x1s)=$y1s, $fnName($x2s)=$y2s',
          '(1) ${_formatLinearCombo(p1, q1)} = ${formatCompactNum(rhs1)}',
          '(2) ${_formatLinearCombo(p2, q2)} = ${formatCompactNum(rhs2)}',
          'a = ${formatCompactNum(aVal)},  b = ${formatCompactNum(bVal)}',
        ],
      );
    }

    // Single unknown ('a' or 'b')
    final paramName = hasA ? 'a' : 'b';
    if (x1 == null || y1 == null) {
      return ParameterSolveOutput(
        solvedA: null,
        solvedB: null,
        steps: const [],
        error: 'Provide x₀ and y₀ to solve parameter $paramName.',
      );
    }

    double evalParam(double val) =>
        hasA ? evaluate(expr, x1, a: val, b: 0) : evaluate(expr, x1, a: 0, b: val);

    final f0 = evalParam(0);
    final f1 = evalParam(1);
    final f2 = evalParam(2);
    if (!f0.isFinite || !f1.isFinite) {
      return const ParameterSolveOutput(
        solvedA: null,
        solvedB: null,
        steps: [],
        error: 'Cannot evaluate condition x₀.',
      );
    }

    final slope = f1 - f0;
    final secondDiff = (f2 - f1) - slope;
    final xStr = formatCompactNum(x1);
    final yStr = formatCompactNum(y1);

    if (secondDiff.abs() < 1e-7) {
      if (slope.abs() <= 1e-9) {
        return ParameterSolveOutput(
          solvedA: null,
          solvedB: null,
          steps: const [],
          error: 'Cannot uniquely solve $paramName at this condition.',
        );
      }

      final pVal = (y1 - f0) / slope;
      final sub = normalizeDigitsAndSymbols(rawRhs).replaceAllMapped(
        RegExp(r'(?<![a-zA-Z])x(?![a-zA-Z])'),
        (_) => '($xStr)',
      );
      final coeffStr = (slope - 1).abs() < 1e-8
          ? paramName
          : (slope + 1).abs() < 1e-8
              ? '-$paramName'
              : '${formatCompactNum(slope)}$paramName';
      final constStr = f0.abs() < 1e-9
          ? ''
          : f0 > 0
              ? ' + ${formatCompactNum(f0)}'
              : ' - ${formatCompactNum(f0.abs())}';

      return ParameterSolveOutput(
        solvedA: hasA ? pVal : null,
        solvedB: hasB ? pVal : null,
        steps: [
          'Given: $fnName($xStr) = $yStr',
          '$sub = $yStr',
          '$coeffStr$constStr = $yStr',
          '$paramName = ${formatCompactNum(pVal)}',
        ],
      );
    }

    // Nonlinear fallback via bisection in [-50, 50]
    double? found;
    double prevP = -50.0;
    double prevErr = evalParam(prevP) - y1;
    for (double probe = -49.5; probe <= 50.0; probe += 0.5) {
      final err = evalParam(probe) - y1;
      if (err.isFinite && prevErr.isFinite && prevErr * err <= 0) {
        double lo = prevP;
        double hi = probe;
        for (int iter = 0; iter < 50; iter++) {
          final mid = (lo + hi) / 2;
          final mErr = evalParam(mid) - y1;
          if ((evalParam(lo) - y1) * mErr <= 0) {
            hi = mid;
          } else {
            lo = mid;
          }
        }
        found = (lo + hi) / 2;
        break;
      }
      prevP = probe;
      prevErr = err;
    }

    if (found == null) {
      return ParameterSolveOutput(
        solvedA: null,
        solvedB: null,
        steps: const [],
        error: 'No real solution found for $paramName.',
      );
    }

    return ParameterSolveOutput(
      solvedA: hasA ? found : null,
      solvedB: hasB ? found : null,
      steps: [
        'Given: $fnName($xStr) = $yStr',
        'Numeric solve: $paramName = ${formatCompactNum(found)}',
      ],
    );
  }

  /// Splits top-level + and - terms to show intermediate arithmetic steps like "= 16 + 6".
  List<String> _splitTopLevelTerms(String rawRhs) {
    final cleaned = normalizeDigitsAndSymbols(rawRhs).replaceAll(' ', '');
    final terms = <String>[];
    int depth = 0;
    int barCount = 0;
    int start = 0;

    for (int i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      if (ch == '(') depth++;
      if (ch == ')') depth = math.max(0, depth - 1);
      if (ch == '|') barCount++;
      final insideBars = barCount % 2 == 1;

      if (depth == 0 && !insideBars && i > start && (ch == '+' || ch == '-')) {
        final prev = cleaned[i - 1];
        if (prev != '^' && prev != '*' && prev != '/' && prev != '+' && prev != '-') {
          terms.add(cleaned.substring(start, i));
          start = i;
        }
      }
    }
    if (start < cleaned.length) {
      terms.add(cleaned.substring(start));
    }
    return terms;
  }

  EvaluationStepResult evaluatePoint({
    required String fnName,
    required Expression expr,
    required String rawExpr,
    required DomainSpec domain,
    required double x,
    double a = 0,
    double b = 0,
  }) {
    if (!domain.contains(x)) {
      return EvaluationStepResult(
        x: x,
        inDomain: false,
        y: null,
        steps: [
          '${formatCompactNum(x)} ∉ Df (${domain.toIntervalNotation()})',
          'Undefined (Outside Domain)',
        ],
      );
    }

    final y = evaluate(expr, x, a: a, b: b);
    if (!y.isFinite) {
      return EvaluationStepResult(
        x: x,
        inDomain: true,
        y: null,
        steps: [
          '${formatCompactNum(x)} ∈ Df',
          'Undefined (Invalid domain math)',
        ],
      );
    }

    final xStr = formatCompactNum(x);
    final aStr = formatCompactNum(a);
    final bStr = formatCompactNum(b);
    final substituted = normalizeDigitsAndSymbols(rawExpr)
        .replaceAll('ax', 'a*x')
        .replaceAll('xa', 'x*a')
        .replaceAll('bx', 'b*x')
        .replaceAll('xb', 'x*b')
        .replaceAllMapped(RegExp(r'(?<![a-zA-Z])x(?![a-zA-Z])'), (_) => '($xStr)')
        .replaceAllMapped(RegExp(r'(?<![a-zA-Z])a(?![a-zA-Z])'), (_) => '($aStr)')
        .replaceAllMapped(RegExp(r'(?<![a-zA-Z])b(?![a-zA-Z])'), (_) => '($bStr)');

    final steps = <String>['$fnName($xStr) = $substituted'];

    final terms = _splitTopLevelTerms(rawExpr);
    if (terms.length > 1) {
      final termVals = <double>[];
      bool allOk = true;
      for (final t in terms) {
        try {
          final tExpr = parseExpression(t);
          final tv = evaluate(tExpr, x, a: a, b: b);
          if (!tv.isFinite) {
            allOk = false;
            break;
          }
          termVals.add(tv);
        } catch (_) {
          allOk = false;
          break;
        }
      }
      if (allOk && termVals.length > 1) {
        final buf = StringBuffer();
        for (int i = 0; i < termVals.length; i++) {
          final v = termVals[i];
          if (i == 0) {
            buf.write(formatCompactNum(v));
          } else if (v >= 0) {
            buf.write(' + ${formatCompactNum(v)}');
          } else {
            buf.write(' - ${formatCompactNum(v.abs())}');
          }
        }
        final intermediate = buf.toString();
        if (intermediate != formatCompactNum(y) && intermediate != substituted) {
          steps.add('= $intermediate');
        }
      }
    }

    steps.add('= ${formatCompactNum(y)}');
    return EvaluationStepResult(
      x: x,
      inDomain: true,
      y: y,
      steps: steps,
    );
  }

  List<TableEntry> parseTableEntries(String raw) {
    final cleaned = normalizeDigitsAndSymbols(raw).trim();
    if (cleaned.isEmpty) return [];
    final list = <TableEntry>[];
    for (final chunk in cleaned.split(',')) {
      final parts = chunk.split(':');
      if (parts.length != 2) continue;
      final x = double.tryParse(parts[0].trim());
      final y = double.tryParse(parts[1].trim());
      if (x != null && y != null && x.isFinite && y.isFinite) {
        if (!list.any((e) => (e.x - x).abs() < 1e-7)) {
          list.add(TableEntry(x: x, y: y));
        }
      }
    }
    list.sort((a, b) => a.x.compareTo(b.x));
    return list;
  }

  EvaluationStepResult evaluateTablePoint({
    required String fnName,
    required List<TableEntry> table,
    required double x,
  }) {
    final idx = table.indexWhere((e) => (e.x - x).abs() < 1e-7);
    if (idx == -1) {
      final domain = DomainSpec.discrete(table.map((e) => e.x).toList());
      return EvaluationStepResult(
        x: x,
        inDomain: false,
        y: null,
        steps: [
          '${formatCompactNum(x)} ∉ Df (${domain.toIntervalNotation()})',
          'Undefined (Outside Domain)',
        ],
      );
    }
    final entry = table[idx];
    return EvaluationStepResult(
      x: x,
      inDomain: true,
      y: entry.y,
      steps: [
        'From table: x = ${formatCompactNum(x)} ∈ Df',
        '$fnName(${formatCompactNum(x)}) = ${formatCompactNum(entry.y)}',
      ],
    );
  }

  RangeSpec computeTableRange(List<TableEntry> table) {
    final outs = table.map((e) => e.y).toSet().toList()..sort();
    return RangeSpec(
      min: outs.isEmpty ? null : outs.first,
      max: outs.isEmpty ? null : outs.last,
      discreteOutputs: outs,
    );
  }

  List<double> parseNumberList(String raw) {
    final cleaned = normalizeDigitsAndSymbols(raw).replaceAll('{', '').replaceAll('}', '').trim();
    if (cleaned.isEmpty) return [];
    final out = <double>[];
    for (final part in cleaned.split(',')) {
      final v = double.tryParse(part.trim());
      if (v != null && v.isFinite) {
        out.add(v);
      }
    }
    return out;
  }

  List<KeyPoint> computeKeyPoints(
    Expression expr,
    DomainSpec domain, {
    double a = 0,
    double b = 0,
  }) {
    if (domain.mode == DomainMode.discrete) {
      final sorted = [...domain.discreteValues]..sort();
      return sorted.map((x) {
        final y = evaluate(expr, x, a: a, b: b);
        return KeyPoint(
          x: x,
          y: y.isFinite ? y : null,
          role: 'Discrete',
        );
      }).toList();
    }

    final lo = domain.lowerBound ?? (domain.upperBound != null ? domain.upperBound! - 4 : 0.0);
    final hi = domain.upperBound ?? (domain.lowerBound != null ? domain.lowerBound! + 4 : 4.0);
    final candidates = <KeyPoint>[];

    if (domain.lowerBound != null) {
      final y = evaluate(expr, domain.lowerBound!, a: a, b: b);
      final open = !domain.lowerInclusive || !domain.contains(domain.lowerBound!);
      candidates.add(
        KeyPoint(
          x: domain.lowerBound!,
          y: y.isFinite ? y : null,
          isEndpoint: true,
          isOpenEndpoint: open,
          role: open ? 'Open Left' : 'Closed Left',
        ),
      );
    }

    final y0 = evaluate(expr, 0, a: a, b: b);
    final y1 = evaluate(expr, 1, a: a, b: b);
    final ym1 = evaluate(expr, -1, a: a, b: b);
    final y2 = evaluate(expr, 2, a: a, b: b);
    if (y0.isFinite && y1.isFinite && ym1.isFinite && y2.isFinite) {
      final coeffA = (y1 + ym1 - 2 * y0) / 2;
      final coeffB = (y1 - ym1) / 2;
      if (coeffA.abs() > 1e-8 && (4 * coeffA + 2 * coeffB + y0 - y2).abs() < 1e-6) {
        final vx = -coeffB / (2 * coeffA);
        if (vx > lo + 1e-6 && vx < hi - 1e-6 && domain.contains(vx)) {
          final vy = evaluate(expr, vx, a: a, b: b);
          candidates.add(
            KeyPoint(
              x: vx,
              y: vy.isFinite ? vy : null,
              isExtremum: true,
              role: 'Vertex',
            ),
          );
        }
      }
    }

    final span = math.max(1.0, hi - lo);
    final step = span <= 8 ? 1 : span <= 20 ? 2 : (span / 6).ceil();
    for (int x = lo.ceil(); x <= hi.floor(); x += step) {
      final xd = x.toDouble();
      if (domain.contains(xd) &&
          !candidates.any((c) => (c.x - xd).abs() < 1e-5)) {
        final y = evaluate(expr, xd, a: a, b: b);
        candidates.add(
          KeyPoint(
            x: xd,
            y: y.isFinite ? y : null,
            role: 'Interior',
          ),
        );
      }
    }

    if (domain.upperBound != null) {
      final y = evaluate(expr, domain.upperBound!, a: a, b: b);
      final open = !domain.upperInclusive || !domain.contains(domain.upperBound!);
      candidates.add(
        KeyPoint(
          x: domain.upperBound!,
          y: y.isFinite ? y : null,
          isEndpoint: true,
          isOpenEndpoint: open,
          role: open ? 'Open Right' : 'Closed Right',
        ),
      );
    }

    candidates.sort((p1, p2) => p1.x.compareTo(p2.x));
    return candidates;
  }

  RangeSpec computeRange(
    Expression expr,
    DomainSpec domain, {
    double a = 0,
    double b = 0,
  }) {
    if (domain.mode == DomainMode.discrete) {
      final outs = domain.discreteValues
          .map((x) => evaluate(expr, x, a: a, b: b))
          .where((y) => y.isFinite)
          .toSet()
          .toList()
        ..sort();
      return RangeSpec(
        min: outs.isEmpty ? null : outs.first,
        max: outs.isEmpty ? null : outs.last,
        discreteOutputs: outs,
      );
    }

    final lo = domain.lowerBound ?? -15.0;
    final hi = domain.upperBound ?? 15.0;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final samples = <double>[];
    const count = 500;
    for (int i = 0; i <= count; i++) {
      final x = lo + (hi - lo) * i / count;
      if (domain.contains(x) || i == 0 || i == count) {
        samples.add(x);
      }
    }

    final y0 = evaluate(expr, 0, a: a, b: b);
    final y1 = evaluate(expr, 1, a: a, b: b);
    final ym1 = evaluate(expr, -1, a: a, b: b);
    final y2 = evaluate(expr, 2, a: a, b: b);
    if (y0.isFinite && y1.isFinite && ym1.isFinite && y2.isFinite) {
      final coeffA = (y1 + ym1 - 2 * y0) / 2;
      final coeffB = (y1 - ym1) / 2;
      if (coeffA.abs() > 1e-8 && (4 * coeffA + 2 * coeffB + y0 - y2).abs() < 1e-6) {
        final vx = -coeffB / (2 * coeffA);
        if (vx >= lo && vx <= hi && domain.contains(vx)) samples.add(vx);
      }
    }

    for (final x in samples) {
      final y = evaluate(expr, x, a: a, b: b);
      if (y.isFinite && y.abs() < 1e6) {
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    if (!minY.isFinite || !maxY.isFinite) {
      return const RangeSpec();
    }

    double? finalMin = minY;
    double? finalMax = maxY;
    if (domain.lowerBound == null || domain.upperBound == null) {
      final probeL = domain.lowerBound == null ? -200.0 : lo;
      final probeR = domain.upperBound == null ? 200.0 : hi;
      final yL = evaluate(expr, probeL, a: a, b: b);
      final yR = evaluate(expr, probeR, a: a, b: b);
      if ((domain.lowerBound == null && yL.isFinite && yL < minY - 25) ||
          (domain.upperBound == null && yR.isFinite && yR < minY - 25)) {
        finalMin = null;
      }
      if ((domain.lowerBound == null && yL.isFinite && yL > maxY + 25) ||
          (domain.upperBound == null && yR.isFinite && yR > maxY + 25)) {
        finalMax = null;
      }
    }

    final yLo = domain.lowerBound != null
        ? evaluate(expr, domain.lowerBound!, a: a, b: b)
        : double.nan;
    final yHi = domain.upperBound != null
        ? evaluate(expr, domain.upperBound!, a: a, b: b)
        : double.nan;

    bool minClosed = finalMin != null;
    bool maxClosed = finalMax != null;
    final attainedInteriorMin = samples.any((x) {
      final atOpenLeft = domain.lowerBound != null &&
          !domain.lowerInclusive &&
          (x - domain.lowerBound!).abs() < 1e-4;
      final atOpenRight = domain.upperBound != null &&
          !domain.upperInclusive &&
          (x - domain.upperBound!).abs() < 1e-4;
      if (atOpenLeft || atOpenRight) return false;
      final y = evaluate(expr, x, a: a, b: b);
      return y.isFinite && (y - minY).abs() < 1e-4;
    });
    final attainedInteriorMax = samples.any((x) {
      final atOpenLeft = domain.lowerBound != null &&
          !domain.lowerInclusive &&
          (x - domain.lowerBound!).abs() < 1e-4;
      final atOpenRight = domain.upperBound != null &&
          !domain.upperInclusive &&
          (x - domain.upperBound!).abs() < 1e-4;
      if (atOpenLeft || atOpenRight) return false;
      final y = evaluate(expr, x, a: a, b: b);
      return y.isFinite && (y - maxY).abs() < 1e-4;
    });

    if (finalMin != null && !attainedInteriorMin) {
      if ((yLo.isFinite && (yLo - minY).abs() < 1e-4 && !domain.lowerInclusive) ||
          (yHi.isFinite && (yHi - minY).abs() < 1e-4 && !domain.upperInclusive)) {
        minClosed = false;
      }
    }
    if (finalMax != null && !attainedInteriorMax) {
      if ((yLo.isFinite && (yLo - maxY).abs() < 1e-4 && !domain.lowerInclusive) ||
          (yHi.isFinite && (yHi - maxY).abs() < 1e-4 && !domain.upperInclusive)) {
        maxClosed = false;
      }
    }

    return RangeSpec(
      min: finalMin,
      minInclusive: minClosed,
      max: finalMax,
      maxInclusive: maxClosed,
    );
  }

  List<InverseSolution> solveInverseTarget({
    required String fnName,
    required FunctionInputMode inputMode,
    required Expression? expr,
    required List<TableEntry> table,
    required DomainSpec domain,
    required double targetY,
    double a = 0,
    double b = 0,
  }) {
    if (!targetY.isFinite) return [];
    final solutions = <InverseSolution>[];

    if (inputMode == FunctionInputMode.table) {
      for (final e in table) {
        if ((e.y - targetY).abs() < 1e-6) {
          solutions.add(
            InverseSolution(
              x: e.x,
              steps: [
                '$fnName(${formatCompactNum(e.x)}) = ${formatCompactNum(e.y)}',
              ],
            ),
          );
        }
      }
      return solutions;
    }

    if (expr == null) return [];

    void addCandidate(double rawX) {
      final cleanX = rawX.abs() < 1e-7 ? 0.0 : double.parse(rawX.toStringAsFixed(5));
      if (!domain.contains(cleanX)) return;
      if (solutions.any((s) => (s.x - cleanX).abs() < 1e-4)) return;
      final checkY = evaluate(expr, cleanX, a: a, b: b);
      if (!checkY.isFinite || (checkY - targetY).abs() > 1e-3) return;
      solutions.add(
        InverseSolution(
          x: cleanX,
          steps: [
            'x = ${formatCompactNum(cleanX)} ($fnName(${formatCompactNum(cleanX)}) = ${formatCompactNum(checkY)})',
          ],
        ),
      );
    }

    if (domain.mode == DomainMode.discrete) {
      for (final x in domain.discreteValues) {
        final y = evaluate(expr, x, a: a, b: b);
        if (y.isFinite && (y - targetY).abs() < 1e-6) {
          addCandidate(x);
        }
      }
      return solutions;
    }

    final lo = domain.lowerBound ?? -20.0;
    final hi = domain.upperBound ?? 20.0;
    const steps = 400;
    double prevX = lo;
    double prevDiff = evaluate(expr, prevX, a: a, b: b) - targetY;
    if (prevDiff.isFinite && prevDiff.abs() < 1e-6) addCandidate(prevX);

    for (int i = 1; i <= steps; i++) {
      final x = lo + (hi - lo) * i / steps;
      final diff = evaluate(expr, x, a: a, b: b) - targetY;
      if (diff.isFinite) {
        if (diff.abs() < 1e-6) {
          addCandidate(x);
        } else if (prevDiff.isFinite && prevDiff * diff < 0 && (prevDiff - diff).abs() < 1e3) {
          double left = prevX;
          double right = x;
          double fL = prevDiff;
          for (int iter = 0; iter < 40; iter++) {
            final mid = (left + right) / 2;
            final fM = evaluate(expr, mid, a: a, b: b) - targetY;
            if (!fM.isFinite) break;
            if (fL * fM <= 0) {
              right = mid;
            } else {
              left = mid;
              fL = fM;
            }
          }
          addCandidate((left + right) / 2);
        }
      }
      prevX = x;
      prevDiff = diff;
    }

    solutions.sort((s1, s2) => s1.x.compareTo(s2.x));
    return solutions;
  }

  String _normalizeComparison(String raw) {
    return normalizeDigitsAndSymbols(raw)
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        .replaceAll('≠', '!=')
        .replaceAll('∞', 'inf')
        .trim();
  }

  ParsedDomainExpression? parseDomainExpression(String raw) {
    var text = _normalizeComparison(raw);
    if (text.isEmpty) return null;

    var excluded = '';
    final barIdx = text.indexOf('|');
    if (text.startsWith('{') && text.endsWith('}') && barIdx != -1) {
      text = text.substring(barIdx + 1, text.length - 1).trim();
    }

    final exclDiff = RegExp(r'-\s*\{([^}]+)\}\s*$').firstMatch(text);
    if (exclDiff != null) {
      excluded = exclDiff.group(1)!.trim();
      text = text.substring(0, exclDiff.start).trim();
    }
    final exclNeq = RegExp(r',\s*x\s*!=\s*(.+)$', caseSensitive: false).firstMatch(text);
    if (exclNeq != null) {
      excluded = exclNeq.group(1)!.trim();
      text = text.substring(0, exclNeq.start).trim();
    }

    if (RegExp(r'^[ℝr]$').hasMatch(text)) {
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: '-inf',
        loInc: false,
        hi: '+inf',
        hiInc: false,
        excluded: excluded,
      );
    }

    final discMatch = RegExp(r'^\{([^}]+)\}$').firstMatch(text);
    if (discMatch != null && !text.contains('x')) {
      return ParsedDomainExpression(
        domainMode: DomainMode.discrete,
        lo: '-inf',
        loInc: false,
        hi: '+inf',
        hiInc: false,
        discrete: discMatch.group(1)!.trim(),
      );
    }

    final intervalMatch =
        RegExp(r'^([[(])\s*([^,]+)\s*,\s*([^\]\)]+)\s*([\])])$').firstMatch(text);
    if (intervalMatch != null) {
      final lb = intervalMatch.group(1)!;
      final lv = intervalMatch.group(2)!.trim();
      final rv = intervalMatch.group(3)!.trim();
      final rb = intervalMatch.group(4)!;
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: lv,
        loInc: lb == '[' && !lv.contains('inf'),
        hi: rv,
        hiInc: rb == ']' && !rv.contains('inf'),
        excluded: excluded,
      );
    }

    final compact = text.replaceAll(' ', '');

    final dblAsc = RegExp(r'^(.+?)(<=|<)x(<=|<)(.+)$', caseSensitive: false)
        .firstMatch(compact);
    if (dblAsc != null) {
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: dblAsc.group(1)!,
        loInc: dblAsc.group(2) == '<=',
        hi: dblAsc.group(4)!,
        hiInc: dblAsc.group(3) == '<=',
        excluded: excluded,
      );
    }

    final dblDesc = RegExp(r'^(.+?)(>=|>)x(>=|>)(.+)$', caseSensitive: false)
        .firstMatch(compact);
    if (dblDesc != null) {
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: dblDesc.group(4)!,
        loInc: dblDesc.group(3) == '>=',
        hi: dblDesc.group(1)!,
        hiInc: dblDesc.group(2) == '>=',
        excluded: excluded,
      );
    }

    final leftVar =
        RegExp(r'^x(>=|>|<=|<)(.+)$', caseSensitive: false).firstMatch(compact);
    if (leftVar != null) {
      final op = leftVar.group(1)!;
      final val = leftVar.group(2)!;
      if (op == '>' || op == '>=') {
        return ParsedDomainExpression(
          domainMode: DomainMode.continuous,
          lo: val,
          loInc: op == '>=',
          hi: '+inf',
          hiInc: false,
          excluded: excluded,
        );
      }
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: '-inf',
        loInc: false,
        hi: val,
        hiInc: op == '<=',
        excluded: excluded,
      );
    }

    final rightVar =
        RegExp(r'^(.+?)(>=|>|<=|<)x$', caseSensitive: false).firstMatch(compact);
    if (rightVar != null) {
      final val = rightVar.group(1)!;
      final op = rightVar.group(2)!;
      if (op == '<' || op == '<=') {
        return ParsedDomainExpression(
          domainMode: DomainMode.continuous,
          lo: val,
          loInc: op == '<=',
          hi: '+inf',
          hiInc: false,
          excluded: excluded,
        );
      }
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: '-inf',
        loInc: false,
        hi: val,
        hiInc: op == '>=',
        excluded: excluded,
      );
    }

    final neqOnly = RegExp(r'^x!=(.+)$', caseSensitive: false).firstMatch(compact);
    if (neqOnly != null) {
      return ParsedDomainExpression(
        domainMode: DomainMode.continuous,
        lo: '-inf',
        loInc: false,
        hi: '+inf',
        hiInc: false,
        excluded: neqOnly.group(1)!,
      );
    }

    return const ParsedDomainExpression(
      domainMode: DomainMode.continuous,
      lo: '-2',
      loInc: true,
      hi: '3',
      hiInc: true,
      error: 'Use e.g. 3≤x<10, x>0, [3,10), or {-2,0,1}',
    );
  }

  bool _satisfiesOp(double val, String op, double target, {double tol = 1e-6}) {
    if (!val.isFinite) return false;
    switch (op) {
      case '=':
        return (val - target).abs() <= tol;
      case '<':
        return val < target - tol;
      case '<=':
        return val <= target + tol;
      case '>':
        return val > target + tol;
      case '>=':
        return val >= target - tol;
      default:
        return false;
    }
  }

  TargetConditionResult? solveTargetCondition({
    required String fnName,
    required FunctionInputMode inputMode,
    required Expression? expr,
    required List<TableEntry> table,
    required DomainSpec domain,
    required String rawCondition,
    double a = 0,
    double b = 0,
  }) {
    var cleaned = _normalizeComparison(rawCondition);
    if (cleaned.isEmpty) return null;
    cleaned = cleaned.replaceFirst(RegExp(r'^[a-zA-Z]\s*\(\s*x\s*\)\s*'), '').trim();
    final match = RegExp(r'^(<=|>=|<|>|=)?\s*(.+)$').firstMatch(cleaned);
    if (match == null) return null;
    final op = match.group(1) ?? '=';
    final targetY = double.tryParse(match.group(2)!.trim());
    if (targetY == null || !targetY.isFinite) return null;

    if (op == '=') {
      final sols = solveInverseTarget(
        fnName: fnName,
        inputMode: inputMode,
        expr: expr,
        table: table,
        domain: domain,
        targetY: targetY,
        a: a,
        b: b,
      );
      return TargetConditionResult(
        op: op,
        targetY: targetY,
        equalitySolutions: sols,
        notation: sols.isEmpty
            ? '∅'
            : sols.map((s) => 'x = ${formatCompactNum(s.x)}').join(', '),
      );
    }

    if (inputMode == FunctionInputMode.table) {
      final matches = table
          .where((e) => _satisfiesOp(e.y, op, targetY))
          .map((e) => formatCompactNum(e.x))
          .toList();
      return TargetConditionResult(
        op: op,
        targetY: targetY,
        equalitySolutions: const [],
        notation: matches.isEmpty ? '∅' : '{${matches.join(', ')}}',
      );
    }

    if (expr == null) return null;

    if (domain.mode == DomainMode.discrete) {
      final matches = <String>[];
      for (final x in domain.discreteValues) {
        final y = evaluate(expr, x, a: a, b: b);
        if (_satisfiesOp(y, op, targetY)) {
          matches.add(formatCompactNum(x));
        }
      }
      return TargetConditionResult(
        op: op,
        targetY: targetY,
        equalitySolutions: const [],
        notation: matches.isEmpty ? '∅' : '{${matches.join(', ')}}',
      );
    }

    final lo = domain.lowerBound ?? -20.0;
    final hi = domain.upperBound ?? 20.0;
    final roots = solveInverseTarget(
      fnName: fnName,
      inputMode: FunctionInputMode.formula,
      expr: expr,
      table: const [],
      domain: DomainSpec.continuous(
        lowerBound: lo,
        lowerInclusive: true,
        upperBound: hi,
        upperInclusive: true,
      ),
      targetY: targetY,
      a: a,
      b: b,
    ).map((s) => s.x);

    final cuts = <double>[lo, hi, ...roots];
    for (final ex in domain.excludedValues) {
      if (ex > lo && ex < hi) cuts.add(ex);
    }

    const probeN = 160;
    double prevY = evaluate(expr, lo, a: a, b: b);
    for (int i = 1; i <= probeN; i++) {
      final x = lo + (hi - lo) * i / probeN;
      final y = evaluate(expr, x, a: a, b: b);
      if ((prevY.isFinite && !y.isFinite) ||
          (!prevY.isFinite && y.isFinite) ||
          (prevY.isFinite && y.isFinite && (y - prevY).abs() > 1e3)) {
        cuts.add(lo + (hi - lo) * (i - 0.5) / probeN);
      }
      prevY = y;
    }

    cuts.sort();
    final uniqueCuts = <double>[];
    for (final c in cuts) {
      if (!uniqueCuts.any((u) => (u - c).abs() < 1e-4)) {
        uniqueCuts.add(c.abs() < 1e-7 ? 0.0 : double.parse(c.toStringAsFixed(4)));
      }
    }

    final pieces = <_DartPiece>[];
    for (int i = 0; i < uniqueCuts.length - 1; i++) {
      final c1 = uniqueCuts[i];
      final c2 = uniqueCuts[i + 1];
      final mid = (c1 + c2) / 2;
      if (!domain.contains(mid)) continue;
      final midY = evaluate(expr, mid, a: a, b: b);
      if (!_satisfiesOp(midY, op, targetY)) continue;

      final c1Ok = domain.contains(c1) &&
          _satisfiesOp(evaluate(expr, c1, a: a, b: b), op, targetY, tol: 1e-3);
      final c2Ok = domain.contains(c2) &&
          _satisfiesOp(evaluate(expr, c2, a: a, b: b), op, targetY, tol: 1e-3);

      pieces.add(
        _DartPiece(
          lo: i == 0 && domain.lowerBound == null ? null : c1,
          loInc: i == 0 && domain.lowerBound == null ? false : c1Ok,
          hi: i == uniqueCuts.length - 2 && domain.upperBound == null ? null : c2,
          hiInc: i == uniqueCuts.length - 2 && domain.upperBound == null ? false : c2Ok,
        ),
      );
    }

    final merged = <_DartPiece>[];
    for (final p in pieces) {
      if (merged.isNotEmpty &&
          merged.last.hi != null &&
          p.lo != null &&
          (merged.last.hi! - p.lo!).abs() < 1e-4 &&
          merged.last.hiInc &&
          p.loInc) {
        merged.last = _DartPiece(
          lo: merged.last.lo,
          loInc: merged.last.loInc,
          hi: p.hi,
          hiInc: p.hiInc,
        );
      } else {
        merged.add(p);
      }
    }

    if (op == '<=' || op == '>=') {
      for (final r in uniqueCuts) {
        final covered = merged.any((p) =>
            (p.lo == null || r > p.lo! + 1e-4 || ((r - p.lo!).abs() < 1e-4 && p.loInc)) &&
            (p.hi == null || r < p.hi! - 1e-4 || ((r - p.hi!).abs() < 1e-4 && p.hiInc)));
        if (!covered &&
            domain.contains(r) &&
            _satisfiesOp(evaluate(expr, r, a: a, b: b), op, targetY, tol: 1e-3)) {
          merged.add(_DartPiece(lo: r, loInc: true, hi: r, hiInc: true));
        }
      }
      merged.sort((p1, p2) =>
          (p1.lo ?? double.negativeInfinity).compareTo(p2.lo ?? double.negativeInfinity));
    }

    final notation = merged.isEmpty
        ? '∅'
        : merged.map((p) {
            if (p.lo != null && p.hi != null && (p.lo! - p.hi!).abs() < 1e-6) {
              return '{${formatCompactNum(p.lo!)}}';
            }
            final lb = p.lo == null ? '(' : (p.loInc ? '[' : '(');
            final lv = p.lo == null ? '-∞' : formatCompactNum(p.lo!);
            final rv = p.hi == null ? '+∞' : formatCompactNum(p.hi!);
            final rb = p.hi == null ? ')' : (p.hiInc ? ']' : ')');
            return '$lb$lv, $rv$rb';
          }).join(' ∪ ');

    return TargetConditionResult(
      op: op,
      targetY: targetY,
      equalitySolutions: const [],
      notation: notation,
    );
  }
}

class _DartPiece {
  final double? lo;
  final bool loInc;
  final double? hi;
  final bool hiInc;

  const _DartPiece({
    required this.lo,
    required this.loInc,
    required this.hi,
    required this.hiInc,
  });
}
