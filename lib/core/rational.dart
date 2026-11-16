/// Exact fraction (BigInt based) - no floating point error anywhere in the math.
class Rational implements Comparable<Rational> {
  Rational._(this.n, this.d);
  final BigInt n; // numerator (carries the sign)
  final BigInt d; // denominator, always > 0

  factory Rational(BigInt n, [BigInt? d]) {
    var den = d ?? BigInt.one;
    if (den == BigInt.zero) throw const FormatException('Division by zero');
    var top = n;
    if (den.isNegative) {
      top = -top;
      den = -den;
    }
    final g = top.gcd(den);
    if (g > BigInt.one) {
      top = top ~/ g;
      den = den ~/ g;
    }
    return Rational._(top, den);
  }

  factory Rational.fromInt(int v) => Rational._(BigInt.from(v), BigInt.one);

  /// "12.5" -> 25/2
  factory Rational.parseDecimal(String s) {
    final parts = s.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    return Rational(BigInt.parse(intPart + frac), BigInt.from(10).pow(frac.length));
  }

  static final Rational zero = Rational.fromInt(0);
  static final Rational one = Rational.fromInt(1);

  Rational operator +(Rational o) => Rational(n * o.d + o.n * d, d * o.d);
  Rational operator -(Rational o) => Rational(n * o.d - o.n * d, d * o.d);
  Rational operator *(Rational o) => Rational(n * o.n, d * o.d);
  Rational operator /(Rational o) => Rational(n * o.d, d * o.n);
  Rational operator -() => Rational._(-n, d);

  Rational pow(int e) => Rational._(n.pow(e), d.pow(e));
  Rational abs() => isNegative ? -this : this;

  bool get isZero => n == BigInt.zero;
  bool get isNegative => n.isNegative;
  bool get isPositive => n > BigInt.zero;
  bool get isInteger => d == BigInt.one;

  BigInt floor() {
    final q = n ~/ d;
    return (n.isNegative && n.remainder(d) != BigInt.zero) ? q - BigInt.one : q;
  }

  BigInt ceil() => -((-this).floor());

  @override
  int compareTo(Rational o) => (n * o.d).compareTo(o.n * d);
  bool operator <(Rational o) => compareTo(o) < 0;
  bool operator <=(Rational o) => compareTo(o) <= 0;
  bool operator >(Rational o) => compareTo(o) > 0;
  bool operator >=(Rational o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object o) => o is Rational && n == o.n && d == o.d;
  @override
  int get hashCode => Object.hash(n, d);

  /// Only used for drawing.
  double toDouble() {
    final nb = n.bitLength, db = d.bitLength;
    if (nb < 1000 && db < 1000) return n.toDouble() / d.toDouble();
    final shift = (nb > db ? nb : db) - 900;
    return (n >> shift).toDouble() / (d >> shift).toDouble();
  }

  @override
  String toString() => d == BigInt.one ? '$n' : '$n/$d';
}
