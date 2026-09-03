import 'dart:io';

import 'package:faraid_engine/faraid_engine.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Satu kes ujian faraid dari fail YAML (format SPEC 1.6).
class FaraidCase {
  FaraidCase(this.raw, this.file);

  final YamlMap raw;
  final String file;

  String get id => raw['id'] as String;
  String get name => raw['name'] as String? ?? id;
  String get source => raw['source'] as String? ?? 'unknown';
  String get verifiedBy => raw['verified_by'] as String? ?? 'pending';

  FaraidInput toInput() {
    final input = raw['input'] as YamlMap;
    final genderStr = input['deceased_gender'] as String;
    final estate = input['net_estate'];
    final heirs = (input['heirs'] as YamlList).map((h) {
      final m = h as YamlMap;
      return HeirClaim(
        _heirType(m['type'] as String),
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

  /// Sahkan [result] terhadap blok `expected`. Melempar [TestFailure] jika gagal.
  void verify(FaraidResult result) {
    final expected = raw['expected'] as YamlMap;

    final expStatus = expected['status'] as String?;
    if (expStatus != null) {
      expect(result.status.name, expStatus,
          reason: '$id: status enjin tidak sepadan');
    }

    final expAm = expected['asal_masalah'];
    if (expAm != null) {
      expect(result.asalMasalah, expAm,
          reason: '$id: asal masalah tidak sepadan');
    }
    final expAmTashih = expected['asal_masalah_tashih'];
    if (expAmTashih != null) {
      expect(result.asalMasalahAfterTashih, expAmTashih,
          reason: '$id: asal masalah selepas tashih tidak sepadan');
    }

    final expShares = expected['shares'] as YamlList?;
    if (expShares != null) {
      for (final e in expShares) {
        final m = e as YamlMap;
        final type = _heirType(m['type'] as String);
        final share =
            result.shares.where((s) => s.type == type).toList();
        expect(share, hasLength(1),
            reason: '$id: waris ${m['type']} sepatutnya menerima bahagian');
        final got = share.single;
        if (m['fraction'] != null) {
          expect(got.shareTotal, Fraction.parse(m['fraction'] as String),
              reason: '$id: pecahan ${m['type']} '
                  '(dapat ${got.shareTotal}, jangka ${m['fraction']})');
        }
        if (m['fraction_each'] != null) {
          expect(got.shareEach, Fraction.parse(m['fraction_each'] as String),
              reason: '$id: pecahan setiap ${m['type']}');
        }
        if (m['basis'] != null) {
          expect(got.basis.name, m['basis'],
              reason: '$id: asas bahagian ${m['type']}');
        }
        if (m['amount'] != null) {
          final want = Money.ringgit(m['amount'] as num);
          expect(got.amountTotal, want,
              reason: '$id: jumlah wang ${m['type']} '
                  '(dapat ${got.amountTotal}, jangka $want)');
        }
      }
    }

    final expBlocked = expected['blocked'] as YamlList?;
    if (expBlocked != null) {
      for (final b in expBlocked) {
        final type = _heirType(b as String);
        expect(result.blocked.any((x) => x.type == type), isTrue,
            reason: '$id: $b sepatutnya terdinding');
        expect(result.shares.any((s) => s.type == type), isFalse,
            reason: '$id: $b terdinding tetapi menerima bahagian');
      }
    }

    // Jumlah bahagian mesti tepat 1, kecuali dinyatakan sebaliknya.
    final allowPartial = expected['allow_baitulmal'] as bool? ?? false;
    if (!allowPartial && result.status == ResultStatus.ok) {
      expect(result.totalShare, Fraction.one,
          reason: '$id: jumlah semua bahagian = ${result.totalShare}, '
              'sepatutnya 1');
    }

    // Wang: jumlah agihan mesti sama dengan harta bersih.
    if (result.netEstate != null && result.status == ResultStatus.ok) {
      var sum = Money.zero;
      for (final s in result.shares) {
        sum += s.amountTotal ?? Money.zero;
      }
      if (!allowPartial) {
        expect(sum, result.netEstate,
            reason: '$id: jumlah wang diagih ($sum) != harta bersih '
                '(${result.netEstate})');
      }
    }
  }
}

HeirType _heirType(String s) {
  for (final t in HeirType.values) {
    if (t.name == s) return t;
  }
  throw ArgumentError('Jenis waris tidak dikenali: $s');
}

/// Muat semua kes daripada `test/cases/*.yaml`.
List<FaraidCase> loadAllCases([String dir = 'test/cases']) {
  final d = Directory(dir);
  if (!d.existsSync()) {
    throw StateError('Direktori kes tidak wujud: ${d.absolute.path}');
  }
  final cases = <FaraidCase>[];
  final files = d
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final doc = loadYaml(f.readAsStringSync());
    if (doc is! YamlList) {
      throw FormatException('${f.path}: fail sepatutnya senarai kes YAML');
    }
    for (final c in doc) {
      cases.add(FaraidCase(c as YamlMap, f.uri.pathSegments.last));
    }
  }
  return cases;
}
