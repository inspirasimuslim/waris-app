import 'dart:core';

/// Pecahan tepat berasaskan [BigInt]. Tiada aritmetik titik terapung —
/// faraid melibatkan penyebut seperti 24, 27, 72 dan ralat `double` akan
/// menghasilkan pembahagian yang salah (lihat SPEC 1.2, peraturan besi).
///
/// Sentiasa disimpan dalam bentuk termudah dengan penyebut positif.
class Fraction implements Comparable<Fraction> {
  Fraction._(this.numerator, this.denominator)
      : assert(denominator != BigInt.zero, 'Penyebut tidak boleh sifar');

  /// Bina daripada [num] / [den], kemudian normalkan.
  factory Fraction(int numerator, [int denominator = 1]) =>
      Fraction.big(BigInt.from(numerator), BigInt.from(denominator));

  /// Bina daripada [BigInt].
  factory Fraction.big(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('Penyebut tidak boleh sifar');
    }
    var n = numerator;
    var d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    if (n == BigInt.zero) {
      return Fraction._(BigInt.zero, BigInt.one);
    }
    final g = n.abs().gcd(d);
    return Fraction._(n ~/ g, d ~/ g);
  }

  /// Hurai daripada rentetan seperti `"1/8"`, `"3"`, atau `"0"`.
  factory Fraction.parse(String source) {
    final s = source.trim();
    if (!s.contains('/')) {
      return Fraction(int.parse(s));
    }
    final parts = s.split('/');
    if (parts.length != 2) {
      throw FormatException('Pecahan tidak sah: $source');
    }
    return Fraction(int.parse(parts[0].trim()), int.parse(parts[1].trim()));
  }

  final BigInt numerator;
  final BigInt denominator;

  static final Fraction zero = Fraction(0);
  static final Fraction one = Fraction(1);

  bool get isZero => numerator == BigInt.zero;
  bool get isPositive => numerator > BigInt.zero;
  bool get isNegative => numerator < BigInt.zero;

  Fraction operator +(Fraction other) => Fraction.big(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator -(Fraction other) => Fraction.big(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator *(Fraction other) => Fraction.big(
        numerator * other.numerator,
        denominator * other.denominator,
      );

  Fraction operator /(Fraction other) {
    if (other.isZero) throw ArgumentError('Bahagi dengan sifar');
    return Fraction.big(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  Fraction operator -() => Fraction._(-numerator, denominator);

  Fraction scale(int factor) =>
      Fraction.big(numerator * BigInt.from(factor), denominator);

  @override
  int compareTo(Fraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator <(Fraction other) => compareTo(other) < 0;
  bool operator <=(Fraction other) => compareTo(other) <= 0;
  bool operator >(Fraction other) => compareTo(other) > 0;
  bool operator >=(Fraction other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  /// Nilai `double` — hanya untuk paparan/donut chart, tidak pernah pengiraan.
  double toDouble() => numerator / denominator;

  @override
  String toString() =>
      denominator == BigInt.one ? '$numerator' : '$numerator/$denominator';

  /// LCM dua integer positif.
  static BigInt lcm(BigInt a, BigInt b) {
    if (a == BigInt.zero || b == BigInt.zero) return BigInt.zero;
    return (a ~/ a.gcd(b)) * b;
  }
}
