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
