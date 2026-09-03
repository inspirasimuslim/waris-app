// CLI semakan enjin faraid (SPEC 1.6). Membolehkan penasihat Syariah menyemak
// enjin tanpa membuka app.
//
//   dart run faraid_engine:check path/ke/kes.yaml [kes2.yaml ...]
//   dart run faraid_engine:check --dir test/cases
//   dart run faraid_engine:check --input '{deceased_gender: female, heirs: [...]}'
//
// Kod keluar 0 jika semua kes lulus (atau tiada blok `expected`), 1 jika ada
// yang gagal.

import 'dart:io';

import 'package:faraid_engine/faraid_engine.dart';
import 'package:yaml/yaml.dart';

const _engine = FaraidEngine();

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln('''
Semakan enjin faraid WARIS ($rulesetMalaysiaSyafieV1)

Guna:
  dart run faraid_engine:check <fail.yaml> [...]
  dart run faraid_engine:check --dir <direktori>

Setiap fail YAML ialah senarai kes (lihat test/cases/*.yaml).
''');
    exit(args.isEmpty ? 2 : 0);
  }

  final files = <File>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--dir') {
      final dir = Directory(args[++i]);
      files.addAll(dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml')));
    } else {
      files.add(File(a));
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));

  var total = 0;
  var passed = 0;
  var failed = 0;

  for (final f in files) {
    if (!f.existsSync()) {
      stderr.writeln('! Fail tidak wujud: ${f.path}');
      failed++;
      continue;
    }
    final doc = loadYaml(f.readAsStringSync());
    final list = doc is YamlList ? doc : [doc];
    for (final raw in list) {
      final m = raw as YamlMap;
      total++;
      final id = m['id'] as String? ?? '(tanpa id)';
      final name = m['name'] as String? ?? '';
      final result = _engine.calculate(_toInput(m['input'] as YamlMap));
      final problems = _check(m['expected'] as YamlMap?, result);
      if (problems.isEmpty) {
        passed++;
        stdout.writeln('  OK  $id  $name');
      } else {
        failed++;
        stdout.writeln('FAIL  $id  $name');
        for (final p in problems) {
          stdout.writeln('        - $p');
        }
        stdout.writeln('      Bahagian dikira:');
        for (final s in result.shares) {
          stdout.writeln('        ${s.type.name} x${s.count}: '
              '${s.shareTotal} (${s.basis.name})'
              '${s.amountTotal != null ? '  ${s.amountTotal}' : ''}');
        }
      }
    }
  }

  stdout.writeln('\n${'-' * 50}');
  stdout.writeln('$total kes  ·  $passed lulus  ·  $failed gagal');
  exit(failed == 0 ? 0 : 1);
}

FaraidInput _toInput(YamlMap input) {
  final genderStr = input['deceased_gender'] as String;
  final estate = input['net_estate'];
  final heirs = (input['heirs'] as YamlList).map((h) {
    final m = h as YamlMap;
    return HeirClaim(
      HeirType.values.firstWhere((t) => t.name == m['type']),
      count: (m['count'] as int?) ?? 1,
      nasabConfirmed: (m['nasab_confirmed'] as bool?) ?? true,
    );
  }).toList();
  return FaraidInput(
    deceasedGender: genderStr == 'male' ? Gender.male : Gender.female,
    netEstate: estate == null ? null : Money.ringgit(estate as num),
    claims: heirs,
  );
}

List<String> _check(YamlMap? expected, FaraidResult r) {
  final problems = <String>[];
  if (expected == null) return problems;

  final s = expected['status'] as String?;
  if (s != null && r.status.name != s) {
    problems.add('status: jangka $s, dapat ${r.status.name}');
  }
  final am = expected['asal_masalah'];
  if (am != null && r.asalMasalah != am) {
    problems.add('asal masalah: jangka $am, dapat ${r.asalMasalah}');
  }
  final amt = expected['asal_masalah_tashih'];
  if (amt != null && r.asalMasalahAfterTashih != amt) {
    problems.add(
        'asal masalah tashih: jangka $amt, dapat ${r.asalMasalahAfterTashih}');
  }
  final shares = expected['shares'] as YamlList?;
  if (shares != null) {
    for (final e in shares) {
      final m = e as YamlMap;
      final type = m['type'] as String;
      final got = r.shares.where((x) => x.type.name == type).toList();
      if (got.length != 1) {
        problems.add('$type: sepatutnya menerima bahagian');
        continue;
      }
      final g = got.single;
      final fr = m['fraction'];
      if (fr != null && g.shareTotal != Fraction.parse(fr as String)) {
        problems.add('$type pecahan: jangka $fr, dapat ${g.shareTotal}');
      }
      final b = m['basis'];
      if (b != null && g.basis.name != b) {
        problems.add('$type asas: jangka $b, dapat ${g.basis.name}');
      }
      final amount = m['amount'];
      if (amount != null &&
          g.amountTotal != Money.ringgit(amount as num)) {
        problems.add('$type wang: jangka RM $amount, dapat ${g.amountTotal}');
      }
    }
  }
  final blocked = expected['blocked'] as YamlList?;
  if (blocked != null) {
    for (final b in blocked) {
      if (!r.blocked.any((x) => x.type.name == b)) {
        problems.add('$b: sepatutnya terdinding');
      }
    }
  }
  return problems;
}
