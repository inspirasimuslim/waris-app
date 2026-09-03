# Log Keputusan Seni Bina — WARIS

Format: tarikh · keputusan · sebab · status.

---

## 2026-09-03 — Fasa 0

### D-001 · Melos 8 + Dart pub workspace
Guna Melos 8.6.0 di atas `workspace:` asli Dart (SDK 3.13) dan `resolution: workspace`
pada setiap package. Satu lockfile untuk seluruh repo. Sebab: Melos 8 tidak lagi
menguruskan pub get sendiri; ia mewakilkan kepada pub workspace.

### D-002 · Nama package sementara `my.sakuradigital.waris`
Ikut SPEC 0.2. Semakan cap dagangan MyIPO, App/Play Store, domain, dan SSM
**belum dibuat** (memerlukan tindakan pemilik). Andaian kerja: nama "WARIS" kekal,
applicationId `my.sakuradigital.waris`. `flutter create` menjana `my.sakuradigital.waris_app`
— akan dibetulkan ke `my.sakuradigital.waris` dalam Fasa 5 (SPEC 5.1).

### D-003 · Nama pakej Dart untuk app ialah `waris_app`
`waris` bertindih dengan konvensyen; direktori kekal `app/`. Tidak menjejaskan applicationId.

### D-004 · `verified_by: pending` pada semua kes ujian faraid
SPEC 0.3 menetapkan penasihat faraid mesti sahkan 120 kes sebelum Fasa 1 tamat.
Penasihat belum dilantik (tindakan pemilik). Kes ujian diambil daripada rujukan
muktabar dan didokumen dalam medan `source`; medan `verified_by` kekal `pending`
sehingga disahkan. Enjin ditandakan "lulus ujian" tetapi **belum disahkan Syariah**.

### D-005 · lints ^6.0.0 seluruh workspace
`flutter_lints: ^6.0.0` (dari `flutter create`) menarik `lints ^6.0.0`. Satu
resolusi workspace bermakna semua package guna versi sama.

### D-006 · Repo GitHub private belum dibuat
`git init` tempatan sudah ada. Menolak ke GitHub private memerlukan kredential
pemilik (SPEC 0.1). Kerja diteruskan pada repo tempatan; tag milestone dibuat tempatan.

---

## 2026-09-03 — Fasa 1

### D-007 · Silang-semak e-Faraid MAIS ditangguh
SPEC 1.6 langkah 5 menetapkan 20 kes rawak dimasukkan ke e-Faraid MAIS dan
dibandingkan. Ini memerlukan interaksi manual dengan kalkulator dalam talian —
tidak dapat diautomasikan di sini. 130 kes dalaman lulus 100%. Tindakan pemilik.

### D-008 · Radd: pasangan dikecualikan; baki tanpa waris lain ke Baitulmal
Ikut pendapat majoriti (FARAID_RULES §4). Jika hanya pasangan tinggal, enjin
memberi pasangan bahagian fardu sahaja dan menandakan baki sebagai Baitulmal
(`allow_baitulmal`), bukan radd kepada pasangan. Malaysia moden kadang beri radd
kepada pasangan bila tiada waris lain — boleh dijadikan pilihan ruleset kemudian.

### D-009 · Kes di luar skop MVP yang dibendera (bukan diteka)
`requiresManualReview` + amaran dikeluarkan untuk: musyarakah/himariyyah,
jadd wal-ikhwah dengan mu'adda (campuran saudara s.i.s + sebapa), jadd
wal-ikhwah dengan aul (jaminan 1/6 datuk melebihi baki), datuk bersama
saudara perempuan sahaja (kaedah had fardu penuh). Selebihnya SPEC 1.5 lajur
"MVP ✅" dilaksanakan penuh.

### D-010 · Akdariyyah & Umariyyatain dikesan secara ketat
Akdariyyah: si mati perempuan + suami + ibu + datuk + tepat seorang saudara
perempuan (s.i.s ATAU sebapa), tiada waris lain — keputusan piawai 27 (H 9, M 6,
GF 8, S 4). Umariyyatain: pasangan + ibu + bapa sahaja (selepas tapisan nasab,
sebelum hajb) — ibu 1/3 baki.

### D-011 · Money guna BigInt sen; `Fraction.toDouble()` untuk paparan sahaja
Tiada `double` dalam laluan pengiraan. Agihan wang guna kaedah baki sen supaya
jumlah agihan = harta bersih tepat ke sen.

---

## 2026-09-03 — Fasa 2

### D-012 · Drift/SQLite ditangguh ke lapisan app (Fasa 3)
`family_graph` kekal PURE Dart tanpa `drift`/`build_runner`. Skema SQL penuh
(SPEC 2.6) disimpan sebagai pemalar `familyGraphSchemaSql` dan graf dalam-memori
menyokong `toJson`/`fromJson`. Lapisan Drift sebenar (yang perlukan runtime
Flutter + `sqlite3` native untuk peranti) dibina dalam `app/lib/data/` pada
Fasa 3 daripada skema yang sama. Snapshot immutable (SPEC 2.7) sudah berfungsi
penuh sebagai JSON dalam `family_graph`.

### D-013 · Nasab menapis di extractor, bukan resolver
`RelationshipResolver` menerbitkan hubungan STRUKTUR (untuk pelabelan UI).
`HeirExtractor` menggunakan pertalian `inherits` sahaja (nasab `confirmed` +
`LinkKind.biological` + perkahwinan `married`). Anak angkat / anak tiri / nasab
tidak sabit dimasukkan ke senarai `excluded` dengan sebab, bukan dibuang senyap.

### D-014 · Kitaran graf DIHALANG di `FamilyGraph.addParentLink`
Melempar `ArgumentError` (SPEC 2.9) kerana resolver akan berulang tanpa henti.
Semua semakan lain (anak lebih tua daripada ibu bapa, lahir selepas kematian
bapa, dua bapa berbeza, umur kahwin) hanya MEMBENDERA melalui `validateGraph`.

### D-015 · Cucu melalui anak lelaki: satu peringkat dalam MVP
`HeirExtractor` mengambil `sonsSon`/`sonsDaughter` daripada anak lelaki si mati
(hidup atau mati). Peringkat lebih dalam (cicit) belum diproses — akan dibendera
apabila diperlukan. Cukup untuk kes lazim (anak lelaki mati, cucu mewarisi).

---

## 2026-09-03 — Fasa 3 (asas, belum lengkap DoD)

### D-016 · Storan: JSON fail dulu, Drift/SQLite kemudian
`InMemoryFamilyRepository` menyimpan graf sebagai satu fail JSON melalui
`path_provider` — memenuhi "data kekal selepas app ditutup" (SPEC Fasa 3 DoD)
tanpa perlukan `sqlite3` native + `build_runner`. Migrasi ke Drift (guna
`familyGraphSchemaSql`) dijadualkan selepas APK pertama. Antara muka
`FamilyRepository` abstrak supaya penukaran tidak menyentuh UI.

### D-017 · Susun atur graf: band generasi, bukan force-directed penuh
`FamilyGraphView` guna `CustomPainter` + `InteractiveViewer` (SPEC 3.3) dengan
BFS generasi dan garisan penyambung ibu bapa–anak. Penolakan berulang untuk
pertindihan mendatar (SPEC 3.3 langkah 4) dan unit pasangan bersebelahan penuh
BELUM dilaksanakan — mencukupi untuk rangkaian kecil, perlu diperhalusi.

### D-018 · Riverpod 3: `StateProvider` dari `legacy.dart`
Riverpod 3 memindahkan `StateProvider` ke `package:flutter_riverpod/legacy.dart`.
Repo memancarkan instance `FamilyGraph` BAHARU setiap perubahan kerana Riverpod
menyahduplikasi `AsyncData` yang `==`.

### D-019 · l10n: ARB + gen-l10n disediakan; migrasi rentetan berterusan
`lib/l10n/app_ms.arb` + `app_en.arb`, kelas `L`, BM lalai (SPEC 3.8). Banyak
rentetan UI masih inline — akan dipindahkan ke ARB secara berperingkat.

### Status DoD Fasa 3 (BELUM lengkap — perlu peranti sebenar & lelaran visual)
- ✅ Data kekal selepas app ditutup (JSON)
- ✅ Aliran Tap → Connect → bottom sheet → tambah orang + cadangan pintar
- ✅ 5 ujian widget (mula, bottom sheet, tambah orang, kad profil, cadangan)
- ⚠️ Render graf: asas sahaja (D-017)
- ⚠️ Mod fokus: tetapan orang fokus ada; had 3-generasi belum
- ⚠️ Mod gelap: tema ditakrif, belum disahkan visual pada peranti
- ⛔ Belum dijalankan pada emulator/peranti sebenar (perlu tindakan pemilik)
- ⛔ Ujian sesi 30 minit tanpa ranap — belum
