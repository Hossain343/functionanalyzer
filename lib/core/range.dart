import 'domain.dart';
import 'engine.dart';
import 'rational.dart';

class RangeInfo {
  const RangeInfo({
    required this.discrete,
    required this.values,
    required this.minY,
    required this.maxY,
    required this.minClosed,
    required this.maxClosed,
  });
  final bool discrete;
  final List<Rational> values;
  final Rational? minY, maxY; // null = infinite
  final bool minClosed, maxClosed;

  String get notation {
    if (discrete) return '{${values.join(', ')}}';
    final lo = minY, hi = maxY;
    if (lo != null && hi != null && lo == hi) return '{$lo}';
    final l = lo == null ? '(-∞' : '${minClosed ? '[' : '('}$lo';
    final r = hi == null ? '∞)' : '$hi${maxClosed ? ']' : ')'}';
    return '$l, $r';
  }

  String get bounds => '${minY ?? '-∞'} … ${maxY ?? '∞'}';
}

class _C {
  const _C(this.y, this.att);
  final Rational y;
  final bool att;
}

/// Exact range. Discrete: any polynomial. Interval: degree <= 2 (endpoints + vertex + limits).
RangeInfo computeRange(Domain d, FunctionModel f) {
  if (d.discrete) {
    final seen = <String>{};
    final ys = [for (final x in d.points) f.eval(x)].where((y) => seen.add(y.toString())).toList()..sort();
    return RangeInfo(discrete: true, values: ys, minY: ys.first, maxY: ys.last, minClosed: true, maxClosed: true);
  }
  if (f.degree > 2) {
    throw const FormatException('Interval domains support linear and quadratic functions');
  }
  final cands = <_C>[];
  var plusInf = false, minusInf = false;
  final lo = d.lo, hi = d.hi;
  if (lo != null) cands.add(_C(f.eval(lo), d.loClosed));
  if (hi != null) cands.add(_C(f.eval(hi), d.hiClosed));
  if (f.degree == 0) {
    cands.add(_C(f.coeffs[0], true));
  } else if (f.degree == 1) {
    final b = f.coeffs[1];
    if (hi == null) {
      if (b.isPositive) {
        plusInf = true;
      } else {
        minusInf = true;
      }
    }
    if (lo == null) {
      if (b.isPositive) {
        minusInf = true;
      } else {
        plusInf = true;
      }
    }
  } else {
    final a = f.coeffs[2], b = f.coeffs[1];
    final v = -b / (Rational.fromInt(2) * a);
    final inside = (lo == null || v > lo) && (hi == null || v < hi);
    if (inside) cands.add(_C(f.eval(v), true));
    if (lo == null || hi == null) {
      if (a.isPositive) {
        plusInf = true;
      } else {
        minusInf = true;
      }
    }
  }
  Rational? minY, maxY;
  var minC = false, maxC = false;
  if (cands.isNotEmpty) {
    if (!minusInf) {
      minY = cands.map((c) => c.y).reduce((p, q) => p < q ? p : q);
      minC = cands.any((c) => c.y == minY && c.att);
    }
    if (!plusInf) {
      maxY = cands.map((c) => c.y).reduce((p, q) => p > q ? p : q);
      maxC = cands.any((c) => c.y == maxY && c.att);
    }
  }
  return RangeInfo(discrete: false, values: const [], minY: minY, maxY: maxY, minClosed: minC, maxClosed: maxC);
}

class KeyRow {
  const KeyRow(this.x, this.y, this.tag);
  final String x, y, tag;
}

List<KeyRow> keyPoints(Domain d, FunctionModel f) {
  if (d.discrete) {
    return [for (final x in d.points) KeyRow('$x', '${f.eval(x)}', 'point')];
  }
  final xs = <String, Rational>{};
  final tags = <String, String>{};
  void add(Rational x, String tag) {
    final k = x.toString();
    xs[k] = x;
    if (tag.isNotEmpty) tags[k] = tag;
  }

  final lo = d.lo, hi = d.hi;
  final six = Rational.fromInt(6);
  final wlo = lo ?? (hi != null ? hi - six : Rational.fromInt(-3));
  final whi = hi ?? (lo != null ? lo + six : Rational.fromInt(3));
  final start = wlo.ceil(), end = whi.floor();
  final count = end - start + BigInt.one;
  if (count > BigInt.zero) {
    final step = count <= BigInt.from(9) ? BigInt.one : (count + BigInt.from(6)) ~/ BigInt.from(7);
    for (var i = start; i <= end; i += step) {
      final x = Rational(i);
      if (d.contains(x)) add(x, '');
    }
  }
  if (f.degree == 2) {
    final v = -f.coeffs[1] / (Rational.fromInt(2) * f.coeffs[2]);
    if (d.contains(v)) add(v, 'vertex');
  }
  if (lo != null) add(lo, d.loClosed ? 'endpoint' : 'open end');
  if (hi != null) add(hi, d.hiClosed ? 'endpoint' : 'open end');
  final list = xs.values.toList()..sort();
  return [for (final x in list) KeyRow('$x', '${f.eval(x)}', tags[x.toString()] ?? '')];
}
