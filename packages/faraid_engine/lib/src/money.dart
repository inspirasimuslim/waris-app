import 'fraction.dart';

/// Wang dalam unit terkecil (sen) sebagai [BigInt] — tiada `double`.
///
/// Pembahagian harta menggunakan [splitBy] yang mengagihkan baki sen secara
/// deterministik (kaedah baki terbesar) supaya jumlah sentiasa tepat.
class Money implements Comparable<Money> {
  const Money._(this.cents);

  factory Money.fromCents(BigInt cents) => Money._(cents);

  /// Bina daripada nilai ringgit (boleh ada perpuluhan sen).
  factory Money.ringgit(num amount) =>
      Money._(BigInt.from((amount * 100).round()));

  factory Money.parse(String source) =>
      Money.ringgit(num.parse(source.replaceAll(',', '').trim()));

  final BigInt cents;

  static final Money zero = Money._(BigInt.zero);

  bool get isZero => cents == BigInt.zero;
  double get ringgit => cents / BigInt.from(100);

  Money operator +(Money other) => Money._(cents + other.cents);
  Money operator -(Money other) => Money._(cents - other.cents);

  Money fractionOf(Fraction f) =>
      Money._((cents * f.numerator) ~/ f.denominator);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && cents == other.cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() {
    final neg = cents.isNegative;
    final abs = cents.abs();
    final r = abs ~/ BigInt.from(100);
    final c = (abs % BigInt.from(100)).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}RM $r.$c';
  }

  /// Agih [this] mengikut senarai [weights] (pecahan bahagian setiap penerima).
  /// Jumlah [weights] mesti = 1. Baki sen diagih kepada penerima dengan baki
  /// pembahagian terbesar (deterministik, stabil mengikut indeks).
  List<Money> splitBy(List<Fraction> weights) {
    if (weights.isEmpty) return const [];
    var sum = Fraction.zero;
    for (final w in weights) {
      sum += w;
    }
    assert(sum == Fraction.one, 'Jumlah berat mesti 1, dapat $sum');

    final base = <BigInt>[];
    final remainders = <BigInt>[];
    for (final w in weights) {
      final scaled = cents * w.numerator;
      base.add(scaled ~/ w.denominator);
      remainders.add(scaled % w.denominator);
    }
    final distributed = base.fold(BigInt.zero, (BigInt a, BigInt b) => a + b);
    var leftover = cents - distributed;

    // Susun indeks mengikut baki relatif (remainder / denominator) menurun.
    final order = List<int>.generate(weights.length, (i) => i)
      ..sort((a, b) {
        final ra = remainders[a] * weights[b].denominator;
        final rb = remainders[b] * weights[a].denominator;
        final cmp = rb.compareTo(ra);
        return cmp != 0 ? cmp : a.compareTo(b);
      });

    final result = List<BigInt>.from(base);
    var idx = 0;
    while (leftover > BigInt.zero && idx < order.length) {
      result[order[idx]] += BigInt.one;
      leftover -= BigInt.one;
      idx++;
    }
    return result.map(Money._).toList();
  }
}
