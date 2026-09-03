import 'enums.dart';
import 'fraction.dart';
import 'model.dart';
import 'money.dart';
import 'reason_codes.dart';
import 'trace.dart';

/// Enjin faraid deterministik rule-based (SPEC 1.4). Bukan AI.
///
/// Skop MVP: fardu, asabah (bi-nafsihi / bi-ghayrihi / ma'a-ghayrihi),
/// hajb hirman & nuqsan, aul, radd, tashih, umariyyatain, akdariyyah,
/// jadd wal-ikhwah asas. Keadaan di luar skop dibendera `requiresManualReview`.
class FaraidEngine {
  const FaraidEngine();

  FaraidResult calculate(FaraidInput input) {
    final ctx = _Ctx(input);

    _validate(ctx);
    if (ctx.invalid) return ctx.buildInvalid();

    _nasabFilter(ctx);
    ctx.siblingCountForMother = ctx.siblingCountAll;
    _flagOutOfScope(ctx);

    if (_isAkdariyyah(ctx)) {
      _applyAkdariyyah(ctx);
      return ctx.build();
    }

    // Umariyyatain diperiksa terhadap set waris sebenar (selepas tapisan nasab,
    // sebelum hajb) — waris yang HANYA terhijab hajb tetap mengubah bahagian ibu.
    if (_tryUmariyyatain(ctx)) {
      _tashihAndMoney(ctx);
      _validateTotals(ctx);
      return ctx.build();
    }

    _hajb(ctx);

    _assignFurud(ctx);
    _resolveAsabah(ctx);
    _aulOrRadd(ctx);
    _tashihAndMoney(ctx);
    _validateTotals(ctx);
    return ctx.build();
  }
}

// ---------------------------------------------------------------------------
// Konteks pengiraan mutable.
// ---------------------------------------------------------------------------

class _Assign {
  _Assign(this.shareTotal, this.basis, this.reasonCode, this.count, {this.note});
  Fraction shareTotal;
  ShareBasis basis;
  String reasonCode;
  int count;
  String? note;
}

class _Ctx {
  _Ctx(this.input) {
    for (final c in input.claims) {
      present[c.type] = (present[c.type] ?? 0) + c.count;
      if (!c.nasabConfirmed) unconfirmed.add(c.type);
    }
  }

  final FaraidInput input;
  final Map<HeirType, int> present = {};
  final Set<HeirType> unconfirmed = {};
  final trace = CalculationTrace();
  final warnings = <Warning>[];
  final blocked = <BlockedHeir>[];
  final Map<HeirType, _Assign> assigned = {};

  bool invalid = false;
  bool manualReview = false;

  /// Bilangan adik-beradik (semua jenis) selepas tapisan nasab tetapi SEBELUM
  /// hajb — untuk syarat `jam' min al-ikhwah` yang menurunkan ibu kepada 1/6
  /// walaupun adik-beradik itu terdinding hajb.
  int siblingCountForMother = 0;
  int originalAm = 1;

  int count(HeirType t) => present[t] ?? 0;
  bool has(HeirType t) => count(t) > 0;

  void remove(HeirType t, String reason, {List<HeirType> by = const []}) {
    if (!has(t)) return;
    present.remove(t);
    blocked.add(BlockedHeir(t, reason, blockedBy: by));
    trace.add('hajb', reason, affected: [t]);
  }

  void assign(
    HeirType t,
    Fraction shareTotal,
    ShareBasis basis,
    String reasonCode, {
    String? note,
  }) {
    assigned[t] = _Assign(shareTotal, basis, reasonCode, count(t), note: note);
  }

  // --- predikat waris ---
  bool get hasMaleDescendant => has(HeirType.son) || has(HeirType.sonsSon);
  bool get hasFarWarith =>
      hasMaleDescendant ||
      has(HeirType.daughter) ||
      has(HeirType.sonsDaughter);
  bool get hasFemaleDescendantOnly =>
      !hasMaleDescendant &&
      (has(HeirType.daughter) || has(HeirType.sonsDaughter));
  bool get hasFather => has(HeirType.father);
  bool get hasGrandfather => has(HeirType.paternalGrandfather);
  bool get hasMaleAscendant => hasFather || hasGrandfather;

  int get siblingCountAll =>
      count(HeirType.fullBrother) +
      count(HeirType.fullSister) +
      count(HeirType.paternalBrother) +
      count(HeirType.paternalSister) +
      count(HeirType.maternalSibling);

  Fraction get assignedSum {
    var s = Fraction.zero;
    for (final a in assigned.values) {
      s += a.shareTotal;
    }
    return s;
  }

  FaraidResult buildInvalid() => FaraidResult(
        status: ResultStatus.invalidInput,
        rulesetVersion: input.ruleset.version,
        shares: const [],
        blocked: blocked,
        trace: trace,
        warnings: warnings,
        asalMasalah: 0,
        asalMasalahAfterTashih: 0,
        netEstate: input.netEstate,
      );

  FaraidResult build() {
    final shares = <HeirShare>[];
    // Susun ikut urutan enum (stabil, mudah dibaca).
    final types = assigned.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    var afterTashih = BigInt.one;
    for (final t in types) {
      final a = assigned[t]!;
      final each = a.count == 0
          ? a.shareTotal
          : a.shareTotal / Fraction(a.count);
      afterTashih = Fraction.lcm(afterTashih, each.denominator);
    }

    for (final t in types) {
      final a = assigned[t]!;
      final each = a.count <= 1
          ? a.shareTotal
          : a.shareTotal / Fraction(a.count);
      Money? amtTotal;
      Money? amtEach;
      if (input.netEstate != null) {
        amtTotal = input.netEstate!.fractionOf(a.shareTotal);
        amtEach = a.count <= 1 ? amtTotal : input.netEstate!.fractionOf(each);
      }
      shares.add(HeirShare(
        type: t,
        count: a.count,
        shareTotal: a.shareTotal,
        shareEach: each,
        amountTotal: amtTotal,
        amountEach: amtEach,
        basis: a.basis,
        reasonCode: a.reasonCode,
        note: a.note,
      ));
    }

    // Agihan wang tepat (kaedah baki sen) supaya jumlah = netEstate.
    if (input.netEstate != null && shares.isNotEmpty) {
      _distributeMoneyExact(shares, input.netEstate!);
    }

    return FaraidResult(
      status: manualReview
          ? ResultStatus.requiresManualReview
          : ResultStatus.ok,
      rulesetVersion: input.ruleset.version,
      shares: shares,
      blocked: blocked,
      trace: trace,
      warnings: warnings,
      asalMasalah: originalAm,
      asalMasalahAfterTashih: afterTashih.toInt(),
      netEstate: input.netEstate,
    );
  }

  void _distributeMoneyExact(List<HeirShare> shares, Money estate) {
    final weights = shares.map((s) => s.shareTotal).toList();
    var sum = Fraction.zero;
    for (final w in weights) {
      sum += w;
    }
    // Radd tak lengkap / aul sudah menjadikan sum == 1; jika sum < 1 (Baitulmal),
    // agih hanya bahagian yang ada dan biarkan bakinya (tidak diagihkan).
    final normalized = sum == Fraction.one
        ? weights
        : weights.map((w) => w / sum).toList();
    final portions = sum == Fraction.one
        ? estate.splitBy(normalized)
        : _splitPartial(estate, weights);
    for (var i = 0; i < shares.length; i++) {
      final s = shares[i];
      final total = portions[i];
      shares[i] = HeirShare(
        type: s.type,
        count: s.count,
        shareTotal: s.shareTotal,
        shareEach: s.shareEach,
        amountTotal: total,
        amountEach: s.count <= 1
            ? total
            : Money.fromCents(total.cents ~/ BigInt.from(s.count)),
        basis: s.basis,
        reasonCode: s.reasonCode,
        note: s.note,
      );
    }
  }

  List<Money> _splitPartial(Money estate, List<Fraction> weights) =>
      weights
          .map((w) => Money.fromCents(
                (estate.cents * w.numerator) ~/ w.denominator,
              ))
          .toList();
}

// ---------------------------------------------------------------------------
// 1. Validation
// ---------------------------------------------------------------------------

void _validate(_Ctx ctx) {
  final i = ctx.input;
  if (i.claims.isEmpty) {
    ctx.invalid = true;
    ctx.warnings.add(const Warning(
        WarningLevel.blocking, 'no_heirs', 'Tiada waris dinyatakan.'));
    return;
  }
  if (i.deceasedGender == Gender.male && ctx.has(HeirType.husband)) {
    ctx.invalid = true;
    ctx.warnings.add(const Warning(WarningLevel.blocking, 'gender_conflict',
        'Si mati lelaki tidak boleh mempunyai suami.'));
  }
  if (i.deceasedGender == Gender.female && ctx.has(HeirType.wife)) {
    ctx.invalid = true;
    ctx.warnings.add(const Warning(WarningLevel.blocking, 'gender_conflict',
        'Si mati perempuan tidak boleh mempunyai isteri.'));
  }
  if (ctx.count(HeirType.husband) > 1) {
    ctx.invalid = true;
    ctx.warnings.add(const Warning(WarningLevel.blocking, 'count',
        'Hanya seorang suami dibenarkan.'));
  }
  if (ctx.count(HeirType.wife) > 4) {
    ctx.invalid = true;
    ctx.warnings.add(const Warning(WarningLevel.blocking, 'count',
        'Maksimum empat isteri.'));
  }
  for (final t in const [
    HeirType.father,
    HeirType.mother,
    HeirType.paternalGrandfather,
  ]) {
    if (ctx.count(t) > 1) {
      ctx.invalid = true;
      ctx.warnings.add(Warning(WarningLevel.blocking, 'count',
          'Hanya seorang ${t.name} dibenarkan.'));
    }
  }
  if (!ctx.invalid) {
    ctx.trace.add('validation', 'Input sah: ${i.claims.length} kumpulan waris, '
        'si mati ${i.deceasedGender.name}.');
  }
}

// ---------------------------------------------------------------------------
// 2. Nasab filter (SPEC 1.4 langkah 2)
// ---------------------------------------------------------------------------

void _nasabFilter(_Ctx ctx) {
  if (ctx.unconfirmed.isEmpty) return;
  for (final t in ctx.unconfirmed) {
    ctx.present.remove(t);
    ctx.blocked.add(BlockedHeir(t, 'Nasab tidak sabit — tidak dimasukkan '
        'sebagai waris.'));
    ctx.trace.add('nasab', 'Waris ${t.name} ditapis keluar kerana nasab '
        'tidak sabit kepada si mati.', affected: [t]);
    ctx.warnings.add(Warning(WarningLevel.caution, 'nasab_filtered',
        'Waris ${t.name} tidak dikira kerana nasab tidak sabit.'));
  }
}

// ---------------------------------------------------------------------------
// Bendera keadaan di luar skop MVP (SPEC 1.5)
// ---------------------------------------------------------------------------

void _flagOutOfScope(_Ctx ctx) {
  // Musyarakah / Himariyyah: suami + ibu + >=2 saudara seibu + saudara s.i.s.
  final musharakah = ctx.has(HeirType.husband) &&
      ctx.has(HeirType.mother) &&
      ctx.count(HeirType.maternalSibling) >= 2 &&
      ctx.has(HeirType.fullBrother) &&
      !ctx.hasFarWarith &&
      !ctx.hasMaleAscendant;
  if (musharakah) {
    ctx.manualReview = true;
    ctx.warnings.add(const Warning(WarningLevel.caution, 'musharakah',
        'Kes musyarakah (himariyyah) di luar skop MVP — perlu semakan manual.'));
    ctx.trace.add('special', 'Dikesan corak musyarakah; enjin membendera dan '
        'tidak menjamin angka.');
  }
}

// ---------------------------------------------------------------------------
// 3. Hajb hirman (SPEC 1.4 langkah 3, FARAID_RULES §3)
// ---------------------------------------------------------------------------

void _hajb(_Ctx ctx) {
  final hasSon = ctx.has(HeirType.son);
  final hasSonsSon = ctx.has(HeirType.sonsSon);
  final hasMaleDesc = hasSon || hasSonsSon;
  final hasFar = ctx.hasFarWarith;
  final hasFather = ctx.hasFather;
  final hasGrandfather = ctx.hasGrandfather;
  final hasMother = ctx.has(HeirType.mother);

  // Cucu lelaki terhijab oleh anak lelaki.
  if (hasSon && ctx.has(HeirType.sonsSon)) {
    ctx.remove(HeirType.sonsSon, 'Cucu lelaki terdinding oleh anak lelaki.',
        by: [HeirType.son]);
  }
  // Cucu perempuan terhijab oleh anak lelaki, atau oleh 2+ anak perempuan
  // (kecuali ada cucu lelaki yang menjadikannya asabah).
  if (ctx.has(HeirType.sonsDaughter)) {
    if (hasSon) {
      ctx.remove(HeirType.sonsDaughter,
          'Cucu perempuan terdinding oleh anak lelaki.', by: [HeirType.son]);
    } else if (ctx.count(HeirType.daughter) >= 2 &&
        !ctx.has(HeirType.sonsSon)) {
      ctx.remove(HeirType.sonsDaughter,
          'Cucu perempuan terdinding oleh dua atau lebih anak perempuan '
          '(tiada cucu lelaki untuk menjadikannya asabah).',
          by: [HeirType.daughter]);
    }
  }

  // Datuk terhijab oleh bapa.
  if (hasFather && hasGrandfather) {
    ctx.remove(HeirType.paternalGrandfather, 'Datuk terdinding oleh bapa.',
        by: [HeirType.father]);
  }

  // Nenek sebelah ibu terhijab oleh ibu.
  if (hasMother && ctx.has(HeirType.maternalGrandmother)) {
    ctx.remove(HeirType.maternalGrandmother,
        'Nenek sebelah ibu terdinding oleh ibu.', by: [HeirType.mother]);
  }
  // Nenek sebelah bapa terhijab oleh ibu dan bapa.
  if (ctx.has(HeirType.paternalGrandmother)) {
    if (hasMother) {
      ctx.remove(HeirType.paternalGrandmother,
          'Nenek sebelah bapa terdinding oleh ibu.', by: [HeirType.mother]);
    } else if (hasFather) {
      ctx.remove(HeirType.paternalGrandmother,
          'Nenek sebelah bapa terdinding oleh bapa.', by: [HeirType.father]);
    }
  }

  // Saudara seibu terhijab oleh far' warith (mutlak) dan usul lelaki.
  if (ctx.has(HeirType.maternalSibling) &&
      (hasFar || ctx.hasMaleAscendant)) {
    ctx.remove(HeirType.maternalSibling,
        'Saudara seibu terdinding oleh keturunan atau usul lelaki (bukan kes '
        'kalalah).',
        by: [
          if (hasMaleDesc) HeirType.son,
          if (ctx.has(HeirType.daughter)) HeirType.daughter,
          if (hasFather) HeirType.father,
          if (hasGrandfather) HeirType.paternalGrandfather,
        ]);
  }

  // Saudara seibu-sebapa terhijab oleh anak lelaki, cucu lelaki, bapa.
  final blocksSiblings = <HeirType>[
    if (hasSon) HeirType.son,
    if (hasSonsSon) HeirType.sonsSon,
    if (hasFather) HeirType.father,
  ];
  if (blocksSiblings.isNotEmpty) {
    for (final t in const [HeirType.fullBrother, HeirType.fullSister]) {
      ctx.remove(t, 'Saudara seibu-sebapa terdinding oleh keturunan lelaki '
          'atau bapa.', by: blocksSiblings);
    }
  }
  // Saudara sebapa terhijab oleh di atas + saudara lelaki s.i.s + s/p s.i.s
  // yang menjadi asabah ma'a-ghayrihi (ditangani kemudian bila far' perempuan).
  final blocksPaternal = <HeirType>[
    ...blocksSiblings,
    if (ctx.has(HeirType.fullBrother)) HeirType.fullBrother,
  ];
  // 2+ saudara perempuan s.i.s menghijab saudara sebapa (kecuali ada saudara
  // lelaki sebapa yang menjadikannya asabah bi-ghayrihi).
  if (ctx.count(HeirType.fullSister) >= 2 &&
      !ctx.has(HeirType.paternalBrother)) {
    blocksPaternal.add(HeirType.fullSister);
  }
  // Seorang saudara perempuan s.i.s yang menjadi asabah ma'a-ghayrihi (bersama
  // anak / cucu perempuan, tanpa keturunan lelaki atau bapa) berkelakuan
  // seperti saudara lelaki s.i.s dan menghijab semua saudara sebapa.
  final femaleDescForSister =
      ctx.has(HeirType.daughter) || ctx.has(HeirType.sonsDaughter);
  if (femaleDescForSister &&
      ctx.has(HeirType.fullSister) &&
      !hasSon &&
      !hasSonsSon &&
      !hasFather &&
      !blocksPaternal.contains(HeirType.fullSister)) {
    blocksPaternal.add(HeirType.fullSister);
  }
  if (blocksPaternal.isNotEmpty) {
    for (final t in const [HeirType.paternalBrother, HeirType.paternalSister]) {
      ctx.remove(t, 'Saudara sebapa terdinding oleh saudara seibu-sebapa atau '
          'keturunan lelaki / bapa.', by: blocksPaternal);
    }
  }

  // Rantaian asabah jauh: anak saudara, bapa saudara, sepupu — terhijab oleh
  // mana-mana asabah yang lebih hampir.
  _blockDistantAsabah(ctx);
}

const _asabahOrder = <HeirType>[
  HeirType.son,
  HeirType.sonsSon,
  HeirType.father,
  HeirType.paternalGrandfather,
  HeirType.fullBrother,
  HeirType.paternalBrother,
  HeirType.fullBrothersSon,
  HeirType.paternalBrothersSon,
  HeirType.fullPaternalUncle,
  HeirType.paternalUncle,
  HeirType.fullPaternalUnclesSon,
  HeirType.paternalUnclesSon,
];

void _blockDistantAsabah(_Ctx ctx) {
  final distant = const [
    HeirType.fullBrothersSon,
    HeirType.paternalBrothersSon,
    HeirType.fullPaternalUncle,
    HeirType.paternalUncle,
    HeirType.fullPaternalUnclesSon,
    HeirType.paternalUnclesSon,
  ];
  for (final t in distant) {
    if (!ctx.has(t)) continue;
    final myRank = _asabahOrder.indexOf(t);
    HeirType? closer;
    for (var r = 0; r < myRank; r++) {
      final o = _asabahOrder[r];
      if (o == HeirType.father || o == HeirType.paternalGrandfather) {
        // Bapa/datuk juga menghijab asabah saudara & seterusnya.
        if (ctx.has(o)) {
          closer = o;
          break;
        }
        continue;
      }
      if (ctx.has(o)) {
        closer = o;
        break;
      }
    }
    if (closer != null) {
      ctx.remove(t, 'Asabah lebih jauh (${t.name}) terdinding oleh asabah lebih '
          'hampir (${closer.name}).', by: [closer]);
    }
  }
}

// ---------------------------------------------------------------------------
// Umariyyatain / Gharrawain (SPEC 1.4 langkah 8, FARAID_RULES §5)
// ---------------------------------------------------------------------------

bool _tryUmariyyatain(_Ctx ctx) {
  // Definisi ketat: waris sebenar (selepas tapisan nasab) hanya pasangan +
  // ibu + bapa. Waris yang terhijab hajb TIDAK dibenarkan di sini kerana
  // kehadiran mereka mengubah bahagian ibu.
  final presentTypes = ctx.present.keys.toSet();
  final onlySpouseAndParents = presentTypes.difference({
        HeirType.husband,
        HeirType.wife,
        HeirType.mother,
        HeirType.father,
      }).isEmpty &&
      ctx.has(HeirType.mother) &&
      ctx.has(HeirType.father) &&
      (ctx.has(HeirType.husband) || ctx.has(HeirType.wife)) &&
      ctx.count(HeirType.mother) == 1 &&
      ctx.count(HeirType.father) == 1;
  if (!onlySpouseAndParents) return false;

  ctx.trace.add('special', 'Umariyyatain: pasangan + ibu + bapa sahaja. Ibu '
      'mengambil 1/3 daripada BAKI selepas bahagian pasangan, bukan 1/3 harta.',
      reasonCode: R.umariyyatain);

  if (ctx.has(HeirType.husband)) {
    ctx.originalAm = 6;
    ctx.assign(HeirType.husband, Fraction(1, 2), ShareBasis.fardu,
        R.husbandHalf);
    ctx.assign(HeirType.mother, Fraction(1, 6), ShareBasis.fardu,
        R.motherThirdOfRemainder,
        note: '1/3 daripada baki (1/2)');
    ctx.assign(HeirType.father, Fraction(1, 3), ShareBasis.asabah,
        R.fatherAsabah);
  } else {
    ctx.originalAm = 4;
    ctx.assign(HeirType.wife, Fraction(1, 4), ShareBasis.fardu, R.wifeQuarter);
    ctx.assign(HeirType.mother, Fraction(1, 4), ShareBasis.fardu,
        R.motherThirdOfRemainder,
        note: '1/3 daripada baki (3/4)');
    ctx.assign(HeirType.father, Fraction(1, 2), ShareBasis.asabah,
        R.fatherAsabah);
  }
  return true;
}

// ---------------------------------------------------------------------------
// Akdariyyah (FARAID_RULES §5)
// ---------------------------------------------------------------------------

bool _isAkdariyyah(_Ctx ctx) {
  if (ctx.input.deceasedGender != Gender.female) return false;
  final keys = ctx.present.keys.toSet();
  final oneFullSister = ctx.count(HeirType.fullSister) == 1;
  final onePaternalSister = ctx.count(HeirType.paternalSister) == 1;
  final sisterKey =
      oneFullSister ? HeirType.fullSister : HeirType.paternalSister;
  return ctx.has(HeirType.husband) &&
      ctx.has(HeirType.mother) &&
      ctx.has(HeirType.paternalGrandfather) &&
      (oneFullSister ^ onePaternalSister) &&
      keys.difference({
        HeirType.husband,
        HeirType.mother,
        HeirType.paternalGrandfather,
        sisterKey,
      }).isEmpty;
}

void _applyAkdariyyah(_Ctx ctx) {
  final sisterKey = ctx.count(HeirType.fullSister) == 1
      ? HeirType.fullSister
      : HeirType.paternalSister;
  ctx.originalAm = 6;
  ctx.trace.add('special',
      'Akdariyyah: suami + ibu + datuk + seorang saudara perempuan. Asal '
      'masalah 6, di-aul kepada 9, kemudian bahagian datuk & saudara '
      'perempuan digabung dan dibahagi 2:1 — ditashih kepada 27.',
      reasonCode: R.akdariyyah);
  // Keputusan piawai: H 9/27, M 6/27, GF 8/27, Sister 4/27.
  ctx.assign(HeirType.husband, Fraction(9, 27), ShareBasis.aul, R.husbandHalf);
  ctx.assign(HeirType.mother, Fraction(6, 27), ShareBasis.aul, R.motherThird);
  ctx.assign(HeirType.paternalGrandfather, Fraction(8, 27), ShareBasis.asabah,
      R.grandfatherBestOfThree);
  ctx.assign(sisterKey, Fraction(4, 27), ShareBasis.asabah,
      R.fullSisterAsabahBiGhayrihi,
      note: 'Digabung dengan datuk, nisbah 2:1');
  _tashihAndMoney(ctx);
  _validateTotals(ctx);
}

// ---------------------------------------------------------------------------
// 4. Furud assignment (SPEC 1.4 langkah 4)
// ---------------------------------------------------------------------------

void _assignFurud(_Ctx ctx) {
  final hasFar = ctx.hasFarWarith;

  // --- Pasangan ---
  if (ctx.has(HeirType.husband)) {
    ctx.assign(
        HeirType.husband,
        hasFar ? Fraction(1, 4) : Fraction(1, 2),
        ShareBasis.fardu,
        hasFar ? R.husbandQuarter : R.husbandHalf);
    ctx.trace.add('furud',
        hasFar
            ? 'Suami 1/4 kerana si mati mempunyai keturunan yang mewarisi.'
            : 'Suami 1/2 kerana si mati tiada keturunan yang mewarisi.',
        affected: [HeirType.husband],
        fraction: hasFar ? Fraction(1, 4) : Fraction(1, 2));
  }
  if (ctx.has(HeirType.wife)) {
    ctx.assign(
        HeirType.wife,
        hasFar ? Fraction(1, 8) : Fraction(1, 4),
        ShareBasis.fardu,
        hasFar ? R.wifeEighth : R.wifeQuarter);
    ctx.trace.add('furud',
        hasFar
            ? 'Isteri 1/8 (dikongsi) kerana si mati mempunyai keturunan.'
            : 'Isteri 1/4 (dikongsi) kerana si mati tiada keturunan.',
        affected: [HeirType.wife],
        fraction: hasFar ? Fraction(1, 8) : Fraction(1, 4));
  }

  // --- Ibu ---
  if (ctx.has(HeirType.mother)) {
    final reduced = hasFar || ctx.siblingCountForMother >= 2;
    ctx.assign(HeirType.mother, reduced ? Fraction(1, 6) : Fraction(1, 3),
        ShareBasis.fardu, reduced ? R.motherSixth : R.motherThird);
    ctx.trace.add('furud',
        reduced
            ? 'Ibu 1/6 kerana ada keturunan atau dua/lebih adik-beradik.'
            : 'Ibu 1/3 kerana tiada keturunan dan kurang daripada dua '
                'adik-beradik.',
        affected: [HeirType.mother],
        fraction: reduced ? Fraction(1, 6) : Fraction(1, 3));
  }

  // --- Nenek (sahih) ---
  final grandmothers = <HeirType>[
    if (ctx.has(HeirType.maternalGrandmother)) HeirType.maternalGrandmother,
    if (ctx.has(HeirType.paternalGrandmother)) HeirType.paternalGrandmother,
  ];
  if (grandmothers.isNotEmpty) {
    final each = Fraction(1, 6) / Fraction(grandmothers.length);
    for (final g in grandmothers) {
      ctx.assign(g, each, ShareBasis.fardu, R.grandmotherSixth);
    }
    ctx.trace.add('furud', 'Nenek 1/6 (dikongsi ${grandmothers.length} nenek).',
        affected: grandmothers, fraction: Fraction(1, 6));
  }

  // --- Bapa ---
  if (ctx.hasFather) {
    if (ctx.hasMaleDescendant) {
      ctx.assign(HeirType.father, Fraction(1, 6), ShareBasis.fardu,
          R.fatherSixth);
      ctx.trace.add('furud', 'Bapa 1/6 kerana ada keturunan lelaki.',
          affected: [HeirType.father], fraction: Fraction(1, 6));
    } else if (ctx.hasFemaleDescendantOnly) {
      ctx.assign(HeirType.father, Fraction(1, 6), ShareBasis.fardu,
          R.fatherSixthPlusAsabah,
          note: '1/6 fardu + baki sebagai asabah');
      ctx.trace.add('furud',
          'Bapa 1/6 fardu + asabah kerana keturunan perempuan sahaja.',
          affected: [HeirType.father]);
    } else {
      // Asabah penuh — ditangani dalam _resolveAsabah.
    }
  }

  // --- Datuk (bila tiada bapa) ---
  if (ctx.hasGrandfather && !ctx.hasFather) {
    _assignGrandfather(ctx);
  }

  // --- Anak perempuan ---
  if (ctx.has(HeirType.daughter) && !ctx.has(HeirType.son)) {
    final n = ctx.count(HeirType.daughter);
    final total = n == 1 ? Fraction(1, 2) : Fraction(2, 3);
    ctx.assign(HeirType.daughter, total, ShareBasis.fardu,
        n == 1 ? R.daughterHalf : R.daughterTwoThirds);
    ctx.trace.add('furud',
        n == 1
            ? 'Anak perempuan tunggal 1/2.'
            : 'Anak perempuan ($n) berkongsi 2/3.',
        affected: [HeirType.daughter], fraction: total);
  }

  // --- Cucu perempuan ---
  if (ctx.has(HeirType.sonsDaughter) && !ctx.has(HeirType.sonsSon)) {
    final nD = ctx.count(HeirType.daughter);
    final nSD = ctx.count(HeirType.sonsDaughter);
    if (nD == 0) {
      final total = nSD == 1 ? Fraction(1, 2) : Fraction(2, 3);
      ctx.assign(HeirType.sonsDaughter, total, ShareBasis.fardu,
          nSD == 1 ? R.sonsDaughterHalf : R.sonsDaughterTwoThirds);
      ctx.trace.add('furud',
          nSD == 1 ? 'Cucu perempuan 1/2.' : 'Cucu perempuan 2/3.',
          affected: [HeirType.sonsDaughter], fraction: total);
    } else if (nD == 1) {
      // Takmilah tuluthain: 1/6.
      ctx.assign(HeirType.sonsDaughter, Fraction(1, 6), ShareBasis.fardu,
          R.sonsDaughterSixth,
          note: 'Melengkapkan 2/3 bersama seorang anak perempuan');
      ctx.trace.add('furud',
          'Cucu perempuan 1/6 (melengkapkan 2/3 bersama seorang anak '
          'perempuan).',
          affected: [HeirType.sonsDaughter], fraction: Fraction(1, 6));
    }
  }

  // --- Saudara seibu ---
  if (ctx.has(HeirType.maternalSibling)) {
    final n = ctx.count(HeirType.maternalSibling);
    final total = n == 1 ? Fraction(1, 6) : Fraction(1, 3);
    ctx.assign(HeirType.maternalSibling, total, ShareBasis.fardu,
        n == 1 ? R.maternalSiblingSixth : R.maternalSiblingThird);
    ctx.trace.add('furud',
        n == 1
            ? 'Saudara seibu tunggal 1/6.'
            : 'Saudara seibu ($n) berkongsi 1/3 sama rata.',
        affected: [HeirType.maternalSibling], fraction: total);
  }

  // --- Saudara perempuan s.i.s / sebapa (bila kalalah & bukan asabah) ---
  _assignSisters(ctx);

  ctx.originalAm = _lcmOfDenominators(ctx.assigned.values.map((a) => a.shareTotal));
}

void _assignGrandfather(_Ctx ctx) {
  final hasFullSib = ctx.has(HeirType.fullBrother) || ctx.has(HeirType.fullSister);
  final hasPatSib =
      ctx.has(HeirType.paternalBrother) || ctx.has(HeirType.paternalSister);
  if (!hasFullSib && !hasPatSib) {
    if (ctx.hasMaleDescendant) {
      ctx.assign(HeirType.paternalGrandfather, Fraction(1, 6), ShareBasis.fardu,
          R.grandfatherSixth);
      ctx.trace.add('furud', 'Datuk 1/6 kerana ada keturunan lelaki.',
          affected: [HeirType.paternalGrandfather], fraction: Fraction(1, 6));
    } else if (ctx.hasFemaleDescendantOnly) {
      ctx.assign(HeirType.paternalGrandfather, Fraction(1, 6), ShareBasis.fardu,
          R.grandfatherSixthPlusAsabah, note: '1/6 fardu + baki asabah');
      ctx.trace.add('furud', 'Datuk 1/6 fardu + asabah (keturunan perempuan '
          'sahaja).', affected: [HeirType.paternalGrandfather]);
    }
    // else: asabah penuh dalam _resolveAsabah.
    return;
  }
  // Jadd wal-ikhwah — ditangani dalam _resolveAsabah selepas furud lain.
  ctx.trace.add('special', 'Datuk bersama adik-beradik (jadd wal-ikhwah): '
      'datuk mengambil yang terbaik antara 1/3 harta, muqasamah, atau 1/6.',
      reasonCode: R.grandfatherBestOfThree);
}

void _assignSisters(_Ctx ctx) {
  final hasBlockingMale = ctx.has(HeirType.son) ||
      ctx.has(HeirType.sonsSon) ||
      ctx.hasFather;
  if (hasBlockingMale) return;

  // Datuk bersama saudara dikendalikan oleh _resolveJaddWalIkhwah.
  if (ctx.hasGrandfather && !ctx.hasFather) return;

  final femaleDesc =
      ctx.has(HeirType.daughter) || ctx.has(HeirType.sonsDaughter);

  // Saudara perempuan s.i.s
  if (ctx.has(HeirType.fullSister) && !ctx.has(HeirType.fullBrother)) {
    if (femaleDesc) {
      // asabah ma'a-ghayrihi — ditangani dalam _resolveAsabah.
    } else {
      final n = ctx.count(HeirType.fullSister);
      final total = n == 1 ? Fraction(1, 2) : Fraction(2, 3);
      ctx.assign(HeirType.fullSister, total, ShareBasis.fardu,
          n == 1 ? R.fullSisterHalf : R.fullSisterTwoThirds);
      ctx.trace.add('furud',
          n == 1 ? 'Saudara perempuan s.i.s 1/2.' : 'Saudara perempuan s.i.s 2/3.',
          affected: [HeirType.fullSister], fraction: total);
    }
  }

  // Saudara perempuan sebapa
  if (ctx.has(HeirType.paternalSister) && !ctx.has(HeirType.paternalBrother)) {
    final fullSisterAsFurud = ctx.assigned.containsKey(HeirType.fullSister) &&
        ctx.assigned[HeirType.fullSister]!.basis == ShareBasis.fardu;
    final oneFullSisterHalf =
        ctx.count(HeirType.fullSister) == 1 && fullSisterAsFurud;
    final twoFullSisters = ctx.count(HeirType.fullSister) >= 2;
    if (femaleDesc && !ctx.has(HeirType.fullSister)) {
      // asabah ma'a-ghayrihi — _resolveAsabah.
    } else if (twoFullSisters) {
      // Terhijab (sudah dikeluarkan dalam _hajb bila tiada sdr lelaki sebapa).
    } else if (oneFullSisterHalf) {
      ctx.assign(HeirType.paternalSister, Fraction(1, 6), ShareBasis.fardu,
          R.paternalSisterSixth,
          note: 'Melengkapkan 2/3 bersama seorang saudara perempuan s.i.s');
      ctx.trace.add('furud', 'Saudara perempuan sebapa 1/6 (takmilah).',
          affected: [HeirType.paternalSister], fraction: Fraction(1, 6));
    } else if (!ctx.has(HeirType.fullSister)) {
      final n = ctx.count(HeirType.paternalSister);
      final total = n == 1 ? Fraction(1, 2) : Fraction(2, 3);
      ctx.assign(HeirType.paternalSister, total, ShareBasis.fardu,
          n == 1 ? R.paternalSisterHalf : R.paternalSisterTwoThirds);
      ctx.trace.add('furud',
          n == 1
              ? 'Saudara perempuan sebapa 1/2.'
              : 'Saudara perempuan sebapa 2/3.',
          affected: [HeirType.paternalSister], fraction: total);
    }
  }
}

// ---------------------------------------------------------------------------
// 5. Asabah resolution (SPEC 1.4 langkah 5)
// ---------------------------------------------------------------------------

void _resolveAsabah(_Ctx ctx) {
  final residue = Fraction.one - ctx.assignedSum;

  // Jadd wal-ikhwah.
  if (ctx.hasGrandfather &&
      !ctx.hasFather &&
      (ctx.has(HeirType.fullBrother) ||
          ctx.has(HeirType.fullSister) ||
          ctx.has(HeirType.paternalBrother) ||
          ctx.has(HeirType.paternalSister))) {
    _resolveJaddWalIkhwah(ctx, residue);
    return;
  }

  if (residue.isZero || residue.isNegative) {
    ctx.trace.add('asabah', 'Tiada baki untuk asabah (jumlah fardu = '
        '${ctx.assignedSum}).');
    return;
  }

  // Anak lelaki + anak perempuan (asabah bi-ghayrihi).
  if (ctx.has(HeirType.son)) {
    _splitTwoOne(ctx, residue, HeirType.son, HeirType.daughter,
        R.sonAsabah, R.daughterAsabahBiGhayrihi);
    return;
  }
  // Cucu lelaki + cucu perempuan.
  if (ctx.has(HeirType.sonsSon)) {
    _splitTwoOne(ctx, residue, HeirType.sonsSon, HeirType.sonsDaughter,
        R.asabahBiNafsihi, R.sonsDaughterAsabahBiGhayrihi);
    return;
  }
  // Bapa asabah.
  if (ctx.hasFather) {
    _addAsabahResidue(ctx, HeirType.father, residue,
        ctx.assigned.containsKey(HeirType.father)
            ? R.fatherSixthPlusAsabah
            : R.fatherAsabah);
    return;
  }
  // Datuk asabah (tiada adik-beradik).
  if (ctx.hasGrandfather) {
    _addAsabahResidue(ctx, HeirType.paternalGrandfather, residue,
        ctx.assigned.containsKey(HeirType.paternalGrandfather)
            ? R.grandfatherSixthPlusAsabah
            : R.grandfatherAsabah);
    return;
  }
  // Saudara perempuan s.i.s / sebapa sebagai asabah ma'a-ghayrihi
  // (bersama anak/cucu perempuan).
  final femaleDesc =
      ctx.has(HeirType.daughter) || ctx.has(HeirType.sonsDaughter);
  if (femaleDesc && ctx.has(HeirType.fullSister)) {
    _addAsabahResidue(ctx, HeirType.fullSister, residue,
        R.fullSisterAsabahMaaGhayrihi);
    ctx.trace.add('asabah', 'Saudara perempuan s.i.s menjadi asabah ma\'a-'
        'ghayrihi bersama keturunan perempuan; mengambil baki $residue.',
        affected: [HeirType.fullSister]);
    return;
  }
  if (femaleDesc && ctx.has(HeirType.paternalSister)) {
    _addAsabahResidue(ctx, HeirType.paternalSister, residue,
        R.paternalSisterAsabahMaaGhayrihi);
    return;
  }
  // Saudara s.i.s (lelaki +/- perempuan).
  if (ctx.has(HeirType.fullBrother)) {
    _splitTwoOne(ctx, residue, HeirType.fullBrother, HeirType.fullSister,
        R.asabahBiNafsihi, R.fullSisterAsabahBiGhayrihi);
    return;
  }
  if (ctx.has(HeirType.paternalBrother)) {
    _splitTwoOne(ctx, residue, HeirType.paternalBrother,
        HeirType.paternalSister, R.asabahBiNafsihi,
        R.paternalSisterAsabahBiGhayrihi);
    return;
  }
  // Rantaian asabah jauh.
  for (final t in const [
    HeirType.fullBrothersSon,
    HeirType.paternalBrothersSon,
    HeirType.fullPaternalUncle,
    HeirType.paternalUncle,
    HeirType.fullPaternalUnclesSon,
    HeirType.paternalUnclesSon,
  ]) {
    if (ctx.has(t)) {
      _addAsabahResidue(ctx, t, residue, R.asabahBiNafsihi);
      return;
    }
  }

  ctx.trace.add('asabah', 'Tiada asabah — baki $residue akan di-radd atau '
      'diserahkan kepada Baitulmal.');
}

void _splitTwoOne(
  _Ctx ctx,
  Fraction residue,
  HeirType male,
  HeirType female,
  String maleReason,
  String femaleReason,
) {
  final nM = ctx.count(male);
  final nF = ctx.count(female);
  final parts = 2 * nM + nF;
  if (parts == 0) return;
  final maleShare = residue * Fraction(2 * nM, parts);
  ctx.assign(male, maleShare, ShareBasis.asabah, maleReason);
  ctx.trace.add('asabah', '$male mengambil baki secara asabah '
      '(lelaki 2 : perempuan 1).', affected: [male], fraction: maleShare);
  if (nF > 0) {
    final femaleShare = residue * Fraction(nF, parts);
    ctx.assign(female, femaleShare, ShareBasis.asabah, femaleReason);
    ctx.trace.add('asabah', '$female menjadi asabah bi-ghayrihi bersama $male.',
        affected: [female], fraction: femaleShare);
  }
}

void _addAsabahResidue(
    _Ctx ctx, HeirType t, Fraction residue, String reason) {
  final existing = ctx.assigned[t];
  if (existing != null) {
    existing.shareTotal += residue;
    existing.basis = ShareBasis.asabah;
    existing.reasonCode = reason;
  } else {
    ctx.assign(t, residue, ShareBasis.asabah, reason);
  }
  ctx.trace.add('asabah', '$t mengambil baki $residue sebagai asabah.',
      affected: [t], fraction: residue);
}

void _resolveJaddWalIkhwah(_Ctx ctx, Fraction residueAfterOthers) {
  // Selepas furud lain (pasangan, ibu, anak perempuan) diambil.
  final residue = residueAfterOthers;
  if (residue.isZero || residue.isNegative) {
    ctx.trace.add('special', 'Jadd wal-ikhwah: tiada baki selepas fardu lain.');
    return;
  }

  // Kumpulan saudara: gabungkan s.i.s + sebapa untuk kiraan muqasamah (mu'adda),
  // kecuali jika hanya sebapa. Untuk MVP kita sokong: (a) hanya s.i.s, atau
  // (b) hanya sebapa. Campuran s.i.s + sebapa dengan mu'adda penuh dibendera.
  final fullB = ctx.count(HeirType.fullBrother);
  final fullS = ctx.count(HeirType.fullSister);
  final patB = ctx.count(HeirType.paternalBrother);
  final patS = ctx.count(HeirType.paternalSister);
  final hasFull = fullB > 0 || fullS > 0;
  final hasPat = patB > 0 || patS > 0;

  HeirType brotherKey;
  HeirType sisterKey;
  int nB;
  int nS;
  if (hasFull && hasPat) {
    ctx.manualReview = true;
    ctx.warnings.add(const Warning(WarningLevel.caution, 'jadd_muadda',
        'Datuk bersama campuran saudara s.i.s dan sebapa (mu\'adda) — di luar '
        'skop MVP, perlu semakan manual.'));
    ctx.trace.add('special', 'Jadd wal-ikhwah dengan mu\'adda dibendera.');
    brotherKey = HeirType.fullBrother;
    sisterKey = HeirType.fullSister;
    nB = fullB;
    nS = fullS;
  } else if (hasFull) {
    brotherKey = HeirType.fullBrother;
    sisterKey = HeirType.fullSister;
    nB = fullB;
    nS = fullS;
  } else {
    brotherKey = HeirType.paternalBrother;
    sisterKey = HeirType.paternalSister;
    nB = patB;
    nS = patS;
  }

  final hasOtherFurud = ctx.assigned.keys.any((t) =>
      t != HeirType.paternalGrandfather &&
      t != brotherKey &&
      t != sisterKey);

  // Tiga pilihan datuk:
  // (a) 1/3 daripada baki
  final optThirdRemainder = residue * Fraction(1, 3);
  // (b) muqasamah — datuk sebagai seorang lelaki
  final sibParts = 2 * nB + nS;
  final grandAsBrotherParts = 2;
  final totalParts = grandAsBrotherParts + sibParts;
  final optMuqasama = residue * Fraction(grandAsBrotherParts, totalParts);
  // (c) 1/6 daripada harta (hanya bermakna bila ada furud lain)
  final optSixthEstate = Fraction(1, 6);

  Fraction grandShare;
  String note;
  if (hasOtherFurud) {
    grandShare = _maxFraction([optThirdRemainder, optMuqasama, optSixthEstate]);
    note = 'Terbaik antara 1/3 baki, muqasamah, 1/6 harta';
  } else {
    grandShare = _maxFraction([optThirdRemainder, optMuqasama]);
    note = 'Terbaik antara 1/3 harta dan muqasamah';
  }

  // Jika jaminan 1/6 datuk melebihi baki, masalah perlu di-aul — di luar skop
  // MVP; bendera dan hadkan bahagian datuk kepada baki.
  if (grandShare > residue) {
    ctx.manualReview = true;
    ctx.warnings.add(const Warning(WarningLevel.caution, 'jadd_aul',
        'Jaminan 1/6 datuk melebihi baki (jadd wal-ikhwah dengan aul) — di '
        'luar skop MVP; angka adalah anggaran.'));
    grandShare = residue;
  }

  ctx.assign(HeirType.paternalGrandfather, grandShare, ShareBasis.asabah,
      R.grandfatherBestOfThree, note: note);
  ctx.trace.add('special', 'Datuk mengambil $grandShare ($note).',
      affected: [HeirType.paternalGrandfather], fraction: grandShare);

  final sibResidue = residue - grandShare;
  if (sibParts == 0) return;
  if (nB > 0) {
    final bShare = sibResidue * Fraction(2 * nB, sibParts);
    ctx.assign(brotherKey, bShare, ShareBasis.asabah, R.asabahBiNafsihi);
    if (nS > 0) {
      final sShare = sibResidue * Fraction(nS, sibParts);
      ctx.assign(sisterKey, sShare, ShareBasis.asabah,
          R.fullSisterAsabahBiGhayrihi);
    }
  } else if (nS > 0) {
    // Saudara perempuan sahaja bersama datuk (tanpa akdariyyah): kaedah penuh
    // melibatkan had fardu s/p dan pemulangan lebihan kepada datuk. MVP
    // membendera dan memberi anggaran muqasamah.
    ctx.manualReview = true;
    ctx.warnings.add(const Warning(WarningLevel.caution, 'jadd_sisters_only',
        'Datuk bersama saudara perempuan sahaja — kaedah penuh di luar skop '
        'MVP; angka adalah anggaran.'));
    ctx.assign(sisterKey, sibResidue, ShareBasis.asabah,
        R.fullSisterAsabahBiGhayrihi,
        note: 'Baki selepas bahagian datuk (anggaran)');
  }
}

// ---------------------------------------------------------------------------
// 6. Aul / Radd (SPEC 1.4 langkah 6)
// ---------------------------------------------------------------------------

void _aulOrRadd(_Ctx ctx) {
  final total = ctx.assignedSum;
  if (total == Fraction.one) return;

  if (total > Fraction.one) {
    // Aul — kecilkan setiap bahagian secara berkadar.
    for (final a in ctx.assigned.values) {
      a.shareTotal = a.shareTotal / total;
      if (a.basis == ShareBasis.fardu) a.basis = ShareBasis.aul;
    }
    ctx.trace.add('aul', 'Jumlah fardu $total melebihi 1 — asal masalah '
        'di-aul; setiap bahagian dikecilkan berkadar.', reasonCode: R.aul);
    return;
  }

  // total < 1 — Radd atau asabah tiada.
  final residue = Fraction.one - total;
  final nonSpouse = ctx.assigned.entries
      .where((e) => e.key != HeirType.husband && e.key != HeirType.wife)
      .toList();
  if (nonSpouse.isEmpty) {
    // Hanya pasangan — baki kepada Baitulmal (MVP: tidak radd kepada pasangan).
    ctx.warnings.add(Warning(WarningLevel.info, 'baitulmal',
        'Baki $residue tiada waris selain pasangan — diserahkan kepada '
        'Baitulmal.'));
    ctx.trace.add('radd', 'Baki $residue kepada Baitulmal (pasangan tidak '
        'menerima radd).', reasonCode: R.baitulmal);
    return;
  }
  var base = Fraction.zero;
  for (final e in nonSpouse) {
    base += e.value.shareTotal;
  }
  for (final e in nonSpouse) {
    final extra = residue * (e.value.shareTotal / base);
    e.value.shareTotal += extra;
    if (e.value.basis == ShareBasis.fardu) e.value.basis = ShareBasis.radd;
  }
  ctx.trace.add('radd', 'Jumlah fardu $total kurang daripada 1 dan tiada '
      'asabah — baki $residue di-radd kepada waris fardu bukan pasangan '
      'mengikut nisbah.', reasonCode: R.radd);
}

// ---------------------------------------------------------------------------
// 7 & 9. Tashih + agihan wang
// ---------------------------------------------------------------------------

void _tashihAndMoney(_Ctx ctx) {
  // Tashih dikira dalam _Ctx.build() (LCM penyebut shareEach). Di sini hanya
  // rekod jejak jika perlu.
  final amEach = _lcmOfDenominators(ctx.assigned.entries.map((e) {
    final a = e.value;
    return a.count <= 1 ? a.shareTotal : a.shareTotal / Fraction(a.count);
  }));
  final amTotal = _lcmOfDenominators(ctx.assigned.values.map((a) => a.shareTotal));
  if (amEach != amTotal) {
    ctx.trace.add('tashih', 'Asal masalah $amTotal dinaikkan kepada $amEach '
        'supaya setiap bahagian individu menjadi integer.',
        reasonCode: R.tashih);
  }
}

// ---------------------------------------------------------------------------
// 10. Validate totals
// ---------------------------------------------------------------------------

void _validateTotals(_Ctx ctx) {
  final total = ctx.assignedSum;
  if (total == Fraction.one) {
    ctx.trace.add('validate', 'Jumlah semua bahagian = 1. Sah.');
    return;
  }
  if (total < Fraction.one) {
    ctx.trace.add('validate', 'Jumlah bahagian $total < 1 — baki kepada '
        'Baitulmal (lihat amaran).');
    return;
  }
  // total > 1 tidak sepatutnya berlaku selepas aul.
  ctx.manualReview = true;
  ctx.warnings.add(Warning(WarningLevel.blocking, 'sum_gt_1',
      'Ralat dalaman: jumlah bahagian $total > 1 selepas pelarasan.'));
  ctx.trace.add('validate', 'AMARAN: jumlah $total > 1.');
}

// ---------------------------------------------------------------------------
// Utiliti
// ---------------------------------------------------------------------------

int _lcmOfDenominators(Iterable<Fraction> fractions) {
  var l = BigInt.one;
  for (final f in fractions) {
    l = Fraction.lcm(l, f.denominator);
  }
  return l.toInt();
}

Fraction _maxFraction(List<Fraction> xs) {
  var m = xs.first;
  for (final x in xs.skip(1)) {
    if (x > m) m = x;
  }
  return m;
}
