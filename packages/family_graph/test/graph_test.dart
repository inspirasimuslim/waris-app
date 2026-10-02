import 'package:family_graph/family_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Person — status hidup lalai (SPEC 3.2)', () {
    test('orang baharu secara lalai adalah alive', () {
      final p = Person(id: 'p1', familyId: 'F1', name: 'Ali', gender: Gender.male);
      expect(p.status, LifeStatus.alive);
    });

    test('boleh dicipta terus sebagai deceased dengan tarikh kematian', () {
      final p = Person(
        id: 'p1',
        familyId: 'F1',
        name: 'Ali',
        gender: Gender.male,
        status: LifeStatus.deceased,
        deathDate: DateTime(2020, 1, 1),
      );
      expect(p.status, LifeStatus.deceased);
      expect(p.deathDate, DateTime(2020, 1, 1));
    });

    test('copyWith boleh tukar alive -> deceased', () {
      final alive = Person(id: 'p1', familyId: 'F1', name: 'Ali', gender: Gender.male);
      final dead = alive.copyWith(
          status: LifeStatus.deceased, deathDate: DateTime(2021, 6, 1));
      expect(dead.status, LifeStatus.deceased);
      expect(alive.status, LifeStatus.alive); // asal tidak berubah
    });
  });

  group('ParentLink — anak boleh ada satu ibu bapa sahaja (SPEC 2.2)', () {
    late FamilyGraph g;

    setUp(() {
      g = FamilyGraph(familyId: 'F1', persons: [
        Person(id: 'anak', familyId: 'F1', name: 'Anak', gender: Gender.male),
        Person(id: 'ibu', familyId: 'F1', name: 'Ibu', gender: Gender.female),
        Person(id: 'bapa', familyId: 'F1', name: 'Bapa', gender: Gender.male),
      ]);
    });

    test('anak boleh direkod dengan ibu sahaja, tanpa bapa', () {
      g.addParentLink(ParentLink(
        id: 'pl1',
        childId: 'anak',
        parentId: 'ibu',
        role: ParentRole.mother,
      ));

      expect(g.parentLink('anak', ParentRole.mother)?.parentId, 'ibu');
      expect(g.parentLink('anak', ParentRole.father), isNull);
    });

    test('anak boleh direkod dengan bapa sahaja, tanpa ibu', () {
      g.addParentLink(ParentLink(
        id: 'pl1',
        childId: 'anak',
        parentId: 'bapa',
        role: ParentRole.father,
      ));

      expect(g.parentLink('anak', ParentRole.father)?.parentId, 'bapa');
      expect(g.parentLink('anak', ParentRole.mother), isNull);
    });

    test('anak boleh ditambah bapa kemudian selepas ibu sahaja wujud', () {
      g.addParentLink(ParentLink(
        id: 'pl1',
        childId: 'anak',
        parentId: 'ibu',
        role: ParentRole.mother,
      ));
      g.addParentLink(ParentLink(
        id: 'pl2',
        childId: 'anak',
        parentId: 'bapa',
        role: ParentRole.father,
      ));

      expect(g.parentLink('anak', ParentRole.mother)?.parentId, 'ibu');
      expect(g.parentLink('anak', ParentRole.father)?.parentId, 'bapa');
    });
  });

  group('SpouseLink — had poligami: maksimum 4 isteri serentak (D-027)', () {
    late FamilyGraph g;

    setUp(() {
      g = FamilyGraph(familyId: 'F1', persons: [
        Person(id: 'suami', familyId: 'F1', name: 'Suami', gender: Gender.male),
        for (var i = 1; i <= 5; i++)
          Person(
              id: 'isteri$i', familyId: 'F1', name: 'Isteri$i', gender: Gender.female),
      ]);
    });

    test('lulus untuk isteri ke-1 hingga ke-4', () {
      for (var i = 1; i <= 4; i++) {
        expect(
          () => g.addSpouseLink(SpouseLink(
            id: 'sl$i',
            personAId: 'suami',
            personBId: 'isteri$i',
            status: MarriageStatus.married,
            order: i,
          )),
          returnsNormally,
          reason: 'isteri ke-$i patut diterima',
        );
      }
      expect(g.spouseLinksOf('suami').length, 4);
    });

    test('ditolak untuk isteri ke-5 berstatus married', () {
      for (var i = 1; i <= 4; i++) {
        g.addSpouseLink(SpouseLink(
          id: 'sl$i',
          personAId: 'suami',
          personBId: 'isteri$i',
          status: MarriageStatus.married,
          order: i,
        ));
      }

      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl5',
          personAId: 'suami',
          personBId: 'isteri5',
          status: MarriageStatus.married,
          order: 5,
        )),
        throwsArgumentError,
      );
      expect(g.spouseLinksOf('suami').length, 4);
    });

    test('isteri ke-5 DITERIMA jika salah satu isteri sebelumnya divorced',
        () {
      for (var i = 1; i <= 4; i++) {
        g.addSpouseLink(SpouseLink(
          id: 'sl$i',
          personAId: 'suami',
          personBId: 'isteri$i',
          status: i == 2 ? MarriageStatus.divorced : MarriageStatus.married,
          order: i,
        ));
      }
      // Hanya 3 married (isteri1, isteri3, isteri4); isteri2 divorced.
      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl5',
          personAId: 'suami',
          personBId: 'isteri5',
          status: MarriageStatus.married,
          order: 5,
        )),
        returnsNormally,
      );
    });

    test('isteri ke-5 DITERIMA jika salah satu isteri sebelumnya widowed',
        () {
      for (var i = 1; i <= 4; i++) {
        g.addSpouseLink(SpouseLink(
          id: 'sl$i',
          personAId: 'suami',
          personBId: 'isteri$i',
          status: i == 3 ? MarriageStatus.widowed : MarriageStatus.married,
          order: i,
        ));
      }
      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl5',
          personAId: 'suami',
          personBId: 'isteri5',
          status: MarriageStatus.married,
          order: 5,
        )),
        returnsNormally,
      );
    });
  });

  group('SpouseLink — seorang perempuan maksimum 1 suami married (D-027)', () {
    late FamilyGraph g;

    setUp(() {
      g = FamilyGraph(familyId: 'F1', persons: [
        Person(id: 'isteri', familyId: 'F1', name: 'Isteri', gender: Gender.female),
        Person(id: 'suami1', familyId: 'F1', name: 'Suami1', gender: Gender.male),
        Person(id: 'suami2', familyId: 'F1', name: 'Suami2', gender: Gender.male),
      ]);
    });

    test('lulus untuk suami pertama', () {
      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl1',
          personAId: 'isteri',
          personBId: 'suami1',
          status: MarriageStatus.married,
        )),
        returnsNormally,
      );
    });

    test('ditolak untuk suami kedua semasa suami pertama masih married', () {
      g.addSpouseLink(SpouseLink(
        id: 'sl1',
        personAId: 'isteri',
        personBId: 'suami1',
        status: MarriageStatus.married,
      ));

      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl2',
          personAId: 'isteri',
          personBId: 'suami2',
          status: MarriageStatus.married,
        )),
        throwsArgumentError,
      );
      expect(g.spouseLinksOf('isteri').length, 1);
    });

    test('diterima untuk suami kedua selepas suami pertama divorced', () {
      g.addSpouseLink(SpouseLink(
        id: 'sl1',
        personAId: 'isteri',
        personBId: 'suami1',
        status: MarriageStatus.divorced,
      ));

      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl2',
          personAId: 'isteri',
          personBId: 'suami2',
          status: MarriageStatus.married,
        )),
        returnsNormally,
      );
    });

    test('diterima untuk suami kedua selepas suami pertama widowed', () {
      g.addSpouseLink(SpouseLink(
        id: 'sl1',
        personAId: 'isteri',
        personBId: 'suami1',
        status: MarriageStatus.widowed,
      ));

      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl2',
          personAId: 'isteri',
          personBId: 'suami2',
          status: MarriageStatus.married,
        )),
        returnsNormally,
      );
    });
  });

  group('SpouseLink — pertalian ke orang tidak wujud ditolak', () {
    test('throws StateError bila personId tidak wujud dalam graf', () {
      final g = FamilyGraph(familyId: 'F1', persons: [
        Person(id: 'a', familyId: 'F1', name: 'A', gender: Gender.male),
      ]);
      expect(
        () => g.addSpouseLink(SpouseLink(
          id: 'sl1',
          personAId: 'a',
          personBId: 'tiada-wujud',
          status: MarriageStatus.married,
        )),
        throwsStateError,
      );
    });
  });
}
