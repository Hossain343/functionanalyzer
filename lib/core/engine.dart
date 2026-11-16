import 'poly.dart';
import 'rational.dart';
import 'text.dart';

class _Tok {
  const _Tok(this.kind, this.text);
  final int kind; // 0 number, 1 variable, 2 operator
  final String text;
}

/// Exact polynomial parser: + - * / ^ ( ), implicit multiplication (4x, 2(x+1), x(x-1)),
/// decimals become exact fractions. Variables: x, and a (unknown constant).
class ExprParser {
  ExprParser._(this._t, this._vars);
  final List<_Tok> _t;
  final bool _vars;
  int _i = 0;

  static Poly parse(String raw, {bool vars = true}) {
    final src = normalizeInput(raw).replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (src.isEmpty) throw const FormatException('Empty expression');
    final p = ExprParser._(_tokenize(src), vars);
    final v = p._expr();
    if (p._i < p._t.length) throw FormatException('Unexpected "${p._t[p._i].text}"');
    return v;
  }

  /// "f(x) = 4x^2 - 3x", "h(x)=3x+a", "y = 2x", or just "4x^2".
  static ({String name, Poly poly}) parseFunction(String input) {
    var s = normalizeInput(input);
    var name = 'f';
    final m = RegExp(r'^([A-Za-z]\w*)\(\s*x\s*\)\s*=\s*(.*)$', caseSensitive: false).firstMatch(s);
    if (m != null) {
      name = m[1]!;
      s = m[2]!;
    } else if (RegExp(r'^y\s*=', caseSensitive: false).hasMatch(s)) {
      s = s.substring(s.indexOf('=') + 1);
    } else if (s.contains('=')) {
      throw const FormatException('Write it like f(x) = 4x^2 - 3x');
    }
    return (name: name, poly: parse(s));
  }

  static List<_Tok> _tokenize(String s) {
    final out = <_Tok>[];
    var i = 0;
    final digit = RegExp(r'[0-9.]');
    final letter = RegExp(r'[a-z]');
    while (i < s.length) {
      final c = s[i];
      if (digit.hasMatch(c)) {
        var j = i, dots = 0;
        while (j < s.length && digit.hasMatch(s[j])) {
          if (s[j] == '.') dots++;
          j++;
        }
        final text = s.substring(i, j);
        if (dots > 1 || text == '.') throw FormatException('Bad number "$text"');
        out.add(_Tok(0, text));
        i = j;
      } else if (letter.hasMatch(c)) {
        var j = i;
        while (j < s.length && letter.hasMatch(s[j])) {
          j++;
        }
        final word = s.substring(i, j);
        if (!RegExp(r'^[xa]+$').hasMatch(word)) {
          throw FormatException('Only polynomials in x are supported (found "$word")');
        }
        for (final ch in word.split('')) {
          out.add(_Tok(1, ch));
        }
        i = j;
      } else if ('+-*/^()'.contains(c)) {
        out.add(_Tok(2, c));
        i++;
      } else {
        throw FormatException('Unexpected symbol "$c"');
      }
    }
    return out;
  }

  bool _peekOp(String op) => _i < _t.length && _t[_i].kind == 2 && _t[_i].text == op;
  bool _startsFactor() => _i < _t.length && (_t[_i].kind != 2 || _t[_i].text == '(');

  Poly _expr() {
    var v = _term();
    while (_peekOp('+') || _peekOp('-')) {
      final op = _t[_i++].text;
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  Poly _term() {
    var v = _unary();
    while (true) {
      if (_peekOp('*')) {
        _i++;
        v = v * _unary();
      } else if (_peekOp('/')) {
        _i++;
        final r = _unary();
        if (!r.isConstant) throw const FormatException('Division is only allowed by a number');
        if (r.constantValue.isZero) throw const FormatException('Division by zero');
        v = v.scale(Rational.one / r.constantValue);
      } else if (_startsFactor()) {
        v = v * _unary();
      } else {
        break;
      }
    }
    return v;
  }

  Poly _unary() {
    if (_peekOp('+')) {
      _i++;
      return _unary();
    }
    if (_peekOp('-')) {
      _i++;
      return -_unary();
    }
    return _power();
  }

  Poly _power() {
    final base = _atom();
    if (_peekOp('^')) {
      _i++;
      final e = _unary();
      if (!e.isConstant || !e.constantValue.isInteger || e.constantValue.isNegative) {
        throw const FormatException('Exponents must be whole numbers (0, 1, 2 ...)');
      }
      final n = e.constantValue.n;
      if (n > BigInt.from(30)) throw const FormatException('Exponent is too large');
      return base.pow(n.toInt());
    }
    return base;
  }

  Poly _atom() {
    if (_i >= _t.length) throw const FormatException('Expression ended unexpectedly');
    final t = _t[_i++];
    if (t.kind == 0) return Poly.constant(Rational.parseDecimal(t.text));
    if (t.kind == 1) {
      if (!_vars) throw const FormatException('Only numbers are allowed here');
      return t.text == 'x' ? Poly.x() : Poly.a();
    }
    if (t.text == '(') {
      final v = _expr();
      if (!_peekOp(')')) throw const FormatException('Missing )');
      _i++;
      return v;
    }
    throw FormatException('Unexpected "${t.text}"');
  }
}

/// "3", "-2", "1/2", "0.25" -> exact Rational.
Rational parseConstant(String raw) {
  if (raw.trim().isEmpty) throw const FormatException('Enter a number');
  return ExprParser.parse(raw, vars: false).constantValue;
}

class _Term {
  const _Term(this.k, this.c);
  final int k;
  final Rational c;
}

/// A polynomial in x with exact coefficients (index = degree).
class FunctionModel {
  FunctionModel(this.name, List<Rational> c) : coeffs = _trim(c) {
    _d = coeffs.map((e) => e.toDouble()).toList();
  }
  final String name;
  final List<Rational> coeffs;
  late final List<double> _d;

  static List<Rational> _trim(List<Rational> c) {
    final l = List<Rational>.from(c);
    while (l.length > 1 && l.last.isZero) {
      l.removeLast();
    }
    return l.isEmpty ? [Rational.zero] : l;
  }

  int get degree => coeffs.length - 1;

  Rational eval(Rational x) {
    var r = Rational.zero;
    for (var k = coeffs.length - 1; k >= 0; k--) {
      r = r * x + coeffs[k];
    }
    return r;
  }

  double evalD(double x) {
    var r = 0.0;
    for (var k = _d.length - 1; k >= 0; k--) {
      r = r * x + _d[k];
    }
    return r;
  }

  /// "4x² - 3x"
  String get body {
    final sb = StringBuffer();
    var first = true;
    for (var k = coeffs.length - 1; k >= 0; k--) {
      final c = coeffs[k];
      if (c.isZero) continue;
      final m = c.abs();
      String mag;
      if (k == 0) {
        mag = '$m';
      } else {
        final coef = m == Rational.one ? '' : (m.isInteger ? '$m' : '($m)');
        mag = '$coef${k == 1 ? 'x' : 'x${sup(k)}'}';
      }
      if (first) {
        sb.write(c.isNegative ? '-$mag' : mag);
        first = false;
      } else {
        sb.write(c.isNegative ? ' - $mag' : ' + $mag');
      }
    }
    return first ? '0' : sb.toString();
  }

  /// Exam-style working, e.g. for f = 4x² - 3x at x = -2:
  /// 4(-2)² - 3(-2) / 4·4 - 3(-2) / 16 - (-6) / 16 + 6 / 22
  List<String> stepsAt(Rational x) {
    final ts = <_Term>[];
    for (var k = coeffs.length - 1; k >= 0; k--) {
      if (!coeffs[k].isZero) ts.add(_Term(k, coeffs[k]));
    }
    if (ts.isEmpty) return ['0'];
    final xv = fmtVal(x);
    final y = eval(x);

    String coefOf(Rational m) => m == Rational.one ? '' : (m.isInteger ? '$m' : '($m)');
    String comb(String coef, String val) {
      if (coef.isEmpty) return val;
      return val.startsWith('(') ? '$coef$val' : '$coef·$val';
    }

    String join(String Function(_Term t, bool first) mag) {
      final sb = StringBuffer();
      for (var i = 0; i < ts.length; i++) {
        final t = ts[i];
        final m = mag(t, i == 0);
        if (i == 0) {
          sb.write(t.c.isNegative ? '-$m' : m);
        } else {
          sb.write(t.c.isNegative ? ' - $m' : ' + $m');
        }
      }
      return sb.toString();
    }

    final s1 = join((t, first) {
      final m = t.c.abs();
      if (t.k == 0) return '$m';
      return comb(coefOf(m), xv + (t.k > 1 ? sup(t.k) : ''));
    });
    final s2 = join((t, first) {
      final m = t.c.abs();
      if (t.k == 0) return '$m';
      if (t.k == 1) return comb(coefOf(m), xv);
      return comb(coefOf(m), fmtVal(x.pow(t.k)));
    });
    final s3 = join((t, first) {
      final v = t.k == 0 ? t.c.abs() : t.c.abs() * x.pow(t.k);
      return (v.isNegative && (!first || t.c.isNegative)) ? '($v)' : '$v';
    });
    final sb4 = StringBuffer();
    for (var i = 0; i < ts.length; i++) {
      final t = ts[i];
      final v = t.c * x.pow(t.k);
      final neg = v.isZero ? t.c.isNegative : v.isNegative;
      final m = v.abs();
      if (i == 0) {
        sb4.write(neg ? '-$m' : '$m');
      } else {
        sb4.write(neg ? ' - $m' : ' + $m');
      }
    }

    final raw = <String>[s1, if (ts.any((t) => t.k >= 2)) s2, s3, sb4.toString(), '$y'];
    final out = <String>[];
    for (final l in raw) {
      if (out.isEmpty || out.last != l) out.add(l);
    }
    return out;
  }
}

String _joinParts(List<String> p) {
  var out = p.first;
  for (var i = 1; i < p.length; i++) {
    final nx = p[i];
    final noDot = nx.startsWith('(') || (nx.startsWith('a') && p.length == 2);
    out += noDot ? nx : '·$nx';
  }
  return out;
}

/// 3·1 + a  (polynomial with x replaced by x0, a kept symbolic)
String _bivarText(Poly poly, Rational x0) {
  final xv = fmtVal(x0);
  final sb = StringBuffer();
  var first = true;
  for (final t in poly.terms) {
    final m = t.c.abs();
    final parts = <String>[];
    if (m != Rational.one || (t.dx == 0 && t.da == 0)) {
      final multi = t.dx > 0 || t.da > 0;
      parts.add(multi && !m.isInteger ? '($m)' : '$m');
    }
    if (t.dx > 0) parts.add(xv + (t.dx > 1 ? sup(t.dx) : ''));
    if (t.da > 0) parts.add('a${t.da > 1 ? sup(t.da) : ''}');
    final mag = _joinParts(parts);
    if (first) {
      sb.write(t.c.isNegative ? '-$mag' : mag);
      first = false;
    } else {
      sb.write(t.c.isNegative ? ' - $mag' : ' + $mag');
    }
  }
  return first ? '0' : sb.toString();
}

String _linText(Rational c0, Rational k) {
  final mk = k.abs();
  final aPart = mk == Rational.one ? 'a' : (mk.isInteger ? '${mk}a' : '($mk)a');
  if (c0.isZero) return k.isNegative ? '-$aPart' : aPart;
  return '$c0${k.isNegative ? ' - ' : ' + '}$aPart';
}

/// Solves the unknown constant a from a condition such as h(1) = 2 (exact).
({Poly poly, List<String> lines}) solveParam(String name, Poly poly, String condition) {
  final cs = normalizeInput(condition);
  final m = RegExp(r'^[A-Za-z]\w*\(\s*(.+?)\s*\)\s*=\s*(.+)$').firstMatch(cs);
  if (m == null) throw const FormatException('Condition must look like h(1) = 2');
  final x0 = parseConstant(m[1]!);
  final y0 = parseConstant(m[2]!);
  final at = poly.aCoeffsAt(x0);
  for (final e in at.entries) {
    if (e.key > 1 && !e.value.isZero) {
      throw const FormatException('The function must be linear in a (like 3x + a)');
    }
  }
  final c0 = at[0] ?? Rational.zero;
  final k = at[1] ?? Rational.zero;
  if (k.isZero) throw const FormatException('The condition must involve a');
  final a = (y0 - c0) / k;
  final resolved = poly.substituteA(a);
  final model = FunctionModel(name, resolved.xCoeffs());

  final subst = _bivarText(poly, x0);
  final lin = _linText(c0, k);
  final raw = <String>['$name($x0) = $y0', '$subst = $y0'];
  if (lin != subst) raw.add('$lin = $y0');
  if (!c0.isZero) {
    raw.add(k == Rational.one ? 'a = $y0 - ${fmtVal(c0)}' : 'a = ($y0 - ${fmtVal(c0)})/${fmtVal(k)}');
  }
  raw.add('a = $a');
  raw.add('So $name(x) = ${model.body}');
  raw.add('Check: $name($x0) = ${model.eval(x0)} ✓');
  final lines = <String>[];
  for (final l in raw) {
    if (lines.isEmpty || lines.last != l) lines.add(l);
  }
  return (poly: resolved, lines: lines);
}
