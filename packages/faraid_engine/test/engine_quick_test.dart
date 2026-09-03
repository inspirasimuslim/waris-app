// ignore_for_file: prefer_const_constructors, unnecessary_parenthesis
import 'package:faraid_engine/faraid_engine.dart';
import 'package:test/test.dart';

const engine = FaraidEngine();

FaraidResult run(Gender g, List<HeirClaim> claims, {num? estate}) => engine.calculate(
      FaraidInput(
        deceasedGender: g,
        netEstate: estate == null ? null : Money.ringgit(estate),
        claims: claims,
      ),
    );

Fraction share(FaraidResult r, HeirType t) =>
    r.shares.firstWhere((s) => s.type == t).shareTotal;

void main() {
  test('Fraction aritmetik tepat', () {
    expect(Fraction(1, 2) + Fraction(1, 3), Fraction(5, 6));
    expect(Fraction(2, 4), Fraction(1, 2));
    expect(Fraction(1, 8) * Fraction(1, 1), Fraction(1, 8));
    expect(Fraction.parse('7/30').toString(), '7/30');
    expect((Fraction(1, 3) + Fraction(1, 3) + Fraction(1, 3)), Fraction.one);
  });

  test('Money split tepat tanpa kehilangan sen', () {
    final parts = Money.ringgit(740000.03).splitBy(
        [Fraction(1, 8), Fraction(3, 8), Fraction(1, 3), Fraction(1, 6)]);
    final sum = parts.reduce((a, b) => a + b);
    expect(sum, Money.ringgit(740000.03));
  });

  test('C1 suami + anak lelaki + anak perempuan', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.son),
      HeirClaim(HeirType.daughter),
    ]);
    expect(r.status, ResultStatus.ok);
    expect(share(r, HeirType.husband), Fraction(1, 4));
    expect(share(r, HeirType.son), Fraction(1, 2));
    expect(share(r, HeirType.daughter), Fraction(1, 4));
    expect(r.totalShare, Fraction.one);
  });

  test('C2 isteri + 2 anak lelaki + 3 anak perempuan + ibu', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.wife),
      HeirClaim(HeirType.son, count: 2),
      HeirClaim(HeirType.daughter, count: 3),
      HeirClaim(HeirType.mother),
    ]);
    expect(share(r, HeirType.wife), Fraction(1, 8));
    expect(share(r, HeirType.mother), Fraction(1, 6));
    // baki 1 - 1/8 - 1/6 = 17/24 dibahagi 2:1 -> 7 bahagian (4 lelaki, 3 perempuan)
    expect(share(r, HeirType.son) + share(r, HeirType.daughter), Fraction(17, 24));
    expect(r.totalShare, Fraction.one);
  });

  test('C3 Umariyyatain suami + ibu + bapa (SPEC FRD-047)', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.father),
    ], estate: 120000);
    expect(share(r, HeirType.husband), Fraction(1, 2));
    expect(share(r, HeirType.mother), Fraction(1, 6));
    expect(share(r, HeirType.father), Fraction(1, 3));
    expect(r.asalMasalah, 6);
    expect(r.shares.firstWhere((s) => s.type == HeirType.husband).amountTotal,
        Money.ringgit(60000));
    expect(r.shares.firstWhere((s) => s.type == HeirType.mother).amountTotal,
        Money.ringgit(20000));
    expect(r.shares.firstWhere((s) => s.type == HeirType.father).amountTotal,
        Money.ringgit(40000));
  });

  test('C4 Umariyyatain isteri + ibu + bapa', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.wife),
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.father),
    ]);
    expect(share(r, HeirType.wife), Fraction(1, 4));
    expect(share(r, HeirType.mother), Fraction(1, 4));
    expect(share(r, HeirType.father), Fraction(1, 2));
  });

  test('C5 dua anak perempuan sahaja — radd', () {
    final r = run(Gender.male, [HeirClaim(HeirType.daughter, count: 2)]);
    expect(share(r, HeirType.daughter), Fraction.one);
    expect(r.shares.single.shareEach, Fraction(1, 2));
  });

  test('C6 suami + 2 anak perempuan — radd tidak sentuh suami', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.daughter, count: 2),
    ]);
    expect(share(r, HeirType.husband), Fraction(1, 4));
    expect(share(r, HeirType.daughter), Fraction(3, 4));
    expect(r.totalShare, Fraction.one);
  });

  test('C7 ibu + bapa sahaja', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.father),
    ]);
    expect(share(r, HeirType.mother), Fraction(1, 3));
    expect(share(r, HeirType.father), Fraction(2, 3));
  });

  test('C8 ibu + bapa + anak lelaki', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.father),
      HeirClaim(HeirType.son),
    ]);
    expect(share(r, HeirType.mother), Fraction(1, 6));
    expect(share(r, HeirType.father), Fraction(1, 6));
    expect(share(r, HeirType.son), Fraction(2, 3));
  });

  test('C9 suami + saudara perempuan s.i.s (kalalah)', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.fullSister),
    ]);
    expect(share(r, HeirType.husband), Fraction(1, 2));
    expect(share(r, HeirType.fullSister), Fraction(1, 2));
  });

  test('C10 suami + s/p s.i.s + s/p sebapa (aul 6->7)', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.fullSister),
      HeirClaim(HeirType.paternalSister),
    ]);
    expect(share(r, HeirType.husband), Fraction(3, 7));
    expect(share(r, HeirType.fullSister), Fraction(3, 7));
    expect(share(r, HeirType.paternalSister), Fraction(1, 7));
    expect(r.asalMasalah, 6);
  });

  test('C11 hajb: anak lelaki mendinding saudara', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.son),
      HeirClaim(HeirType.fullBrother),
      HeirClaim(HeirType.fullSister),
    ]);
    expect(r.blocked.any((b) => b.type == HeirType.fullBrother), isTrue);
    expect(share(r, HeirType.son), Fraction.one);
  });

  test('C12 ibu + 2 saudara seibu + saudara lelaki s.i.s', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.maternalSibling, count: 2),
      HeirClaim(HeirType.fullBrother),
    ]);
    expect(share(r, HeirType.mother), Fraction(1, 6));
    expect(share(r, HeirType.maternalSibling), Fraction(1, 3));
    expect(share(r, HeirType.fullBrother), Fraction(1, 2));
  });

  test('C13 Akdariyyah', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.paternalGrandfather),
      HeirClaim(HeirType.fullSister),
    ]);
    expect(share(r, HeirType.husband), Fraction(9, 27));
    expect(share(r, HeirType.mother), Fraction(6, 27));
    expect(share(r, HeirType.paternalGrandfather), Fraction(8, 27));
    expect(share(r, HeirType.fullSister), Fraction(4, 27));
    expect(r.totalShare, Fraction.one);
  });

  test('C14 isteri + ibu + 2 saudara lelaki s.i.s', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.wife),
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.fullBrother, count: 2),
    ]);
    expect(share(r, HeirType.wife), Fraction(1, 4));
    expect(share(r, HeirType.mother), Fraction(1, 6));
    expect(share(r, HeirType.fullBrother), Fraction(7, 12));
  });

  test('C15 datuk + 2 saudara lelaki s.i.s (muqasamah = 1/3)', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.paternalGrandfather),
      HeirClaim(HeirType.fullBrother, count: 2),
    ]);
    expect(share(r, HeirType.paternalGrandfather), Fraction(1, 3));
    expect(share(r, HeirType.fullBrother), Fraction(2, 3));
    expect(r.totalShare, Fraction.one);
  });

  test('C16 minbariyyah: suami + 2 anak perempuan + ibu + bapa (aul 12->15)', () {
    final r = run(Gender.female, [
      HeirClaim(HeirType.husband),
      HeirClaim(HeirType.daughter, count: 2),
      HeirClaim(HeirType.mother),
      HeirClaim(HeirType.father),
    ]);
    expect(share(r, HeirType.husband), Fraction(3, 15));
    expect(share(r, HeirType.daughter), Fraction(8, 15));
    expect(share(r, HeirType.mother), Fraction(2, 15));
    expect(share(r, HeirType.father), Fraction(2, 15));
    expect(r.totalShare, Fraction.one);
  });

  test('C17 nasab tidak sabit menapis anak', () {
    final r = run(Gender.male, [
      HeirClaim(HeirType.wife),
      HeirClaim(HeirType.son, nasabConfirmed: false),
      HeirClaim(HeirType.father),
      HeirClaim(HeirType.mother),
    ]);
    expect(r.blocked.any((b) => b.type == HeirType.son), isTrue);
    // Menjadi: isteri 1/4, ibu 1/3, bapa asabah  (tiada far' warith)
    expect(share(r, HeirType.wife), Fraction(1, 4));
    expect(share(r, HeirType.mother), Fraction(1, 4)); // umariyyatain? tidak — ada isteri+ibu+bapa sahaja selepas tapis -> ya umariyyatain
  });

  test('C18 input tidak sah — si mati lelaki ada suami', () {
    final r = run(Gender.male, [HeirClaim(HeirType.husband)]);
    expect(r.status, ResultStatus.invalidInput);
  });
}
