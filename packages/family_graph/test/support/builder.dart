import 'package:family_graph/family_graph.dart';

/// Pembina graf ringkas untuk ujian.
class FamilyBuilder {
  FamilyBuilder(this.familyId);
  final String familyId;
  final _persons = <Person>[];
  final _parents = <ParentLink>[];
  final _spouses = <SpouseLink>[];
  int _seq = 0;

  String person(
    String id, {
    Gender gender = Gender.male,
    LifeStatus status = LifeStatus.alive,
    DateTime? birth,
    DateTime? death,
    bool isSelf = false,
  }) {
    _persons.add(Person(
      id: id,
      familyId: familyId,
      name: id,
      gender: gender,
      status: status,
      birthDate: birth,
      deathDate: death,
      isSelf: isSelf,
    ));
    return id;
  }

  void parents(
    String childId, {
    String? father,
    String? mother,
    NasabStatus fatherNasab = NasabStatus.confirmed,
    NasabStatus motherNasab = NasabStatus.confirmed,
    LinkKind fatherKind = LinkKind.biological,
    LinkKind motherKind = LinkKind.biological,
  }) {
    if (father != null) {
      _parents.add(ParentLink(
        id: 'pl${_seq++}',
        childId: childId,
        parentId: father,
        role: ParentRole.father,
        nasabStatus: fatherNasab,
        kind: fatherKind,
      ));
    }
    if (mother != null) {
      _parents.add(ParentLink(
        id: 'pl${_seq++}',
        childId: childId,
        parentId: mother,
        role: ParentRole.mother,
        nasabStatus: motherNasab,
        kind: motherKind,
      ));
    }
  }

  void marry(
    String a,
    String b, {
    MarriageStatus status = MarriageStatus.married,
    int? order,
  }) {
    _spouses.add(SpouseLink(
      id: 'sl${_seq++}',
      personAId: a,
      personBId: b,
      status: status,
      order: order,
    ));
  }

  FamilyGraph build() => FamilyGraph(
        familyId: familyId,
        persons: _persons,
        parentLinks: _parents,
        spouseLinks: _spouses,
      );
}
