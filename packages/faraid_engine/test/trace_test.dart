// ignore_for_file: prefer_const_constructors
import 'package:faraid_engine/faraid_engine.dart';
import 'package:test/test.dart';

void main() {
  const engine = FaraidEngine();

  test('trace direkod untuk setiap pengiraan (SPEC 1.7)', () {
    final r = engine.calculate(FaraidInput(
      deceasedGender: Gender.female,
      netEstate: Money.ringgit(240000),
      claims: [
        HeirClaim(HeirType.husband),
        HeirClaim(HeirType.son),
        HeirClaim(HeirType.daughter),
        HeirClaim(HeirType.fullBrother),
      ],
    ));
    expect(r.trace.steps, isNotEmpty);
    final phases = r.trace.steps.map((s) => s.phase).toSet();
    expect(phases, containsAll(<String>['validation', 'hajb', 'furud', 'asabah']));
    // Saudara lelaki terdinding oleh anak lelaki — mesti ada dalam trace + blocked.
    expect(r.blocked.any((b) => b.type == HeirType.fullBrother), isTrue);
    expect(
        r.trace.steps.any((s) =>
            s.phase == 'hajb' && s.affected.contains(HeirType.fullBrother)),
        isTrue);
    // Setiap langkah boleh di-serialize untuk butang "Kenapa?".
    expect(r.trace.toJson(), isA<List<Map<String, Object?>>>());
  });

  test('keadaan di luar skop dibendera, bukan diteka (SPEC 1.5)', () {
    // Musyarakah / himariyyah.
    final r = engine.calculate(FaraidInput(
      deceasedGender: Gender.female,
      claims: [
        HeirClaim(HeirType.husband),
        HeirClaim(HeirType.mother),
        HeirClaim(HeirType.maternalSibling, count: 2),
        HeirClaim(HeirType.fullBrother, count: 1),
      ],
    ));
    expect(r.status, ResultStatus.requiresManualReview);
    expect(r.warnings.any((w) => w.code == 'musharakah'), isTrue);
  });

  test('tiada double dalam laluan pengiraan — pecahan kekal tepat', () {
    final r = engine.calculate(FaraidInput(
      deceasedGender: Gender.male,
      netEstate: Money.ringgit(100000),
      claims: [
        HeirClaim(HeirType.wife),
        HeirClaim(HeirType.son, count: 3),
        HeirClaim(HeirType.daughter, count: 2),
      ],
    ));
    // 7/8 dibahagi 8 bahagian -> penyebut 64, mesti tepat.
    final son = r.shares.firstWhere((s) => s.type == HeirType.son);
    expect(son.shareEach, Fraction(7, 32));
    var total = Money.zero;
    for (final s in r.shares) {
      total += s.amountTotal!;
    }
    expect(total, Money.ringgit(100000));
  });
}
