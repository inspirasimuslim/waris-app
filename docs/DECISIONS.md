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

### D-020 · Fasa 4: aliran simulasi + "Kenapa?" templat tetap
`SimulationFlow`: intro → skrin waris (dikenal pasti + tidak mewarisi + sebab)
→ input harta (boleh dilangkau, aset kasar vs bersih, wasiat/hibah TIDAK
ditolak automatik) → skrin keputusan (pecahan + jumlah + asal masalah + tashih).
"Kenapa?" dijana daripada `reasonCode` trace melalui templat TETAP
(`why_templates.dart`) — bukan AI (SPEC 4.5). Penafian SPEC 4.7 pada setiap
skrin keputusan (`_DisclaimerFooter`). Kes `requiresManualReview` dipaparkan
sebagai sepanduk amaran, angka tidak disembunyikan tetapi dilabel perlu semakan.

### D-021 · Snapshot disimpan sebagai graf beku; keputusan dijana semula
Fail JSON menyimpan `graph` + `simulations[]`. Setiap simulasi menyimpan graf
beku penuh; `SimulationSnapshot.fromJson` menjalankan semula enjin ke atas graf
beku itu (deterministik → keputusan sama) daripada menserialisasi `FaraidResult`
penuh. Menjamin immutability (SPEC 2.7) tanpa `FaraidResult.fromJson`.

### Status DoD Fasa 4
- ✅ Simulasi hujung ke hujung dari kad profil
- ✅ Snapshot immutable disimpan
- ✅ Waris terdinding + sebab dipaparkan
- ✅ Input harta berfungsi & boleh dilangkau
- ✅ "Kenapa?" untuk semua reasonCode MVP (templat tetap)
- ✅ Sejarah simulasi
- ✅ Penafian pada setiap skrin keputusan
- ✅ Ujian e2e: bina keluarga → simulasi → angka padan FRD-106; kes luar skop dibendera
- ⚠️ Donut chart keputusan belum (senarai kad sahaja)

---

## 2026-09-03 — Fasa 5 (APK)

### D-022 · Keystore UJIAN dijana; BUKAN untuk Play Store
Atas persetujuan pemilik, `app/waris-release.jks` dijana (`keytool`, RSA 2048,
alias `waris`, kata laluan `warisTest2026`) untuk menghasilkan APK boleh-pasang
bagi ujian dalaman. `key.properties` + `.jks` dalam `.gitignore`. Sebelum
keluaran awam, pemilik MESTI jana keystore rasmi dan sandarkan di dua lokasi
(SPEC 5.2). `build.gradle.kts` guna signingConfig `release` bila `key.properties`
wujud, jika tidak jatuh balik ke debug supaya `flutter run --release` berfungsi.

### D-023 · applicationId & namespace = `my.sakuradigital.waris`
Ditukar daripada `my.sakuradigital.waris_app` yang dijana `flutter create`
(SPEC 5.1, jawapan pemilik: kekal nama WARIS). MainActivity dipindahkan ke
pakej `my.sakuradigital.waris`.

### D-024 · minSdk & targetSdk ikut lantai Flutter 3.47
SPEC 5.1 menetapkan `minSdk 23` / `targetSdk 35`. Flutter 3.47 (+ AGP 9.1)
menguatkuasakan lantai `minSdk`/`compileSdk`/`targetSdk` yang lebih tinggi;
`build.gradle.kts` guna `flutter.minSdkVersion` / `flutter.targetSdkVersion`.
Liputan peranti kekal >98%; penyulitan + biometrik disokong sepenuhnya.
`isMinifyEnabled` + `isShrinkResources` + proguard-rules.pro dihidupkan (SPEC 5.3).

### D-026 · Bottom sheet dua-peringkat mesti dalam SATU sheet
Ranap dilaporkan pada peranti (`flutter run --release`): pilih jenis hubungan →
`Null check operator used on a null value` di `MediaQuery.of` dalam
`_showAddPerson`. Punca: `showModalBottomSheet` bersarang dipanggil dengan
`context` daripada sheet yang sudah di-`pop`. Peraturan seterusnya: JANGAN
pop satu sheet kemudian buka sheet baharu dengan `context` yang sama; sama ada
tukar kandungan dalam satu sheet (dilakukan untuk connect_sheet), atau tangkap
`Navigator` sebelum `pop` dan guna `navigator.context` (dilakukan untuk
profile_card). Ujian regresi dalam `widget_test.dart` guna `tester.takeException()`.

### D-025 · Ikon & splash berjenama ditangguh
`flutter_launcher_icons` / `flutter_native_splash` (SPEC 5.6) memerlukan fail
seni ikon 1024×1024 yang belum wujud. APK pertama guna ikon Flutter lalai.
Tindakan: pemilik sediakan seni ikon; kemudian jana untuk semua ketumpatan.

---

## Status DoD Fasa 3 (BELUM lengkap — perlu peranti sebenar & lelaran visual)
- ✅ Data kekal selepas app ditutup (JSON)
- ✅ Aliran Tap → Connect → bottom sheet → tambah orang + cadangan pintar
- ✅ 5 ujian widget (mula, bottom sheet, tambah orang, kad profil, cadangan)
- ⚠️ Render graf: asas sahaja (D-017)
- ⚠️ Mod fokus: tetapan orang fokus ada; had 3-generasi belum
- ⚠️ Mod gelap: tema ditakrif, belum disahkan visual pada peranti
- ⛔ Belum dijalankan pada emulator/peranti sebenar (perlu tindakan pemilik)
- ⛔ Ujian sesi 30 minit tanpa ranap — belum
