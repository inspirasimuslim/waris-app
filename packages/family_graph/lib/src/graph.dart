import 'enums.dart';
import 'models.dart';

/// Simpanan dalam-memori bagi graf keluarga: hanya hubungan LANGSUNG
/// (ParentLink, SpouseLink). Semua hubungan lain diterbitkan oleh
/// [RelationshipResolver] (SPEC 2.1).
class FamilyGraph {
  FamilyGraph({
    required this.familyId,
    Iterable<Person> persons = const [],
    Iterable<ParentLink> parentLinks = const [],
    Iterable<SpouseLink> spouseLinks = const [],
  }) {
    for (final p in persons) {
      _persons[p.id] = p;
    }
    _parentLinks.addAll(parentLinks);
    _spouseLinks.addAll(spouseLinks);
  }

  final String familyId;
  final Map<String, Person> _persons = {};
  final List<ParentLink> _parentLinks = [];
  final List<SpouseLink> _spouseLinks = [];

  Iterable<Person> get persons => _persons.values;
  Iterable<ParentLink> get parentLinks => _parentLinks;
  Iterable<SpouseLink> get spouseLinks => _spouseLinks;

  Person? person(String id) => _persons[id];
  Person requirePerson(String id) =>
      _persons[id] ?? (throw StateError('Orang tidak wujud: $id'));

  void addPerson(Person p) => _persons[p.id] = p;

  void addParentLink(ParentLink link) {
    if (!_persons.containsKey(link.childId) ||
        !_persons.containsKey(link.parentId)) {
      throw StateError('ParentLink merujuk orang yang tidak wujud.');
    }
    if (_wouldCreateCycle(link.childId, link.parentId)) {
      // SPEC 2.9: kitaran dalam graf mesti DIHALANG (bukan sekadar dibendera)
      // kerana ia menyebabkan resolver berulang tanpa henti.
      throw ArgumentError('Pertalian ini mencipta kitaran dalam graf keturunan '
          '(${link.parentId} sudah keturunan ${link.childId}).');
    }
    _parentLinks.add(link);
  }

  void addSpouseLink(SpouseLink link) {
    if (!_persons.containsKey(link.personAId) ||
        !_persons.containsKey(link.personBId)) {
      throw StateError('SpouseLink merujuk orang yang tidak wujud.');
    }
    _spouseLinks.add(link);
  }

  /// Adakah menambah [parentId] sebagai ibu bapa [childId] mencipta kitaran?
  bool _wouldCreateCycle(String childId, String parentId) {
    if (childId == parentId) return true;
    // Adakah childId sudah menjadi nenek moyang parentId?
    final seen = <String>{};
    final stack = <String>[parentId];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      if (cur == childId) return true;
      if (!seen.add(cur)) continue;
      for (final l in _parentLinks.where((l) => l.childId == cur)) {
        stack.add(l.parentId);
      }
    }
    return false;
  }

  ParentLink? parentLink(String childId, ParentRole role) {
    for (final l in _parentLinks) {
      if (l.childId == childId && l.role == role) return l;
    }
    return null;
  }

  List<ParentLink> childLinksOf(String parentId) =>
      _parentLinks.where((l) => l.parentId == parentId).toList();

  List<SpouseLink> spouseLinksOf(String personId) =>
      _spouseLinks.where((l) => l.involves(personId)).toList();

  // --- Serialisasi untuk snapshot immutable (SPEC 2.7) ---

  Map<String, Object?> toJson() => {
        'familyId': familyId,
        'persons': _persons.values.map((p) => p.toJson()).toList(),
        'parentLinks': _parentLinks.map((l) => l.toJson()).toList(),
        'spouseLinks': _spouseLinks.map((l) => l.toJson()).toList(),
      };

  static FamilyGraph fromJson(Map<String, Object?> j) => FamilyGraph(
        familyId: j['familyId']! as String,
        persons: (j['persons']! as List)
            .map((e) => Person.fromJson((e as Map).cast<String, Object?>())),
        parentLinks: (j['parentLinks']! as List).map(
            (e) => ParentLink.fromJson((e as Map).cast<String, Object?>())),
        spouseLinks: (j['spouseLinks']! as List).map(
            (e) => SpouseLink.fromJson((e as Map).cast<String, Object?>())),
      );

  /// Salinan mendalam yang tidak dipengaruhi perubahan kemudian pada asal
  /// (SPEC 2.7 — snapshot immutable).
  FamilyGraph deepCopy() => FamilyGraph.fromJson(toJson());
}
