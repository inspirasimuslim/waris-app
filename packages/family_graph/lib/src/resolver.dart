import 'enums.dart';
import 'graph.dart';
import 'models.dart';

/// Menerbitkan hubungan tidak langsung daripada [FamilyGraph] (SPEC 2.4).
///
/// Kaedah penerbitan (sibling, grandparent, uncle, cousin) mengembalikan
/// hubungan STRUKTUR tanpa menapis nasab — penapisan nasab untuk faraid dibuat
/// oleh Heir Extractor. Parameter `inheritingOnly` boleh dihidupkan bila
/// pemanggil hanya mahu laluan yang mewarisi.
class RelationshipResolver {
  RelationshipResolver(this.graph);

  final FamilyGraph graph;

  Person? _p(String id) => graph.person(id);

  Person? parentOf(String personId, ParentRole role, {bool inheritingOnly = false}) {
    final link = graph.parentLink(personId, role);
    if (link == null) return null;
    if (inheritingOnly && !link.inherits) return null;
    return _p(link.parentId);
  }

  /// Bapa pada [degree] peringkat ke atas (1 = bapa, 2 = datuk sebelah bapa...).
  List<Person> fathersOf(String personId, {int degree = 1, bool inheritingOnly = false}) {
    final out = <Person>[];
    var current = personId;
    for (var i = 0; i < degree; i++) {
      final f = parentOf(current, ParentRole.father, inheritingOnly: inheritingOnly);
      if (f == null) return out;
      out.add(f);
      current = f.id;
    }
    return out;
  }

  Person? fatherAtDegree(String personId, int degree, {bool inheritingOnly = false}) {
    final chain = fathersOf(personId, degree: degree, inheritingOnly: inheritingOnly);
    return chain.length == degree ? chain.last : null;
  }

  /// Anak-anak seseorang. [minStatus] = status nasab paling lemah yang diterima
  /// (mengikut kekuatan enum: `confirmed` paling kuat). Jika `null`, semua.
  List<Person> childrenOf(String personId, {NasabStatus? minStatus, bool biologicalOnly = false}) {
    final out = <Person>[];
    for (final l in graph.childLinksOf(personId)) {
      if (minStatus != null && l.nasabStatus.index > minStatus.index) continue;
      if (biologicalOnly && l.kind != LinkKind.biological) continue;
      final c = _p(l.childId);
      if (c != null) out.add(c);
    }
    return out;
  }

  /// Adik-beradik mengikut [kind]. Berkongsi bapa (paternal), ibu (maternal),
  /// atau kedua-duanya (full).
  List<Person> siblingsOf(String personId, SiblingKind kind, {bool inheritingOnly = false}) {
    final father = parentOf(personId, ParentRole.father, inheritingOnly: inheritingOnly);
    final mother = parentOf(personId, ParentRole.mother, inheritingOnly: inheritingOnly);
    final out = <Person>[];
    for (final other in graph.persons) {
      if (other.id == personId) continue;
      final of = parentOf(other.id, ParentRole.father, inheritingOnly: inheritingOnly);
      final om = parentOf(other.id, ParentRole.mother, inheritingOnly: inheritingOnly);
      final sameFather = father != null && of?.id == father.id;
      final sameMother = mother != null && om?.id == mother.id;
      switch (kind) {
        case SiblingKind.full:
          if (sameFather && sameMother) out.add(other);
        case SiblingKind.paternal:
          if (sameFather && !sameMother) out.add(other);
        case SiblingKind.maternal:
          if (sameMother && !sameFather) out.add(other);
      }
    }
    return out;
  }

  /// Semua nenek moyang sebelah bapa (bapa, datuk, moyang...).
  List<Person> ancestorsPaternal(String personId, {bool inheritingOnly = false}) {
    final out = <Person>[];
    var current = personId;
    final seen = <String>{};
    while (true) {
      final f = parentOf(current, ParentRole.father, inheritingOnly: inheritingOnly);
      if (f == null || !seen.add(f.id)) break;
      out.add(f);
      current = f.id;
    }
    return out;
  }

  /// Semua keturunan lelaki melalui anak lelaki (anak lelaki, cucu lelaki...).
  List<Person> descendantsMale(String personId, {bool inheritingOnly = true}) {
    final out = <Person>[];
    final stack = <String>[personId];
    final seen = <String>{};
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      for (final c in childrenOf(cur,
          minStatus: inheritingOnly ? NasabStatus.confirmed : null,
          biologicalOnly: inheritingOnly)) {
        if (c.gender != Gender.male) continue;
        if (!seen.add(c.id)) continue;
        out.add(c);
        stack.add(c.id);
      }
    }
    return out;
  }

  /// Bapa saudara mengikut sebelah: adik-beradik kepada bapa (paternal uncle
  /// jika `paternalSide`, jika tidak sebelah ibu).
  List<Person> unclesAunts(String personId, {required bool paternalSide, bool inheritingOnly = false}) {
    final parent = parentOf(personId, paternalSide ? ParentRole.father : ParentRole.mother,
        inheritingOnly: inheritingOnly);
    if (parent == null) return const [];
    return [
      ...siblingsOf(parent.id, SiblingKind.full, inheritingOnly: inheritingOnly),
      ...siblingsOf(parent.id, SiblingKind.paternal, inheritingOnly: inheritingOnly),
      ...siblingsOf(parent.id, SiblingKind.maternal, inheritingOnly: inheritingOnly),
    ];
  }

  /// Anak saudara: anak kepada adik-beradik.
  List<Person> niblings(String personId, SiblingKind via, {bool inheritingOnly = false}) {
    final out = <Person>[];
    for (final sib in siblingsOf(personId, via, inheritingOnly: inheritingOnly)) {
      out.addAll(childrenOf(sib.id,
          minStatus: inheritingOnly ? NasabStatus.confirmed : null));
    }
    return out;
  }

  /// Sepupu: anak kepada bapa/ibu saudara.
  List<Person> cousins(String personId, {required bool paternalSide, bool inheritingOnly = false}) {
    final out = <Person>[];
    for (final u in unclesAunts(personId, paternalSide: paternalSide, inheritingOnly: inheritingOnly)) {
      out.addAll(childrenOf(u.id,
          minStatus: inheritingOnly ? NasabStatus.confirmed : null));
    }
    return out;
  }

  /// Pasangan yang masih berkahwin dengan [personId].
  List<Person> currentSpouses(String personId) {
    final out = <Person>[];
    for (final l in graph.spouseLinksOf(personId)) {
      if (l.status != MarriageStatus.married) continue;
      final o = _p(l.other(personId));
      if (o != null) out.add(o);
    }
    return out;
  }

  /// Label hubungan ringkas dalam Bahasa Melayu (SPEC 2.4).
  RelationshipLabel describe(String fromId, String toId) {
    final from = _p(fromId);
    final to = _p(toId);
    if (from == null || to == null) {
      return const RelationshipLabel('tidak diketahui', 'unknown');
    }
    if (fromId == toId) return const RelationshipLabel('diri sendiri', 'self');

    // Pasangan.
    if (currentSpouses(fromId).any((p) => p.id == toId)) {
      return RelationshipLabel(
          to.gender == Gender.male ? 'suami' : 'isteri', 'spouse');
    }
    // Ibu bapa langsung.
    for (final role in ParentRole.values) {
      if (parentOf(fromId, role)?.id == toId) {
        return RelationshipLabel(
            role == ParentRole.father ? 'bapa' : 'ibu', role.name);
      }
    }
    // Anak.
    if (childrenOf(fromId).any((p) => p.id == toId)) {
      return RelationshipLabel(
          to.gender == Gender.male ? 'anak lelaki' : 'anak perempuan', 'child');
    }
    // Datuk / nenek.
    for (final side in [true, false]) {
      final gp = fatherAtDegree(fromId, 2);
      if (side && gp?.id == toId) {
        return const RelationshipLabel('datuk sebelah bapa', 'grandparent_paternal');
      }
    }
    // Adik-beradik.
    for (final kind in SiblingKind.values) {
      if (siblingsOf(fromId, kind).any((p) => p.id == toId)) {
        final g = to.gender == Gender.male ? 'Saudara lelaki' : 'Saudara perempuan';
        final suffix = switch (kind) {
          SiblingKind.full => 'seibu-sebapa',
          SiblingKind.paternal => 'sebapa',
          SiblingKind.maternal => 'seibu',
        };
        return RelationshipLabel('$g $suffix', 'sibling_${kind.name}');
      }
    }
    // Bapa/ibu saudara.
    for (final side in [true, false]) {
      if (unclesAunts(fromId, paternalSide: side).any((p) => p.id == toId)) {
        final g = to.gender == Gender.male ? 'Bapa saudara' : 'Ibu saudara';
        return RelationshipLabel(
            '$g sebelah ${side ? 'bapa' : 'ibu'}', 'uncle_${side ? 'paternal' : 'maternal'}');
      }
    }
    // Sepupu.
    for (final side in [true, false]) {
      if (cousins(fromId, paternalSide: side).any((p) => p.id == toId)) {
        return const RelationshipLabel('sepupu', 'cousin');
      }
    }
    return const RelationshipLabel('ahli keluarga', 'relative');
  }
}

class RelationshipLabel {
  const RelationshipLabel(this.text, this.code);
  final String text;
  final String code;

  @override
  String toString() => text;
}
