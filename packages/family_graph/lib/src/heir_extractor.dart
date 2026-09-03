import 'package:faraid_engine/faraid_engine.dart';

import 'enums.dart';
import 'graph.dart';
import 'models.dart';
import 'resolver.dart';

/// Hasil penukaran graf → input enjin faraid.
class HeirExtraction {
  HeirExtraction({
    required this.input,
    required this.notes,
    required this.excluded,
  });

  /// Sedia untuk diberikan kepada [FaraidEngine.calculate].
  final FaraidInput input;

  /// Perkara yang perlu diberi perhatian pengguna (nasab tidak pasti, status
  /// hidup tidak diketahui...). Bukan ralat — panduan.
  final List<String> notes;

  /// Orang yang WUJUD dalam graf tetapi TIDAK dimasukkan sebagai waris, dengan
  /// sebab (untuk skrin "Tidak mewarisi").
  final List<ExcludedPerson> excluded;
}

class ExcludedPerson {
  ExcludedPerson(this.person, this.wouldBe, this.reason);
  final Person person;
  final HeirType? wouldBe;
  final String reason;
}

/// Menukar [FamilyGraph] kepada [FaraidInput] untuk seorang si mati (SPEC 2.5).
///
/// Menggunakan **lapisan nasab**, bukan lapisan hubungan keluarga: anak yang
/// nasabnya tidak sabit kepada si mati TIDAK dimasukkan sebagai anak.
class HeirExtractor {
  HeirExtractor(this.graph) : _r = RelationshipResolver(graph);

  final FamilyGraph graph;
  final RelationshipResolver _r;

  HeirExtraction extractHeirs({
    required String deceasedId,
    required DateTime simulationDate,
    Ruleset ruleset = Ruleset.malaysiaSyafieV1,
    Money? netEstate,
  }) {
    final deceased = graph.requirePerson(deceasedId);
    final notes = <String>[];
    final excluded = <ExcludedPerson>[];
    final counts = <HeirType, int>{};

    bool alive(Person p) => p.isAliveOn(simulationDate);

    void add(HeirType t, Iterable<Person> people) {
      final live = people.where((p) => p.id != deceasedId).toList();
      for (final p in live) {
        if (p.status == LifeStatus.unknown) {
          notes.add('Status hidup ${p.name} tidak diketahui — ${t.name} '
              'berpotensi terjejas.');
          excluded.add(ExcludedPerson(p, t, 'Status hidup tidak diketahui'));
        } else if (alive(p)) {
          counts[t] = (counts[t] ?? 0) + 1;
        } else {
          excluded.add(ExcludedPerson(
              p, t, 'Telah meninggal sebelum tarikh simulasi'));
        }
      }
    }

    // Catat orang yang pertalian nasabnya menghalang pewarisan.
    void flagNonInheriting(ParentRole role, String label) {
      final link = graph.parentLink(deceasedId, role);
      if (link != null && !link.inherits) {
        notes.add('Nasab $label si mati: ${link.nasabStatus.name} — '
            'rantaian sebelah $label tidak dibina.');
      }
    }

    flagNonInheriting(ParentRole.father, 'bapa');
    flagNonInheriting(ParentRole.mother, 'ibu');

    // --- Pasangan ---
    for (final s in _r.currentSpouses(deceasedId)) {
      if (!alive(s)) {
        excluded.add(ExcludedPerson(s, null, 'Pasangan telah meninggal'));
        continue;
      }
      if (s.gender == Gender.male && deceased.gender == Gender.female) {
        counts[HeirType.husband] = 1;
      } else if (s.gender == Gender.female && deceased.gender == Gender.male) {
        counts[HeirType.wife] = (counts[HeirType.wife] ?? 0) + 1;
      }
    }

    // --- Ibu bapa ---
    final father = _r.parentOf(deceasedId, ParentRole.father, inheritingOnly: true);
    final mother = _r.parentOf(deceasedId, ParentRole.mother, inheritingOnly: true);
    if (father != null) add(HeirType.father, [father]);
    if (mother != null) add(HeirType.mother, [mother]);

    // --- Datuk & nenek ---
    // Datuk sebelah bapa: bapa kepada bapa (rantaian mewarisi).
    final pgf = _nearestPaternalGrandfather(deceasedId);
    if (pgf != null) add(HeirType.paternalGrandfather, [pgf]);
    // Nenek sebelah bapa: ibu kepada bapa.
    if (father != null) {
      final pgm = _r.parentOf(father.id, ParentRole.mother, inheritingOnly: true);
      if (pgm != null) add(HeirType.paternalGrandmother, [pgm]);
    }
    // Nenek sebelah ibu: ibu kepada ibu.
    if (mother != null) {
      final mgm = _r.parentOf(mother.id, ParentRole.mother, inheritingOnly: true);
      if (mgm != null) add(HeirType.maternalGrandmother, [mgm]);
    }

    // --- Anak ---
    final children = _r.childrenOf(deceasedId,
        minStatus: NasabStatus.confirmed, biologicalOnly: true);
    _reportExcludedChildren(deceasedId, children, excluded, notes);
    add(HeirType.son, children.where((c) => c.gender == Gender.male));
    add(HeirType.daughter, children.where((c) => c.gender == Gender.female));

    // --- Cucu melalui anak lelaki (satu peringkat; peringkat lebih dalam
    //     dibendera) ---
    for (final son in children.where((c) => c.gender == Gender.male)) {
      final gk = _r.childrenOf(son.id,
          minStatus: NasabStatus.confirmed, biologicalOnly: true);
      add(HeirType.sonsSon, gk.where((c) => c.gender == Gender.male));
      add(HeirType.sonsDaughter, gk.where((c) => c.gender == Gender.female));
    }
    // Cucu daripada anak lelaki yang SUDAH meninggal (mereka mewarisi bila
    // bapa mereka tiada).
    for (final ex in excluded.where((e) => e.wouldBe == HeirType.son)) {
      final gk = _r.childrenOf(ex.person.id,
          minStatus: NasabStatus.confirmed, biologicalOnly: true);
      add(HeirType.sonsSon, gk.where((c) => c.gender == Gender.male));
      add(HeirType.sonsDaughter, gk.where((c) => c.gender == Gender.female));
    }

    // --- Adik-beradik ---
    add(HeirType.fullBrother,
        _r.siblingsOf(deceasedId, SiblingKind.full, inheritingOnly: true)
            .where((p) => p.gender == Gender.male));
    add(HeirType.fullSister,
        _r.siblingsOf(deceasedId, SiblingKind.full, inheritingOnly: true)
            .where((p) => p.gender == Gender.female));
    add(HeirType.paternalBrother,
        _r.siblingsOf(deceasedId, SiblingKind.paternal, inheritingOnly: true)
            .where((p) => p.gender == Gender.male));
    add(HeirType.paternalSister,
        _r.siblingsOf(deceasedId, SiblingKind.paternal, inheritingOnly: true)
            .where((p) => p.gender == Gender.female));
    add(HeirType.maternalSibling,
        _r.siblingsOf(deceasedId, SiblingKind.maternal, inheritingOnly: true));

    // --- Anak saudara lelaki (melalui saudara lelaki) ---
    add(HeirType.fullBrothersSon, _nephewSons(deceasedId, SiblingKind.full));
    add(HeirType.paternalBrothersSon,
        _nephewSons(deceasedId, SiblingKind.paternal));

    // --- Bapa saudara sebelah bapa & anak mereka ---
    if (father != null) {
      final fullUncles = _r
          .siblingsOf(father.id, SiblingKind.full, inheritingOnly: true)
          .where((p) => p.gender == Gender.male)
          .toList();
      final patUncles = _r
          .siblingsOf(father.id, SiblingKind.paternal, inheritingOnly: true)
          .where((p) => p.gender == Gender.male)
          .toList();
      add(HeirType.fullPaternalUncle, fullUncles);
      add(HeirType.paternalUncle, patUncles);
      for (final u in fullUncles) {
        add(HeirType.fullPaternalUnclesSon,
            _r.childrenOf(u.id, minStatus: NasabStatus.confirmed, biologicalOnly: true)
                .where((p) => p.gender == Gender.male));
      }
      for (final u in patUncles) {
        add(HeirType.paternalUnclesSon,
            _r.childrenOf(u.id, minStatus: NasabStatus.confirmed, biologicalOnly: true)
                .where((p) => p.gender == Gender.male));
      }
    }

    final claims = counts.entries
        .map((e) => HeirClaim(e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    return HeirExtraction(
      input: FaraidInput(
        deceasedGender: deceased.gender,
        ruleset: ruleset,
        netEstate: netEstate,
        claims: claims,
      ),
      notes: notes,
      excluded: excluded,
    );
  }

  Person? _nearestPaternalGrandfather(String personId) {
    final chain = _r.ancestorsPaternal(personId, inheritingOnly: true);
    // chain[0] = bapa; datuk = chain[1] jika ada.
    if (chain.length < 2) return null;
    return chain[1];
  }

  List<Person> _nephewSons(String deceasedId, SiblingKind via) {
    final out = <Person>[];
    for (final sib in _r.siblingsOf(deceasedId, via, inheritingOnly: true)) {
      if (sib.gender != Gender.male) continue;
      out.addAll(_r
          .childrenOf(sib.id, minStatus: NasabStatus.confirmed, biologicalOnly: true)
          .where((p) => p.gender == Gender.male));
    }
    return out;
  }

  void _reportExcludedChildren(String deceasedId, List<Person> inheriting,
      List<ExcludedPerson> excluded, List<String> notes) {
    final inheritingIds = inheriting.map((p) => p.id).toSet();
    for (final l in graph.childLinksOf(deceasedId)) {
      if (inheritingIds.contains(l.childId)) continue;
      final p = graph.person(l.childId);
      if (p == null) continue;
      final reason = l.kind != LinkKind.biological
          ? 'Pertalian ${l.kind.name} — tidak mewarisi melalui nasab'
          : 'Nasab ${l.nasabStatus.name} — tidak sabit sebagai anak';
      excluded.add(ExcludedPerson(
          p, p.gender == Gender.male ? HeirType.son : HeirType.daughter, reason));
      notes.add('${p.name} tidak dikira sebagai anak: $reason.');
    }
  }
}
