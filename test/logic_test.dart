import 'package:flutter_test/flutter_test.dart';
import 'package:function_analyzer/core/analysis.dart';
import 'package:function_analyzer/core/domain.dart';
import 'package:function_analyzer/core/engine.dart';
import 'package:function_analyzer/core/rational.dart';

Rational r(int v) => Rational.fromInt(v);

Domain closed(int a, int b) =>
    Domain.interval(lo: r(a), hi: r(b), loClosed: true, hiClosed: true);

void main() {
  test('g(x)=4x^2-3x on [-2,3]: g(-2)=22, g(1)=1, g(5) undefined', () {
    final a = Analysis.run(
        exprText: 'g(x)=4x^2-3x', domain: closed(-2, 3), condition: '', queryText: '-2, 1, 5');
    expect(a.evals[0].y, r(22));
    expect(a.evals[0].steps, ['4(-2)² - 3(-2)', '4·4 - 3(-2)', '16 - (-6)', '16 + 6', '22']);
    expect(a.evals[1].y, r(1));
    expect(a.evals[1].steps, ['4·1² - 3·1', '4·1 - 3·1', '4 - 3', '1']);
    expect(a.evals[2].inDomain, false);
    expect(a.range.notation, '[-9/16, 27]');
  });

  test('half-open [-2,3): range [-9/16, 27)', () {
    final d = Domain.interval(lo: r(-2), hi: r(3), loClosed: true, hiClosed: false);
    final a = Analysis.run(exprText: 'f(x)=4x^2-3x', domain: d, condition: '', queryText: '');
    expect(a.range.notation, '[-9/16, 27)');
  });

  test('discrete set {-2,0,1,2,4}', () {
    final a = Analysis.run(
        exprText: 'f(x) = 4x^2 - 3x',
        domain: Domain.parseSet('{-2, 0, 1, 2, 4}'),
        condition: '',
        queryText: '-2, 1, 5');
    expect(a.range.notation, '{0, 1, 10, 22, 52}');
    expect(a.evals[2].inDomain, false);
  });

  test('h(x)=3x+a with h(1)=2 gives a=-1, h(2)=5', () {
    final d = Domain.interval(lo: r(-2), hi: null, loClosed: true, hiClosed: false);
    final a = Analysis.run(exprText: 'h(x)=3x+a', domain: d, condition: 'h(1)=2', queryText: '2');
    expect(a.f.body, '3x - 1');
    expect(a.evals[0].y, r(5));
    expect(a.range.notation, '[-7, ∞)');
    expect(a.paramLines.contains('a = -1'), true);
  });

  test('linear f(x)=2x+1 on [1,3)', () {
    final d = Domain.interval(lo: r(1), hi: r(3), loClosed: true, hiClosed: false);
    final a = Analysis.run(exprText: 'f(x)=2x+1', domain: d, condition: '', queryText: '');
    expect(a.range.notation, '[3, 7)');
  });

  test('interval <-> set-builder notation', () {
    final d1 = Domain.interval(lo: r(3), hi: r(10), loClosed: true, hiClosed: false);
    expect(d1.intervalNotation, '[3, 10)');
    expect(d1.setBuilder, '{x ∈ R | 3 ≤ x < 10}');
    final d2 = Domain.interval(lo: r(-1), hi: r(0), loClosed: false, hiClosed: false);
    expect(d2.intervalNotation, '(-1, 0)');
    expect(d2.setBuilder, '{x ∈ R | -1 < x < 0}');
    final d3 = Domain.interval(lo: r(2), hi: null, loClosed: false, hiClosed: false);
    expect(d3.intervalNotation, '(2, ∞)');
    expect(d3.setBuilder, '{x ∈ R | x > 2}');
  });

  test('exact numbers, Persian digits, implicit multiplication', () {
    expect(parseConstant('۱/۲'), Rational(BigInt.one, BigInt.two));
    expect(parseConstant('0.25'), Rational(BigInt.one, BigInt.from(4)));
    final p = ExprParser.parseFunction('f(x)=(x+1)(x-1)').poly;
    expect(FunctionModel('f', p.xCoeffs()).body, 'x² - 1');
  });
}
