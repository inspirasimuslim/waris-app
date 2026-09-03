import 'graph.dart';
import 'models.dart';

/// Cadangan "kemungkinan orang yang sama" (SPEC 2.8). TIDAK pernah menggabung
/// automatik — hanya mencadangkan.
class DuplicateSuggestion {
  DuplicateSuggestion(this.candidate, this.score, this.reason);
  final Person candidate;
  final double score;
  final String reason;
}

/// Cari calon pertindihan untuk seseorang yang hendak ditambah.
List<DuplicateSuggestion> findDuplicates(
  FamilyGraph graph, {
  required String name,
  required Gender gender,
  DateTime? birthDate,
}) {
  final out = <DuplicateSuggestion>[];
  final target = name.trim().toLowerCase();
  for (final p in graph.persons) {
    if (p.gender != gender) continue;
    final sim = _nameSimilarity(target, p.name.trim().toLowerCase());
    if (sim < 0.7) continue;
    var score = sim;
    final reasons = <String>['nama serupa (${(sim * 100).round()}%)'];
    if (birthDate != null && p.birthDate != null) {
      final diff = birthDate.difference(p.birthDate!).inDays.abs();
      if (diff <= 366) {
        score += 0.2;
        reasons.add('tarikh lahir hampir');
      }
    }
    out.add(DuplicateSuggestion(p, score, reasons.join(', ')));
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
}

/// Kesamaan berasaskan jarak Levenshtein ternormal (0..1).
double _nameSimilarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final d = _levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  return 1 - d / maxLen;
}

int _levenshtein(String a, String b) {
  final m = a.length;
  final n = b.length;
  final prev = List<int>.generate(n + 1, (i) => i);
  final curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    for (var j = 0; j <= n; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[n];
}
