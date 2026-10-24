/// Exact rational number backed by [BigInt], used where floating point
/// rounding is unacceptable (e.g. balancing chemical equations).
class Rational implements Comparable<Rational> {
  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) {
      throw ArgumentError('Denominator must not be zero');
    }
    var n = numerator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  const Rational._(this.numerator, this.denominator);

  factory Rational.fromInt(int n, [int d = 1]) =>
      Rational(BigInt.from(n), BigInt.from(d));

  /// Converts a finite double to an exact rational by limiting the
  /// denominator (continued fraction approximation).
  factory Rational.fromDouble(double x, {int maxDenominator = 1000000}) {
    if (!x.isFinite) throw ArgumentError('Value must be finite');
    final negative = x < 0;
    var v = x.abs();
    var h0 = BigInt.zero, h1 = BigInt.one;
    var k0 = BigInt.one, k1 = BigInt.zero;
    final maxD = BigInt.from(maxDenominator);
    for (var i = 0; i < 64; i++) {
      final a = BigInt.from(v.floor());
      final h2 = a * h1 + h0;
      final k2 = a * k1 + k0;
      if (k2 > maxD) break;
      h0 = h1;
      h1 = h2;
      k0 = k1;
      k1 = k2;
      final frac = v - v.floor();
      if (frac < 1e-12) break;
      v = 1 / frac;
    }
    if (k1 == BigInt.zero) return Rational.zero;
    return Rational(negative ? -h1 : h1, k1);
  }

  static final Rational zero = Rational._(BigInt.zero, BigInt.one);
  static final Rational one = Rational._(BigInt.one, BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;
  bool get isInteger => denominator == BigInt.one;

  Rational operator +(Rational o) => Rational(
        numerator * o.denominator + o.numerator * denominator,
        denominator * o.denominator,
      );

  Rational operator -(Rational o) => Rational(
        numerator * o.denominator - o.numerator * denominator,
        denominator * o.denominator,
      );

  Rational operator *(Rational o) =>
      Rational(numerator * o.numerator, denominator * o.denominator);

  Rational operator /(Rational o) =>
      Rational(numerator * o.denominator, denominator * o.numerator);

  Rational operator -() => Rational._(-numerator, denominator);

  Rational abs() => isNegative ? -this : this;

  double toDouble() => numerator / denominator;

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}

BigInt lcm(BigInt a, BigInt b) {
  if (a == BigInt.zero || b == BigInt.zero) return BigInt.zero;
  return (a ~/ a.gcd(b)) * b;
}
