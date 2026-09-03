import 'enums.dart';
import 'fraction.dart';
import 'money.dart';
import 'trace.dart';

/// Tuntutan seorang (atau sekumpulan) waris.
class HeirClaim {
  const HeirClaim(this.type, {this.count = 1, this.nasabConfirmed = true})
      : assert(count > 0, 'Bilangan waris mesti > 0');

  final HeirType type;
  final int count;

  /// Daripada Nasab Engine. Jika `false`, waris ini ditapis keluar
  /// (SPEC 1.4 langkah 2, SPEC 2.5).
  final bool nasabConfirmed;

  HeirClaim copyWith({int? count}) =>
      HeirClaim(type, count: count ?? this.count, nasabConfirmed: nasabConfirmed);
}

/// Input kepada enjin faraid (SPEC 1.2).
class FaraidInput {
  const FaraidInput({
    required this.deceasedGender,
    required this.claims,
    this.ruleset = Ruleset.malaysiaSyafieV1,
    this.netEstate,
  });

  final Ruleset ruleset;
  final Gender deceasedGender;

  /// Harta pusaka BERSIH. Jika `null`, enjin hanya memulangkan pecahan
  /// tanpa nilai wang (pengguna hanya mahu tahu *siapa*).
  final Money? netEstate;

  final List<HeirClaim> claims;

  HeirClaim? claimOf(HeirType type) {
    for (final c in claims) {
      if (c.type == type) return c;
    }
    return null;
  }

  bool has(HeirType type) => claimOf(type) != null;
  int countOf(HeirType type) => claimOf(type)?.count ?? 0;
}

/// Bahagian seorang jenis waris.
class HeirShare {
  const HeirShare({
    required this.type,
    required this.count,
    required this.shareTotal,
    required this.shareEach,
    required this.basis,
    required this.reasonCode,
    this.amountTotal,
    this.amountEach,
    this.note,
  });

  final HeirType type;
  final int count;
  final Fraction shareEach;
  final Fraction shareTotal;
  final Money? amountTotal;
  final Money? amountEach;
  final ShareBasis basis;
  final String reasonCode;
  final String? note;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'count': count,
        'shareEach': shareEach.toString(),
        'shareTotal': shareTotal.toString(),
        if (amountTotal != null) 'amountTotal': amountTotal!.cents.toString(),
        if (amountEach != null) 'amountEach': amountEach!.cents.toString(),
        'basis': basis.name,
        'reasonCode': reasonCode,
        if (note != null) 'note': note,
      };
}

class BlockedHeir {
  const BlockedHeir(this.type, this.reason, {this.blockedBy = const []});
  final HeirType type;
  final String reason;
  final List<HeirType> blockedBy;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'reason': reason,
        if (blockedBy.isNotEmpty)
          'blockedBy': blockedBy.map((e) => e.name).toList(),
      };
}

/// Keputusan enjin (SPEC 1.2).
class FaraidResult {
  const FaraidResult({
    required this.status,
    required this.rulesetVersion,
    required this.shares,
    required this.blocked,
    required this.trace,
    required this.warnings,
    required this.asalMasalah,
    required this.asalMasalahAfterTashih,
    this.netEstate,
  });

  final ResultStatus status;
  final String rulesetVersion;
  final Money? netEstate;
  final List<HeirShare> shares;
  final List<BlockedHeir> blocked;
  final CalculationTrace trace;
  final List<Warning> warnings;

  /// Asal masalah asal (sebelum aul/radd/tashih).
  final int asalMasalah;

  /// Asal masalah selepas aul/radd/tashih (penyebut akhir saham).
  final int asalMasalahAfterTashih;

  bool get isOk => status == ResultStatus.ok;

  /// Jumlah semua bahagian — sepatutnya tepat 1 (kecuali radd tak lengkap /
  /// baki Baitulmal).
  Fraction get totalShare {
    var t = Fraction.zero;
    for (final s in shares) {
      t += s.shareTotal;
    }
    return t;
  }

  Map<String, Object?> toJson() => {
        'status': status.name,
        'rulesetVersion': rulesetVersion,
        if (netEstate != null) 'netEstate': netEstate!.cents.toString(),
        'asalMasalah': asalMasalah,
        'asalMasalahAfterTashih': asalMasalahAfterTashih,
        'shares': shares.map((s) => s.toJson()).toList(),
        'blocked': blocked.map((b) => b.toJson()).toList(),
        'warnings': warnings.map((w) => w.toJson()).toList(),
        'trace': trace.toJson(),
      };
}
