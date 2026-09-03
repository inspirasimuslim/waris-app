# WARIS

Digital Family Network untuk keluarga Muslim. Faraid hanyalah salah satu enjin
di atas graf keluarga. Lihat [`docs/SPEC.md`](docs/SPEC.md) untuk spesifikasi penuh.

## Struktur monorepo

| Path | Jenis | Fasa |
|---|---|---|
| `packages/faraid_engine` | Pure Dart — enjin faraid deterministik | 1 |
| `packages/family_graph` | Pure Dart — model graf, resolver, heir extractor | 2 |
| `packages/wali_engine` | Pure Dart — enjin wali (rangka) | 6 |
| `packages/mahram_engine` | Pure Dart — enjin mahram (rangka) | 6 |
| `app` | Flutter — Family Network UI | 3+ |

Diurus dengan [Melos](https://melos.invertase.dev) + Dart pub workspace.

## Persekitaran

- Flutter `3.47.2` (stable) — dikunci dalam `.fvmrc`
- Dart `3.13.2`
- Melos `8.6.0` (global: `dart pub global activate melos`)

## Arahan biasa

```bash
dart pub get                      # resolve seluruh workspace
dart pub global run melos bootstrap
dart pub global run melos run test        # ujian pure-Dart (enjin + graf)
dart pub global run melos run test:flutter # ujian widget
dart pub global run melos run analyze
```

## Prinsip yang tidak dibuka semula

Lihat SPEC A3 dan D3. Ringkasnya: enjin sebelum UI; pecahan bukan titik terapung;
nasab menapis waris; snapshot immutable; AI menerangkan bukan menentukan;
bendera ketidakpastian jangan teka; tiada bahasa menghukum; ilmu asas kekal percuma.
