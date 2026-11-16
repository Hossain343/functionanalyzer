import 'package:flutter_test/flutter_test.dart';
import 'package:function_analyzer/engines/parser_solver_engine.dart';
import 'package:function_analyzer/models/function_problem.dart';

void main() {
  final engine = ParserSolverEngine();

  test('evaluates quadratic with intermediate step 16 + 6 and outside domain check', () {
    final parsed = engine.tryParseFunction('g(x) = 4*x^2 - 3*x');
    expect(parsed.error, isNull);
    final expr = parsed.expression!;
    const domain = DomainSpec.continuous(
      lowerBound: -2,
      lowerInclusive: true,
      upperBound: 3,
      upperInclusive: true,
    );

    final resIn = engine.evaluatePoint(
      fnName: parsed.fnName,
      expr: expr,
      rawExpr: parsed.rhsText,
      domain: domain,
      x: -2,
    );
    expect(resIn.inDomain, isTrue);
    expect(resIn.y, closeTo(22.0, 1e-6));
    expect(resIn.steps.any((s) => s.contains('16 + 6')), isTrue);

    final resOut = engine.evaluatePoint(
      fnName: parsed.fnName,
      expr: expr,
      rawExpr: parsed.rhsText,
      domain: domain,
      x: 5,
    );
    expect(resOut.inDomain, isFalse);
    expect(resOut.y, isNull);
    expect(resOut.steps.last, 'Undefined (Outside Domain)');

    final range = engine.computeRange(expr, domain);
    expect(range.min!, closeTo(-0.5625, 1e-3));
    expect(range.max!, closeTo(27.0, 1e-3));
  });

  test('solves parameter a automatically from condition h(1) = 2', () {
    final parsed = engine.tryParseFunction('h(x) = 3*x + a');
    expect(parsed.hasParameterA, isTrue);
    final solved = engine.solveParameterAWithSteps(
      fnName: parsed.fnName,
      expr: parsed.expression!,
      rawRhs: parsed.rhsText,
      x0: 1,
      y0: 2,
    );
    expect(solved.solvedA, isNotNull);
    expect(solved.solvedA!, closeTo(-1.0, 1e-6));
  });

  test('parses and evaluates table-only discrete function pairs', () {
    final table = engine.parseTableEntries('-2:0, 0:3, 1:-1, 2:2, 4:1');
    expect(table.length, 5);

    final f0 = engine.evaluateTablePoint(fnName: 'f', table: table, x: 0);
    expect(f0.inDomain, isTrue);
    expect(f0.y, 3.0);

    final f5 = engine.evaluateTablePoint(fnName: 'f', table: table, x: 5);
    expect(f5.inDomain, isFalse);
    expect(f5.steps.last, 'Undefined (Outside Domain)');

    final range = engine.computeTableRange(table);
    expect(range.discreteOutputs, [-1.0, 0.0, 1.0, 2.0, 3.0]);
  });

  test('handles unbounded half-open interval (0, +inf)', () {
    final parsed = engine.tryParseFunction('f(x) = 2*x + 1');
    const domain = DomainSpec.continuous(
      lowerBound: 0,
      lowerInclusive: false,
      upperBound: null,
      upperInclusive: false,
    );
    expect(domain.toIntervalNotation(), '(0, +∞)');
    expect(domain.toSetBuilderNotation(), '{x ∈ ℝ | x > 0}');
    expect(domain.contains(0), isFalse);
    expect(domain.contains(2), isTrue);

    final range = engine.computeRange(parsed.expression!, domain);
    expect(range.max, isNull);
  });

  test('evaluates absolute value |x - 2| without corrupting abs keyword', () {
    final parsed = engine.tryParseFunction('f(x) = |x - 2|');
    expect(parsed.error, isNull);
    expect(parsed.hasParameterA, isFalse);
    const domain = DomainSpec.continuous(
      lowerBound: -5,
      lowerInclusive: true,
      upperBound: 5,
      upperInclusive: true,
    );
    final res = engine.evaluatePoint(
      fnName: parsed.fnName,
      expr: parsed.expression!,
      rawExpr: parsed.rhsText,
      domain: domain,
      x: -1,
    );
    expect(res.inDomain, isTrue);
    expect(res.y, closeTo(3.0, 1e-6));
    expect(res.steps.first.contains('0bs'), isFalse);
  });

  test('solves two unknowns (a, b) system from two conditions', () {
    final parsed = engine.tryParseFunction('f(x) = ax + b');
    expect(parsed.error, isNull);
    expect(parsed.hasParameterA, isTrue);
    expect(parsed.hasParameterB, isTrue);

    final out = engine.solveParametersWithSteps(
      fnName: parsed.fnName,
      expr: parsed.expression!,
      rawRhs: parsed.rhsText,
      hasA: parsed.hasParameterA,
      hasB: parsed.hasParameterB,
      x1: 1,
      y1: 4,
      x2: 3,
      y2: 10,
    );
    expect(out.error, isNull);
    expect(out.solvedA!, closeTo(3.0, 1e-6));
    expect(out.solvedB!, closeTo(1.0, 1e-6));
  });

  test('supports excluded domain points, Persian digits, and inverse target f(x)=k', () {
    final parsed = engine.tryParseFunction('f(x) = ۲*x + ۱');
    expect(parsed.error, isNull);
    const domain = DomainSpec.continuous(
      lowerBound: -1,
      lowerInclusive: true,
      upperBound: 5,
      upperInclusive: true,
      excludedValues: [2],
    );
    expect(domain.toIntervalNotation(), '[-1, 5] - {2}');
    expect(domain.contains(2), isFalse);
    expect(domain.contains(3), isTrue);

    final sols = engine.solveInverseTarget(
      fnName: 'f',
      inputMode: FunctionInputMode.formula,
      expr: parsed.expression,
      table: const [],
      domain: domain,
      targetY: 7,
    );
    expect(sols.length, 1);
    expect(sols.first.x, closeTo(3.0, 1e-3));
  });

  test('parses domain inequalities and solves f(x) >= k and < k conditions', () {
    final domParsed = engine.parseDomainExpression('{x ∈ ℝ | 3 ≤ x < 10}');
    expect(domParsed, isNotNull);
    expect(domParsed!.error, isNull);
    expect(domParsed.lo, '3');
    expect(domParsed.loInc, isTrue);
    expect(domParsed.hi, '10');
    expect(domParsed.hiInc, isFalse);

    final fParsed = engine.tryParseFunction('f(x) = x^2 - 4');
    const domain = DomainSpec.continuous(
      lowerBound: -3,
      lowerInclusive: true,
      upperBound: 3,
      upperInclusive: true,
    );
    final geRes = engine.solveTargetCondition(
      fnName: 'f',
      inputMode: FunctionInputMode.formula,
      expr: fParsed.expression,
      table: const [],
      domain: domain,
      rawCondition: '>= 0',
    );
    expect(geRes, isNotNull);
    expect(geRes!.notation, '[-3, -2] ∪ [2, 3]');

    final ltRes = engine.solveTargetCondition(
      fnName: 'f',
      inputMode: FunctionInputMode.formula,
      expr: fParsed.expression,
      table: const [],
      domain: domain,
      rawCondition: '< 0',
    );
    expect(ltRes, isNotNull);
    expect(ltRes!.notation, '(-2, 2)');
  });
}
