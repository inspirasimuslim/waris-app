import 'enums.dart';
import 'graph.dart';
import 'models.dart';

/// Keterukan penemuan pengesahan data (SPEC 2.9).
enum IssueLevel {
  /// ⚠️ Bendera sahaja — pengguna boleh teruskan.
  warning,

  /// 🚫 Mesti dihalang.
  blocking,
}

class DataIssue {
  DataIssue(this.level, this.code, this.message, {this.personIds = const []});
  final IssueLevel level;
  final String code;
  final String message;
  final List<String> personIds;

  @override
  String toString() => '${level.name.toUpperCase()} $code: $message';
}

/// Semak keadaan tidak munasabah dalam graf (SPEC 2.9). Membendera, tidak
/// menghalang — KECUALI kitaran graf (yang sudah dihalang di [FamilyGraph]).
List<DataIssue> validateGraph(FamilyGraph graph) {
  final issues = <DataIssue>[];

  for (final link in graph.parentLinks) {
    final child = graph.person(link.childId);
    final parent = graph.person(link.parentId);
    if (child == null || parent == null) continue;

    // Anak lebih tua daripada ibu bapa.
    final cb = child.birthDate;
    final pb = parent.birthDate;
    if (cb != null && pb != null && !cb.isAfter(pb)) {
      issues.add(DataIssue(IssueLevel.warning, 'child_older_than_parent',
          '${child.name} dilahirkan sebelum atau sama dengan ${parent.name} '
          '(ibu bapa) — maklumat mungkin tidak konsisten.',
          personIds: [child.id, parent.id]));
    }

    // Anak lahir lebih 9 bulan selepas kematian bapa.
    if (link.role == ParentRole.father &&
        parent.status == LifeStatus.deceased &&
        parent.deathDate != null &&
        cb != null) {
      final gap = cb.difference(parent.deathDate!).inDays;
      if (gap > 280) {
        issues.add(DataIssue(IssueLevel.warning, 'born_after_father_death',
            '${child.name} dilahirkan lebih 9 bulan selepas kematian '
            '${parent.name} — tarikh mungkin perlu disemak.',
            personIds: [child.id, parent.id]));
      }
    }
  }

  // Dua bapa (atau dua ibu) berbeza untuk seorang anak.
  final byChildRole = <String, List<ParentLink>>{};
  for (final l in graph.parentLinks) {
    byChildRole.putIfAbsent('${l.childId}:${l.role.name}', () => []).add(l);
  }
  for (final entry in byChildRole.entries) {
    final distinctParents = entry.value.map((l) => l.parentId).toSet();
    if (distinctParents.length > 1) {
      final childId = entry.value.first.childId;
      issues.add(DataIssue(IssueLevel.warning, 'conflicting_nasab',
          '${graph.person(childId)?.name ?? childId} mempunyai lebih daripada '
          'satu ${entry.value.first.role.name} yang berbeza — percanggahan nasab.',
          personIds: [childId, ...distinctParents]));
    }
  }

  // Perkahwinan tidak munasabah dari segi umur (pasangan < 15 tahun pada tarikh
  // kahwin).
  for (final s in graph.spouseLinks) {
    if (s.marriageDate == null) continue;
    for (final pid in [s.personAId, s.personBId]) {
      final p = graph.person(pid);
      final bd = p?.birthDate;
      if (bd == null) continue;
      final ageAtMarriage = s.marriageDate!.difference(bd).inDays ~/ 365;
      if (ageAtMarriage < 15) {
        issues.add(DataIssue(IssueLevel.warning, 'implausible_marriage_age',
            '${p!.name} berumur kira-kira $ageAtMarriage tahun pada tarikh '
            'perkahwinan — sila semak tarikh.',
            personIds: [pid]));
      }
    }
  }

  return issues;
}
