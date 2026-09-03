import 'package:faraid_engine/faraid_engine.dart';
import 'package:test/test.dart';

import 'support/case_runner.dart';

/// Runner untuk semua kes YAML dalam `test/cases/` (SPEC 1.6).
///
/// Jalankan dari direktori package: `dart test test/engine_cases_test.dart`.
void main() {
  const engine = FaraidEngine();
  final cases = loadAllCases();

  test('sekurang-kurangnya 120 kes ujian dimuatkan (SPEC 1.6)', () {
    expect(cases.length, greaterThanOrEqualTo(120),
        reason: 'Dapat ${cases.length} kes.');
  });

  test('semua id kes unik', () {
    final ids = cases.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('setiap kes mempunyai medan source (SPEC 1.6 langkah 2)', () {
    final missing =
        cases.where((c) => c.source == 'unknown').map((c) => c.id).toList();
    expect(missing, isEmpty, reason: 'Kes tanpa source: $missing');
  });

  group('kes faraid', () {
    for (final c in cases) {
      test('${c.id} — ${c.name} [${c.file}]', () {
        final result = engine.calculate(c.toInput());
        c.verify(result);
      });
    }
  });
}
