import 'package:family_graph/family_graph.dart';
import 'package:test/test.dart';

import 'support/builder.dart';

/// Keluarga rujukan tiga generasi + cabang menyamping:
///
///        Kakek --- Nenek        MakLong --- (isteri MakLong)
///          |                          |
///     +----+----+                  Sepupu1
///     |         |
///   Ayah      PakSu            IbuKandung
///     |                             |
///     +-------------- Fokus --------+   (Fokus kahwin Pasangan)
///     |         |        |
///   Adik1    Adik2     TiriBapa (sebapa: ibu lain)
///     |
///   AnakAdik1
FamilyGraph refFamily() {
  final b = FamilyBuilder('F1')
    ..person('Kakek', gender: Gender.male)
    ..person('Nenek', gender: Gender.female)
    ..person('NenekIbu', gender: Gender.female)
    ..person('Ayah', gender: Gender.male)
    ..person('PakSu', gender: Gender.male)
    ..person('MakLong', gender: Gender.female)
    ..person('IbuKandung', gender: Gender.female)
    ..person('IbuTiriBapa', gender: Gender.female)
    ..person('Fokus', gender: Gender.male, isSelf: true)
    ..person('Pasangan', gender: Gender.female)
    ..person('Adik1', gender: Gender.male)
    ..person('Adik2', gender: Gender.female)
    ..person('TiriBapa', gender: Gender.male)
    ..person('AnakAdik1', gender: Gender.male)
    ..person('Sepupu1', gender: Gender.male)
    ..person('IsteriMakLong', gender: Gender.female);

  b
    ..parents('Ayah', father: 'Kakek', mother: 'Nenek')
    ..parents('PakSu', father: 'Kakek', mother: 'Nenek')
    ..parents('MakLong', father: 'Kakek', mother: 'Nenek')
    ..parents('IbuKandung', mother: 'NenekIbu')
    ..parents('Fokus', father: 'Ayah', mother: 'IbuKandung')
    ..parents('Adik1', father: 'Ayah', mother: 'IbuKandung')
    ..parents('Adik2', father: 'Ayah', mother: 'IbuKandung')
    ..parents('TiriBapa', father: 'Ayah', mother: 'IbuTiriBapa')
    ..parents('AnakAdik1', father: 'Adik1')
    ..parents('Sepupu1', father: 'MakLong', mother: 'IsteriMakLong')
    ..marry('Fokus', 'Pasangan')
    ..marry('MakLong', 'IsteriMakLong');

  return b.build();
}

void main() {
  final graph = refFamily();
  final r = RelationshipResolver(graph);

  group('parentOf / fathersOf', () {
    test('bapa langsung', () {
      expect(r.parentOf('Fokus', ParentRole.father)?.id, 'Ayah');
      expect(r.parentOf('Fokus', ParentRole.mother)?.id, 'IbuKandung');
    });
    test('datuk sebelah bapa (degree 2)', () {
      expect(r.fatherAtDegree('Fokus', 2)?.id, 'Kakek');
    });
    test('rantaian bapa penuh', () {
      expect(r.fathersOf('Fokus', degree: 3).map((p) => p.id), ['Ayah', 'Kakek']);
    });
    test('tiada bapa dikembalikan senarai kosong', () {
      expect(r.fathersOf('Kakek'), isEmpty);
    });
  });

  group('childrenOf', () {
    test('semua anak', () {
      expect(r.childrenOf('Ayah').map((p) => p.id).toSet(),
          {'Fokus', 'Adik1', 'Adik2', 'TiriBapa'});
    });
    test('tapis nasab confirmed sahaja', () {
      final g = (FamilyBuilder('F2')
            ..person('P')
            ..person('C1')
            ..person('C2')
            ..parents('C1', father: 'P')
            ..parents('C2', father: 'P', fatherNasab: NasabStatus.notEstablished))
          .build();
      final rr = RelationshipResolver(g);
      expect(rr.childrenOf('P', minStatus: NasabStatus.confirmed).map((p) => p.id),
          ['C1']);
      expect(rr.childrenOf('P').length, 2);
    });
  });

  group('siblingsOf', () {
    test('seibu-sebapa', () {
      expect(r.siblingsOf('Fokus', SiblingKind.full).map((p) => p.id).toSet(),
          {'Adik1', 'Adik2'});
    });
    test('sebapa (ibu berbeza)', () {
      expect(r.siblingsOf('Fokus', SiblingKind.paternal).map((p) => p.id),
          ['TiriBapa']);
    });
    test('seibu', () {
      expect(r.siblingsOf('Fokus', SiblingKind.maternal), isEmpty);
    });
    test('bukan adik-beradik kepada diri sendiri', () {
      expect(r.siblingsOf('Fokus', SiblingKind.full).any((p) => p.id == 'Fokus'),
          isFalse);
    });
  });

  group('ancestors & descendants', () {
    test('nenek moyang sebelah bapa', () {
      expect(r.ancestorsPaternal('Fokus').map((p) => p.id), ['Ayah', 'Kakek']);
    });
    test('keturunan lelaki', () {
      final g = (FamilyBuilder('F3')
            ..person('A')
            ..person('B')
            ..person('C')
            ..person('D', gender: Gender.female)
            ..parents('B', father: 'A')
            ..parents('C', father: 'B')
            ..parents('D', father: 'A'))
          .build();
      expect(RelationshipResolver(g).descendantsMale('A').map((p) => p.id).toSet(),
          {'B', 'C'});
    });
  });

  group('uncles / cousins / nephews', () {
    test('bapa saudara sebelah bapa', () {
      expect(
          r.unclesAunts('Fokus', paternalSide: true).map((p) => p.id).toSet(),
          {'PakSu', 'MakLong'});
    });
    test('anak saudara melalui saudara lelaki', () {
      expect(r.niblings('Fokus', SiblingKind.full).map((p) => p.id), ['AnakAdik1']);
    });
    test('sepupu sebelah bapa', () {
      expect(r.cousins('Fokus', paternalSide: true).map((p) => p.id), ['Sepupu1']);
    });
  });

  group('currentSpouses', () {
    test('pasangan berkahwin', () {
      expect(r.currentSpouses('Fokus').map((p) => p.id), ['Pasangan']);
    });
    test('cerai tidak dikira', () {
      final g = (FamilyBuilder('F4')
            ..person('X')
            ..person('Y', gender: Gender.female)
            ..marry('X', 'Y', status: MarriageStatus.divorced))
          .build();
      expect(RelationshipResolver(g).currentSpouses('X'), isEmpty);
    });
  });

  group('describe', () {
    test('bapa', () => expect(r.describe('Fokus', 'Ayah').code, 'father'));
    test('ibu', () => expect(r.describe('Fokus', 'IbuKandung').code, 'mother'));
    test('pasangan', () => expect(r.describe('Fokus', 'Pasangan').text, 'isteri'));
    test('anak', () => expect(r.describe('Ayah', 'Fokus').code, 'child'));
    test('saudara sebapa',
        () => expect(r.describe('Fokus', 'TiriBapa').text, contains('sebapa')));
    test('bapa saudara sebelah bapa',
        () => expect(r.describe('Fokus', 'PakSu').code, 'uncle_paternal'));
    test('sepupu', () => expect(r.describe('Fokus', 'Sepupu1').code, 'cousin'));
    test('diri sendiri', () => expect(r.describe('Fokus', 'Fokus').code, 'self'));
  });

  group('kitaran graf dihalang (SPEC 2.9)', () {
    test('A bapa kepada B, B bapa kepada A -> ArgumentError', () {
      final g = FamilyGraph(familyId: 'F5', persons: [
        Person(id: 'A', familyId: 'F5', name: 'A', gender: Gender.male),
        Person(id: 'B', familyId: 'F5', name: 'B', gender: Gender.male),
      ]);
      g.addParentLink(ParentLink(
          id: 'x', childId: 'B', parentId: 'A', role: ParentRole.father));
      expect(
          () => g.addParentLink(ParentLink(
              id: 'y', childId: 'A', parentId: 'B', role: ParentRole.father)),
          throwsArgumentError);
    });
    test('seseorang tidak boleh jadi bapa sendiri', () {
      final g = FamilyGraph(familyId: 'F6', persons: [
        Person(id: 'A', familyId: 'F6', name: 'A', gender: Gender.male),
      ]);
      expect(
          () => g.addParentLink(ParentLink(
              id: 'z', childId: 'A', parentId: 'A', role: ParentRole.father)),
          throwsArgumentError);
    });
  });

  group('isAliveOn', () {
    test('deceased sebelum tarikh simulasi', () {
      final p = Person(
        id: 'p',
        familyId: 'F',
        name: 'p',
        gender: Gender.male,
        status: LifeStatus.deceased,
        deathDate: DateTime(2020),
      );
      expect(p.isAliveOn(DateTime(2026)), isFalse);
      expect(p.isAliveOn(DateTime(2019)), isTrue);
    });
    test('unknown dianggap tidak hidup', () {
      final p = Person(
          id: 'p',
          familyId: 'F',
          name: 'p',
          gender: Gender.male,
          status: LifeStatus.unknown);
      expect(p.isAliveOn(DateTime(2026)), isFalse);
    });
  });

  group('pengesahan data (SPEC 2.9)', () {
    test('anak lebih tua daripada bapa dibendera', () {
      final g = (FamilyBuilder('F7')
            ..person('P', birth: DateTime(2000))
            ..person('C', birth: DateTime(1990))
            ..parents('C', father: 'P'))
          .build();
      final issues = validateGraph(g);
      expect(issues.any((i) => i.code == 'child_older_than_parent'), isTrue);
    });
    test('dua bapa berbeza dibendera', () {
      final g = FamilyGraph(familyId: 'F8', persons: [
        Person(id: 'C', familyId: 'F8', name: 'C', gender: Gender.male),
        Person(id: 'P1', familyId: 'F8', name: 'P1', gender: Gender.male),
        Person(id: 'P2', familyId: 'F8', name: 'P2', gender: Gender.male),
      ], parentLinks: [
        ParentLink(id: 'a', childId: 'C', parentId: 'P1', role: ParentRole.father),
        ParentLink(id: 'b', childId: 'C', parentId: 'P2', role: ParentRole.father),
      ]);
      expect(validateGraph(g).any((i) => i.code == 'conflicting_nasab'), isTrue);
    });
  });

  group('pengesanan pertindihan (SPEC 2.8)', () {
    test('cadang nama serupa, tidak gabung automatik', () {
      final g = (FamilyBuilder('F9')..person('Abdullah', gender: Gender.male))
          .build();
      final s = findDuplicates(g, name: 'Abdulah', gender: Gender.male);
      expect(s, isNotEmpty);
      expect(s.first.candidate.id, 'Abdullah');
    });
    test('jantina berbeza tidak dicadang', () {
      final g = (FamilyBuilder('F10')..person('Ali', gender: Gender.male)).build();
      expect(findDuplicates(g, name: 'Ali', gender: Gender.female), isEmpty);
    });
  });

  group('resolver — kes tepi tambahan', () {
    test('parentOf inheritingOnly menolak nasab tidak sabit', () {
      final g = (FamilyBuilder('E1')
            ..person('C')
            ..person('P')
            ..parents('C', father: 'P', fatherNasab: NasabStatus.disputed))
          .build();
      final rr = RelationshipResolver(g);
      expect(rr.parentOf('C', ParentRole.father)?.id, 'P');
      expect(rr.parentOf('C', ParentRole.father, inheritingOnly: true), isNull);
    });

    test('fathersOf berhenti bila rantaian putus', () {
      expect(r.fathersOf('Fokus', degree: 9).map((p) => p.id),
          ['Ayah', 'Kakek']);
    });

    test('fatherAtDegree pulangkan null bila tidak cukup peringkat', () {
      expect(r.fatherAtDegree('Fokus', 5), isNull);
    });

    test('siblingsOf inheritingOnly menolak adik-beradik nasab tidak sabit', () {
      final g = (FamilyBuilder('E2')
            ..person('A')
            ..person('B')
            ..person('Ayah')
            ..parents('A', father: 'Ayah')
            ..parents('B', father: 'Ayah', fatherNasab: NasabStatus.notEstablished))
          .build();
      final rr = RelationshipResolver(g);
      expect(rr.siblingsOf('A', SiblingKind.paternal).map((p) => p.id), ['B']);
      expect(
          rr.siblingsOf('A', SiblingKind.paternal, inheritingOnly: true), isEmpty);
    });

    test('adik-beradik seibu: ibu sama, bapa berbeza', () {
      final g = (FamilyBuilder('E3')
            ..person('A')
            ..person('B')
            ..person('Ibu', gender: Gender.female)
            ..person('Ayah1')
            ..person('Ayah2')
            ..parents('A', father: 'Ayah1', mother: 'Ibu')
            ..parents('B', father: 'Ayah2', mother: 'Ibu'))
          .build();
      final rr = RelationshipResolver(g);
      expect(rr.siblingsOf('A', SiblingKind.maternal).map((p) => p.id), ['B']);
      expect(rr.siblingsOf('A', SiblingKind.full), isEmpty);
      expect(rr.siblingsOf('A', SiblingKind.paternal), isEmpty);
    });

    test('descendantsMale hanya melalui anak lelaki, bukan anak perempuan', () {
      final g = (FamilyBuilder('E4')
            ..person('A')
            ..person('AnakP', gender: Gender.female)
            ..person('CucuLelakiViaAnakP')
            ..parents('AnakP', father: 'A')
            ..parents('CucuLelakiViaAnakP', mother: 'AnakP'))
          .build();
      expect(RelationshipResolver(g).descendantsMale('A'), isEmpty);
    });

    test('niblings kosong bila saudara tiada anak', () {
      expect(r.niblings('Fokus', SiblingKind.paternal), isEmpty);
    });

    test('unclesAunts sebelah ibu', () {
      final g = (FamilyBuilder('E5')
            ..person('D')
            ..person('Ibu', gender: Gender.female)
            ..person('NenekIbu', gender: Gender.female)
            ..person('PakCik')
            ..parents('D', mother: 'Ibu')
            ..parents('Ibu', mother: 'NenekIbu')
            ..parents('PakCik', mother: 'NenekIbu'))
          .build();
      expect(
          RelationshipResolver(g)
              .unclesAunts('D', paternalSide: false)
              .map((p) => p.id),
          ['PakCik']);
    });

    test('describe: datuk sebelah bapa', () {
      expect(r.describe('Fokus', 'Kakek').code, 'grandparent_paternal');
    });

    test('describe: orang tidak berkaitan -> relative/unknown', () {
      final g = (FamilyBuilder('E6')..person('X')..person('Y')).build();
      expect(RelationshipResolver(g).describe('X', 'Y').code,
          anyOf('relative', 'unknown'));
    });

    test('deepCopy graf bebas daripada asal', () {
      final g = refFamily();
      final copy = g.deepCopy();
      g.addPerson(
          Person(id: 'Baru', familyId: 'F1', name: 'Baru', gender: Gender.male));
      expect(copy.person('Baru'), isNull);
      expect(g.person('Baru'), isNotNull);
    });

    test('toJson/fromJson pusingan penuh', () {
      final g = refFamily();
      final round = FamilyGraph.fromJson(g.toJson());
      expect(round.persons.length, g.persons.length);
      expect(round.parentLinks.length, g.parentLinks.length);
      expect(round.spouseLinks.length, g.spouseLinks.length);
      expect(
          RelationshipResolver(round)
              .siblingsOf('Fokus', SiblingKind.full)
              .map((p) => p.id)
              .toSet(),
          {'Adik1', 'Adik2'});
    });

    test('childrenOf biologicalOnly menolak anak angkat', () {
      final g = (FamilyBuilder('E7')
            ..person('P')
            ..person('Kandung')
            ..person('Angkat')
            ..parents('Kandung', father: 'P')
            ..parents('Angkat', father: 'P', fatherKind: LinkKind.adoptive))
          .build();
      expect(
          RelationshipResolver(g)
              .childrenOf('P', biologicalOnly: true)
              .map((p) => p.id),
          ['Kandung']);
    });

    test('validateGraph: anak lahir >9 bulan selepas kematian bapa', () {
      final g = (FamilyBuilder('E8')
            ..person('Bapa',
                status: LifeStatus.deceased, death: DateTime(2020, 1, 1))
            ..person('Anak', birth: DateTime(2021, 6, 1))
            ..parents('Anak', father: 'Bapa'))
          .build();
      expect(validateGraph(g).any((i) => i.code == 'born_after_father_death'),
          isTrue);
    });

    test('validateGraph: umur perkahwinan tidak munasabah', () {
      final g = FamilyGraph(familyId: 'E9', persons: [
        Person(
            id: 'X',
            familyId: 'E9',
            name: 'X',
            gender: Gender.male,
            birthDate: DateTime(2015)),
        Person(
            id: 'Y',
            familyId: 'E9',
            name: 'Y',
            gender: Gender.female,
            birthDate: DateTime(2014)),
      ], spouseLinks: [
        SpouseLink(
            id: 's',
            personAId: 'X',
            personBId: 'Y',
            status: MarriageStatus.married,
            marriageDate: DateTime(2025)),
      ]);
      expect(validateGraph(g).any((i) => i.code == 'implausible_marriage_age'),
          isTrue);
    });

    test('NasabStatus.inheritsByNasab hanya benar untuk confirmed', () {
      expect(NasabStatus.confirmed.inheritsByNasab, isTrue);
      for (final s in NasabStatus.values.where((s) => s != NasabStatus.confirmed)) {
        expect(s.inheritsByNasab, isFalse);
      }
    });

    test('schema SQL mengandungi semua jadual teras', () {
      for (final t in ['persons', 'parent_links', 'spouse_links', 'simulations']) {
        expect(familyGraphSchemaSql, contains('CREATE TABLE $t'));
      }
      expect(familyGraphSchemaSql, contains('deleted_at'));
    });
  });
}
