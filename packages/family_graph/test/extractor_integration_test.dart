import 'package:faraid_engine/faraid_engine.dart';
import 'package:family_graph/family_graph.dart';
import 'package:test/test.dart';

import 'support/builder.dart';

const engine = FaraidEngine();
final simDate = DateTime(2026, 9, 3);

FaraidResult runSim(FamilyGraph g, String deceasedId, {num? estate}) {
  final snap = SimulationSnapshot.run(
    id: 's1',
    graph: g,
    deceasedId: deceasedId,
    simulationDate: simDate,
    netEstate: estate == null ? null : Money.ringgit(estate),
  );
  return snap.result;
}

HeirExtraction extract(FamilyGraph g, String deceasedId, {num? estate}) =>
    HeirExtractor(g).extractHeirs(
      deceasedId: deceasedId,
      simulationDate: simDate,
      netEstate: estate == null ? null : Money.ringgit(estate),
    );

Fraction sh(FaraidResult r, HeirType t) =>
    r.shares.firstWhere((s) => s.type == t).shareTotal;

void main() {
  group('extractHeirs -> jenis waris betul', () {
    test('pasangan, ibu bapa, anak, adik-beradik dikenal pasti', () {
      final b = FamilyBuilder('F')
        ..person('D', gender: Gender.male)
        ..person('W', gender: Gender.female)
        ..person('Ayah', gender: Gender.male)
        ..person('Ibu', gender: Gender.female)
        ..person('Anak1', gender: Gender.male)
        ..person('Anak2', gender: Gender.female)
        ..person('Abang', gender: Gender.male);
      b
        ..marry('D', 'W')
        ..parents('D', father: 'Ayah', mother: 'Ibu')
        ..parents('Abang', father: 'Ayah', mother: 'Ibu')
        ..parents('Anak1', father: 'D')
        ..parents('Anak2', father: 'D');
      final e = extract(b.build(), 'D');
      final types = e.input.claims.map((c) => c.type).toSet();
      expect(types, containsAll(<HeirType>[
        HeirType.wife,
        HeirType.father,
        HeirType.mother,
        HeirType.son,
        HeirType.daughter,
        HeirType.fullBrother,
      ]));
    });
  });

  group('integrasi graf -> extractor -> enjin', () {
    test('A: isteri + 2 anak lelaki + anak perempuan + ibu', () {
      final b = FamilyBuilder('A')
        ..person('D', gender: Gender.male)
        ..person('W', gender: Gender.female)
        ..person('Ibu', gender: Gender.female)
        ..person('S1', gender: Gender.male)
        ..person('S2', gender: Gender.male)
        ..person('Dtr', gender: Gender.female);
      b
        ..marry('D', 'W')
        ..parents('D', mother: 'Ibu')
        ..parents('S1', father: 'D')
        ..parents('S2', father: 'D')
        ..parents('Dtr', father: 'D');
      final r = runSim(b.build(), 'D', estate: 240000);
      expect(r.status, ResultStatus.ok);
      expect(sh(r, HeirType.wife), Fraction(1, 8));
      expect(sh(r, HeirType.mother), Fraction(1, 6));
      expect(sh(r, HeirType.son) + sh(r, HeirType.daughter), Fraction(17, 24));
      expect(r.totalShare, Fraction.one);
    });

    test('B: Umariyyatain (suami + ibu + bapa) padan dengan FRD-106', () {
      final b = FamilyBuilder('B')
        ..person('D', gender: Gender.female)
        ..person('H', gender: Gender.male)
        ..person('Ayah', gender: Gender.male)
        ..person('Ibu', gender: Gender.female);
      b
        ..marry('D', 'H')
        ..parents('D', father: 'Ayah', mother: 'Ibu');
      final r = runSim(b.build(), 'D', estate: 120000);
      expect(sh(r, HeirType.husband), Fraction(1, 2));
      expect(sh(r, HeirType.mother), Fraction(1, 6));
      expect(sh(r, HeirType.father), Fraction(1, 3));
      Money? amt(HeirType t) =>
          r.shares.firstWhere((s) => s.type == t).amountTotal;
      expect(amt(HeirType.husband), Money.ringgit(60000));
      expect(amt(HeirType.mother), Money.ringgit(20000));
      expect(amt(HeirType.father), Money.ringgit(40000));
    });

    test('C: nasab tidak sabit menapis anak (padan FRD-121)', () {
      final b = FamilyBuilder('C')
        ..person('D', gender: Gender.male)
        ..person('W', gender: Gender.female)
        ..person('Ayah', gender: Gender.male)
        ..person('Ibu', gender: Gender.female)
        ..person('AnakRagu', gender: Gender.male);
      b
        ..marry('D', 'W')
        ..parents('D', father: 'Ayah', mother: 'Ibu')
        ..parents('AnakRagu', father: 'D', fatherNasab: NasabStatus.notEstablished);
      final g = b.build();
      final e = extract(g, 'D');
      expect(e.excluded.any((x) => x.person.id == 'AnakRagu'), isTrue);
      expect(e.input.claims.any((c) => c.type == HeirType.son), isFalse);
      final r = runSim(g, 'D', estate: 120000);
      // Menjadi umariyyatain: W 1/4, Ibu 1/4, Ayah 1/2.
      expect(sh(r, HeirType.wife), Fraction(1, 4));
      expect(sh(r, HeirType.mother), Fraction(1, 4));
      expect(sh(r, HeirType.father), Fraction(1, 2));
    });

    test('D: anak angkat tidak mewarisi (LinkKind.adoptive)', () {
      final b = FamilyBuilder('D')
        ..person('D', gender: Gender.male)
        ..person('Ibu', gender: Gender.female)
        ..person('AnakAngkat', gender: Gender.male);
      b
        ..parents('D', mother: 'Ibu')
        ..parents('AnakAngkat', father: 'D', fatherKind: LinkKind.adoptive);
      final e = extract(b.build(), 'D');
      expect(e.input.claims.any((c) => c.type == HeirType.son), isFalse);
      expect(e.excluded.any((x) => x.person.id == 'AnakAngkat'), isTrue);
    });

    test('E: cucu lelaki mewarisi apabila bapa mereka (anak si mati) meninggal',
        () {
      final b = FamilyBuilder('E')
        ..person('D', gender: Gender.male)
        ..person('W', gender: Gender.female)
        ..person('Dtr', gender: Gender.female)
        ..person('AnakMati', gender: Gender.male,
            status: LifeStatus.deceased, death: DateTime(2024))
        ..person('Cucu1', gender: Gender.male)
        ..person('Cucu2', gender: Gender.male);
      b
        ..marry('D', 'W')
        ..parents('Dtr', father: 'D')
        ..parents('AnakMati', father: 'D')
        ..parents('Cucu1', father: 'AnakMati')
        ..parents('Cucu2', father: 'AnakMati');
      final r = runSim(b.build(), 'D', estate: 800000);
      expect(sh(r, HeirType.wife), Fraction(1, 8));
      expect(sh(r, HeirType.daughter), Fraction(1, 2));
      expect(sh(r, HeirType.sonsSon), Fraction(3, 8));
      expect(r.totalShare, Fraction.one);
    });

    test('F: datuk sebelah bapa menggantikan bapa yang telah meninggal', () {
      final b = FamilyBuilder('F')
        ..person('D', gender: Gender.male)
        ..person('Ibu', gender: Gender.female)
        ..person('AyahMati', gender: Gender.male,
            status: LifeStatus.deceased, death: DateTime(2020))
        ..person('Datuk', gender: Gender.male)
        ..person('Anak', gender: Gender.male);
      b
        ..parents('D', father: 'AyahMati', mother: 'Ibu')
        ..parents('AyahMati', father: 'Datuk')
        ..parents('Anak', father: 'D');
      final r = runSim(b.build(), 'D', estate: 120000);
      expect(sh(r, HeirType.paternalGrandfather), Fraction(1, 6));
      expect(sh(r, HeirType.mother), Fraction(1, 6));
      expect(sh(r, HeirType.son), Fraction(2, 3));
      expect(r.shares.any((s) => s.type == HeirType.father), isFalse);
    });
  });

  group('snapshot immutable (SPEC 2.7)', () {
    test('menambah waris selepas simulasi TIDAK mengubah keputusan lama', () {
      final b = FamilyBuilder('S')
        ..person('D', gender: Gender.male)
        ..person('W', gender: Gender.female)
        ..person('S1', gender: Gender.male);
      b
        ..marry('D', 'W')
        ..parents('S1', father: 'D');
      final g = b.build();

      final snap = SimulationSnapshot.run(
        id: 'snap1',
        graph: g,
        deceasedId: 'D',
        simulationDate: simDate,
        netEstate: Money.ringgit(800000),
      );
      final wifeBefore = snap.result.shares
          .firstWhere((s) => s.type == HeirType.wife)
          .shareTotal;
      expect(wifeBefore, Fraction(1, 8));

      // Ubah graf ASAL: tambah dua anak lagi.
      g
        ..addPerson(Person(
            id: 'S2', familyId: 'S', name: 'S2', gender: Gender.male))
        ..addPerson(Person(
            id: 'S3', familyId: 'S', name: 'S3', gender: Gender.male))
        ..addParentLink(ParentLink(
            id: 'n1', childId: 'S2', parentId: 'D', role: ParentRole.father))
        ..addParentLink(ParentLink(
            id: 'n2', childId: 'S3', parentId: 'D', role: ParentRole.father));

      // Snapshot lama masih sama.
      expect(
          snap.result.shares
              .firstWhere((s) => s.type == HeirType.wife)
              .shareTotal,
          Fraction(1, 8));
      expect(snap.graph.persons.length, 3);

      // Simulasi baharu mengambil kira anak baharu (isteri kekal 1/8, tetapi
      // bilangan anak lelaki bertambah).
      final snap2 = SimulationSnapshot.run(
        id: 'snap2',
        graph: g,
        deceasedId: 'D',
        simulationDate: simDate,
        netEstate: Money.ringgit(800000),
      );
      expect(snap2.graph.persons.length, 5);
      expect(snap2.result.shares.firstWhere((s) => s.type == HeirType.son).count,
          3);
    });
  });

  group('nota panduan (SPEC 2.5 langkah 6)', () {
    test('status hidup tidak diketahui dibendera, bukan diteka', () {
      final b = FamilyBuilder('N')
        ..person('D', gender: Gender.male)
        ..person('Ibu', gender: Gender.female, status: LifeStatus.unknown)
        ..person('Anak', gender: Gender.male);
      b
        ..parents('D', mother: 'Ibu')
        ..parents('Anak', father: 'D');
      final e = extract(b.build(), 'D');
      expect(e.notes.any((n) => n.contains('tidak diketahui')), isTrue);
      expect(e.input.claims.any((c) => c.type == HeirType.mother), isFalse);
    });
  });
}
