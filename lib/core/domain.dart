import 'engine.dart';
import 'rational.dart';
import 'text.dart';

/// Df: a continuous interval (bounds may be infinite = null) or a discrete set.
class Domain {
  Domain._(this.discrete, this.points, this.lo, this.hi, this.loClosed, this.hiClosed);

  final bool discrete;
  final List<Rational> points; // sorted, discrete only
  final Rational? lo, hi; // null = infinite
  final bool loClosed, hiClosed;

  factory Domain.set(List<Rational> pts) {
    if (pts.isEmpty) throw const FormatException('Enter at least one value');
    final seen = <String>{};
    final u = [for (final p in pts) if (seen.add(p.toString())) p]..sort();
    return Domain._(true, u, u.first, u.last, true, true);
  }

  factory Domain.interval({Rational? lo, Rational? hi, required bool loClosed, required bool hiClosed}) {
    if (lo != null && hi != null) {
      if (lo > hi) throw const FormatException('Left bound must be ≤ right bound');
      if (lo == hi && !(loClosed && hiClosed)) throw const FormatException('Empty interval');
    }
    return Domain._(false, const [], lo, hi, loClosed && lo != null, hiClosed && hi != null);
  }

  /// "{-2, 0, 1}" or "-2, 0, 1" (fractions/decimals allowed).
  factory Domain.parseSet(String raw) {
    var s = normalizeInput(raw).replaceAll(RegExp(r'\s+'), '');
    final eq = s.indexOf('=');
    if (eq >= 0) s = s.substring(eq + 1);
    s = s.replaceAll(RegExp(r'^\{|\}$'), '');
    final parts = s.split(RegExp(r'[,;]')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) throw const FormatException('Enter at least one value');
    final pts = <Rational>[];
    for (final p in parts) {
      try {
        pts.add(parseConstant(p));
      } on FormatException {
        throw FormatException('Bad set value "$p"');
      }
    }
    return Domain.set(pts);
  }

  bool contains(Rational x) {
    if (discrete) return points.any((p) => p == x);
    final l = lo, h = hi;
    if (l != null && (loClosed ? x < l : x <= l)) return false;
    if (h != null && (hiClosed ? x > h : x >= h)) return false;
    return true;
  }

  bool get hasOpenBound => !discrete && ((lo != null && !loClosed) || (hi != null && !hiClosed));

  String get roster => '{${points.join(', ')}}';

  /// "-2 ≤ x < 3"
  String get condition {
    final l = lo, h = hi;
    if (l != null && h != null) return '$l ${loClosed ? '≤' : '<'} x ${hiClosed ? '≤' : '<'} $h';
    if (l != null) return 'x ${loClosed ? '≥' : '>'} $l';
    if (h != null) return 'x ${hiClosed ? '≤' : '<'} $h';
    return 'x ∈ R';
  }

  /// "[-2, 3)"  or  "{-2, 0, 1}"
  String get intervalNotation {
    if (discrete) return roster;
    return '${loClosed ? '[' : '('}${lo ?? '-∞'}, ${hi ?? '∞'}${hiClosed ? ']' : ')'}';
  }

  /// "{x ∈ R | -2 ≤ x < 3}"
  String get setBuilder {
    if (discrete) return roster;
    return (lo == null && hi == null) ? '{x ∈ R}' : '{x ∈ R | $condition}';
  }
}
