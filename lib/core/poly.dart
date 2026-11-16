import 'dart:math' as math;
import 'rational.dart';

/// Polynomial in x and the unknown constant a with exact rational coefficients.
class Poly {
  Poly._(this._t);
  final Map<int, Rational> _t; // key = degX * 64 + degA
  static const int _k = 64;
  static const int maxDeg = 40;

  factory Poly.constant(Rational c) => Poly._(c.isZero ? <int, Rational>{} : {0: c});
  factory Poly.x() => Poly._({_k: Rational.one});
  factory Poly.a() => Poly._({1: Rational.one});

  static Poly _clean(Map<int, Rational> m) {
    m.removeWhere((_, v) => v.isZero);
    return Poly._(m);
  }

  Poly operator +(Poly o) {
    final m = Map<int, Rational>.from(_t);
    o._t.forEach((k, v) => m[k] = (m[k] ?? Rational.zero) + v);
    return _clean(m);
  }

  Poly operator -() => Poly._({for (final e in _t.entries) e.key: -e.value});
  Poly operator -(Poly o) => this + (-o);

  Poly operator *(Poly o) {
    final m = <int, Rational>{};
    for (final p in _t.entries) {
      for (final q in o._t.entries) {
        final dx = p.key ~/ _k + q.key ~/ _k;
        final da = p.key % _k + q.key % _k;
        if (dx > maxDeg || da > maxDeg) throw const FormatException('Degree is too high');
        final key = dx * _k + da;
        m[key] = (m[key] ?? Rational.zero) + p.value * q.value;
      }
    }
    return _clean(m);
  }

  Poly scale(Rational r) => _clean({for (final e in _t.entries) e.key: e.value * r});

  Poly pow(int e) {
    var r = Poly.constant(Rational.one);
    for (var i = 0; i < e; i++) {
      r = r * this;
    }
    return r;
  }

  bool get isConstant => _t.keys.every((k) => k == 0);
  Rational get constantValue => _t[0] ?? Rational.zero;
  bool get hasA => _t.keys.any((k) => k % _k > 0);
  int get degX => _t.keys.fold<int>(0, (m, k) => math.max(m, k ~/ _k));

  /// Terms sorted by x-degree then a-degree, descending.
  List<({int dx, int da, Rational c})> get terms {
    final l = [for (final e in _t.entries) (dx: e.key ~/ _k, da: e.key % _k, c: e.value)];
    l.sort((p, q) => p.dx != q.dx ? q.dx.compareTo(p.dx) : q.da.compareTo(p.da));
    return l;
  }

  /// Substitute x = x0 -> map {degree of a: coefficient}.
  Map<int, Rational> aCoeffsAt(Rational x0) {
    final m = <int, Rational>{};
    _t.forEach((k, v) {
      final da = k % _k;
      m[da] = (m[da] ?? Rational.zero) + v * x0.pow(k ~/ _k);
    });
    return m;
  }

  /// Substitute a = value -> polynomial in x only.
  Poly substituteA(Rational a) {
    final m = <int, Rational>{};
    _t.forEach((k, v) {
      final key = (k ~/ _k) * _k;
      m[key] = (m[key] ?? Rational.zero) + v * a.pow(k % _k);
    });
    return _clean(m);
  }

  /// Coefficients of x (requires no a). Index = degree.
  List<Rational> xCoeffs() {
    final out = List<Rational>.filled(degX + 1, Rational.zero);
    _t.forEach((k, v) => out[k ~/ _k] = out[k ~/ _k] + v);
    return out;
  }
}
