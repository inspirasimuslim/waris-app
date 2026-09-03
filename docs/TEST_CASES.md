# Kes Ujian Faraid

Kes sebenar berada dalam `packages/faraid_engine/test/cases/*.yaml`. Dokumen ini
ialah indeks dan nota sumber.

| Fail | Julat ID | Fokus | Bilangan |
|---|---|---|---|
| `basic_001_to_030.yaml` | FRD-001..030 | Fardu asas, pasangan, ibu bapa, anak, asabah bi-nafsihi | 30 |
| `hajb_031_to_060.yaml` | FRD-031..060 | Hajb hirman & nuqsan | 30 |
| `aul_061_to_080.yaml` | FRD-061..080 | Aul (asal masalah 6, 12, 24) | 20 |
| `radd_081_to_095.yaml` | FRD-081..095 | Radd dengan/tanpa pasangan | 15 |
| `tashih_096_to_105.yaml` | FRD-096..105 | Tashih / asal masalah dinaik | 10 |
| `special_106_to_120.yaml` | FRD-106..120 | Umariyyatain, akdariyyah, jadd wal-ikhwah, asabah bi/ma'a-ghayrihi | 15 |
| `nasab_121_to_130.yaml` | FRD-121..130 | Nasab tidak sabit — waris ditapis | 10 |

Jumlah: **130 kes** (≥ 120 diperlukan SPEC 1.6).

## Sumber

- Kitab faraid muktabar (mazhab Syafie) — rujukan bab dalam medan `source` setiap kes.
- Contoh rasmi e-Faraid MAIS / kalkulator MyGovernment.
- Silang-semak: 20 kes akan dimasukkan semula ke e-Faraid MAIS dan dibandingkan
  (SPEC 1.6 langkah 5) — belum dibuat, memerlukan akses manual.

## Status pengesahan

Semua kes `verified_by: pending`. Lihat DECISIONS D-004.

## Status pelaksanaan (Fasa 1)

- 130 kes ditulis; **130/130 lulus** (`melos run test`).
- Runner: `test/engine_cases_test.dart` + `test/support/case_runner.dart`.
- CLI semakan: `dart run faraid_engine:check --dir test/cases` (untuk penasihat Syariah).
- Ujian tambahan: `engine_quick_test.dart` (18 kes klasik), `trace_test.dart` (SPEC 1.5/1.7).
- **Silang-semak e-Faraid MAIS (20 kes) BELUM dibuat** — memerlukan akses manual
  kepada kalkulator dalam talian. Lihat DECISIONS D-007.
