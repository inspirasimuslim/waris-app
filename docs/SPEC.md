# WARIS — Spesifikasi Pembangunan Lengkap

**Versi:** 1.0
**Tarikh:** 2 September 2026
**Status:** Baseline pembangunan
**Sasaran akhir fasa ini:** APK yang boleh dipasang dan digunakan

---

## Cara guna dokumen ini

Dokumen ini ditulis untuk dibaca oleh manusia **dan** oleh Claude Code. Setiap fasa mempunyai:

- **Objektif** — apa yang wujud selepas fasa ini siap
- **Tugasan** — langkah konkrit
- **Definition of Done** — syarat untuk teruskan ke fasa seterusnya

Jangan lompat fasa. Fasa 1 (enjin faraid) mesti siap dan lulus ujian sebelum sebarang UI dibina. Sebab kalau enjin salah, semua yang cantik di atasnya tidak bermakna.

---

# BAHAGIAN A — ASAS PRODUK

## A1. Apa itu WARIS

WARIS bukan kalkulator faraid. WARIS ialah **Digital Family Network** untuk keluarga Muslim, dan faraid hanyalah salah satu enjin yang duduk di atas rangkaian tersebut.

Pengguna memasukkan struktur keluarga **sekali sahaja**. Selepas itu mereka boleh memanggil apa-apa fungsi daripada rangkaian yang sama:

- Siapa waris saya jika saya meninggal hari ini?
- Siapa waris ayah saya jika beliau meninggal?
- Siapa calon wali nikah untuk anak perempuan saya?
- Siapa mahram saya?
- Berapa anggaran harta pusaka bersih?

**Tagline:** *Kenali keluarga. Fahami hak. Pelihara warisan.*

## A2. Kenapa positioning ini

Pasaran kalkulator faraid sudah sesak — iFaraid, Faraid Learn & Calculator, Islamic Inheritance, e-Faraid MAIS (percuma), kalkulator rasmi MyGovernment (percuma), Faraid360 CIMB. Bertanding sebagai "kalkulator faraid yang lebih cantik" adalah kalah sebelum mula.

Yang belum ada sebagai produk consumer matang:

> **Rangkaian keluarga digital yang kekal + pilih mana-mana ahli + simulasi kematian + pengesanan waris automatik + enjin faraid + enjin wali**

Soalan sebenar pengguna bukan *"berapa RM saya dapat"* tetapi *"siapa sebenarnya waris saya"*.

## A3. Prinsip terkunci

Perkara berikut sudah diputuskan dan **tidak dibuka semula** tanpa sebab kuat:

| # | Prinsip |
|---|---|
| 1 | Pengguna mula dengan **satu individu**. Tiada borang panjang. |
| 2 | Semua penambahan melalui **Tap → Connect → pilih hubungan** |
| 3 | Family Network ialah **homepage**, bukan dashboard penuh kad |
| 4 | Pengguna masukkan hubungan **langsung** sahaja; sistem *derive* yang selebihnya |
| 5 | **Hubungan keluarga ≠ nasab ≠ waris ≠ wali ≠ mahram** — lapisan berasingan |
| 6 | Nasab mempunyai status tersendiri, private by default |
| 7 | Death Simulation guna **immutable snapshot** — database sebenar tidak berubah |
| 8 | Enjin faraid **deterministic rule-based**, bukan AI |
| 9 | Enjin wali guna ruleset berasingan daripada faraid |
| 10 | AI hanya lapisan **penerangan**, tidak pernah menentukan hukum atau angka |
| 11 | MVP = Malaysia / Syafie sahaja, tetapi ruleset tidak hard-coded |
| 12 | **Simple di depan, sophisticated di belakang** |
| 13 | Architecture modular — feature baru tidak merosakkan yang sedia ada |
| 14 | Privasi dibina dari awal, bukan ditampal kemudian |
| 15 | Monetisasi: **Free + Premium Lifetime**. Tiada langganan bulanan. |

## A4. Seni bina konsep

```
                  FAMILY NETWORK
                  (relationship graph)
                          │
                    NASAB ENGINE
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
  FARAID ENGINE     WALI ENGINE      MAHRAM ENGINE
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                  DEATH SIMULATION
                          │
                ┌─────────┼─────────┐
              WARIS     ESTATE    KENAPA?
```

Family Network bukan satu feature. Ia adalah **foundation**. Semua yang lain duduk di atasnya.

## A5. Stack teknologi

Sejajar dengan pengalaman sedia ada dan keperluan projek:

| Lapisan | Pilihan | Sebab |
|---|---|---|
| App | **Flutter** (Dart) | Satu codebase Android + iOS + web |
| State | **Riverpod** | Testable, tiada BuildContext dependency |
| DB tempatan | **Drift** (SQLite) | Offline-first; graf keluarga hidup di device |
| DB cloud | **Supabase** (Postgres + Auth + Storage + RLS) | Dah biasa; RLS penting untuk data sensitif |
| Enjin faraid | **Pure Dart package** berasingan | Boleh diuji tanpa Flutter, tanpa DB, tanpa UI |
| Enjin wali/mahram | Pure Dart package berasingan | Sama |
| Graf UI | Custom `CustomPainter` + `InteractiveViewer` | Kawalan penuh; package graf sedia ada terlalu terhad |
| Pembayaran | **RevenueCat** atau Google Play Billing terus | Lifetime = non-consumable IAP |
| Push | Firebase Cloud Messaging | Fasa lewat sahaja |
| Build iOS | **Codemagic** | Build cloud tanpa Mac |
| Crash/analytics | Sentry + Posthog (self-host optional) | Elak Firebase Analytics untuk data sensitif |

**Keputusan penting:** WARIS ialah **local-first**. Graf keluarga hidup dalam SQLite di device dan berfungsi sepenuhnya tanpa internet. Supabase hanya untuk backup, sync dan kolaborasi. Ini bukan sekadar prestasi — ia mengurangkan permukaan risiko privasi dengan ketara, dan membolehkan Free tier berfungsi tanpa akaun langsung.

---

# BAHAGIAN B — FASA PEMBANGUNAN

Ada 9 fasa. Fasa 0–5 menghasilkan APK yang boleh dipasang. Fasa 6–8 adalah pengembangan selepas APK pertama.

```
FASA 0  Persediaan & tadbir urus
FASA 1  Enjin faraid (pure Dart) + test suite        ← paling kritikal
FASA 2  Model data & graf keluarga
FASA 3  Aplikasi Flutter: Family Network UI
FASA 4  Death Simulation + integrasi enjin
FASA 5  Build APK pertama                             ← milestone
FASA 6  Enjin wali + nasab + mahram
FASA 7  Estate, dokumen, laporan PDF
FASA 8  Cloud sync, kolaborasi, monetisasi, Play Store
```

---

## FASA 0 — Persediaan & Tadbir Urus

**Objektif:** Semua halangan bukan-kod diselesaikan sebelum satu baris kod ditulis.

### 0.1 Version control — WAJIB, tiada pengecualian

Sekarang tiada version control pada mana-mana projek. Untuk WARIS ini tidak boleh diteruskan, sebab enjin faraid akan melalui puluhan lelaran dan kau perlu boleh patah balik.

```bash
git init
git branch -M main
# Repo PRIVATE di GitHub
```

Struktur cawangan:

```
main        — kod yang boleh dibina, sentiasa hijau
develop     — integrasi
feature/*   — kerja harian
```

Tag setiap milestone: `v0.1.0-engine`, `v0.2.0-graph`, `v0.3.0-apk`.

`.gitignore` mesti merangkumi: `*.env`, `*.keystore`, `*.jks`, `key.properties`, `google-services.json`, `**/secrets/`.

> **Peringatan keras:** Jangan sekali-kali commit keystore atau kunci Supabase service_role ke repo, walaupun repo private.

### 0.2 Semakan nama

Sebelum melekat pada nama "WARIS":

1. Carian cap dagangan di MyIPO (kelas 9 — perisian, kelas 42 — perkhidmatan IT)
2. Carian App Store + Google Play untuk "waris"
3. Semakan domain: `waris.app`, `warisapp.my`, `appwaris.com`
4. Semakan pendaftaran syarikat SSM

**Nama sandaran jika bertindih:** WarisKu, Salasilah, NasabKu, Warisan, MyWaris.

Sampai semakan selesai, guna package id sementara `my.sakuradigital.waris` — ia mudah ditukar sebelum keluaran pertama, sangat menyakitkan selepas.

### 0.3 Penasihat Syariah

Ini bukan pilihan. App yang menyentuh faraid dan wali tanpa semakan orang berkelayakan adalah risiko sebenar, bukan risiko teori.

Yang diperlukan:

| Peranan | Untuk | Bila |
|---|---|---|
| Pakar faraid | Sahkan ruleset + 120 kes ujian | Sebelum Fasa 1 tamat |
| Pegawai/penasihat Syariah | Modul wali dan nasab | Sebelum Fasa 6 |
| Semakan prosedur perundangan | Kata-kata penafian, rujukan Mahkamah Syariah | Sebelum keluaran awam |

Ke mana hendak pergi: Jabatan Mufti Negeri Terengganu, Fakulti Syariah UniSZA (dekat dengan kau di Kuala Terengganu), YADIM, atau perunding pusaka swasta.

**Sebelum penasihat disahkan:** modul wali dibina tetapi dilabel sebagai **bahan pendidikan**, bukan penentuan. Lihat Fasa 6.

### 0.4 Persekitaran pembangunan

```bash
flutter doctor -v          # semua tanda ✓ kecuali Xcode (Windows)
flutter --version          # rekod versi dalam README
dart --version
```

Kunci versi Flutter dalam `.fvmrc` guna FVM supaya build tidak pecah bila Flutter naik versi.

### 0.5 Struktur repo

```
waris/
├── packages/
│   ├── faraid_engine/          # pure Dart, tiada Flutter
│   │   ├── lib/
│   │   └── test/
│   ├── wali_engine/            # pure Dart
│   ├── mahram_engine/          # pure Dart
│   └── family_graph/           # pure Dart — model graf & resolver
├── app/                        # aplikasi Flutter
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── features/
│   │   └── main.dart
│   └── test/
├── docs/
│   ├── SPEC.md                 # dokumen ini
│   ├── FARAID_RULES.md
│   ├── TEST_CASES.md
│   └── DECISIONS.md            # log keputusan seni bina
└── melos.yaml                  # pengurusan monorepo
```

Guna **Melos** untuk urus monorepo. Enjin sebagai package berasingan bukan hiasan — ia memaksa enjin kekal bebas daripada UI dan boleh diuji dalam milisaat.

### Definition of Done — Fasa 0

- [ ] Repo git private wujud, `.gitignore` betul
- [ ] Semakan nama selesai, nama muktamad diputuskan
- [ ] Sekurang-kurangnya satu penasihat faraid bersetuju untuk semak
- [ ] `flutter doctor -v` bersih
- [ ] Struktur monorepo Melos berjalan, `melos bootstrap` berjaya

---

## FASA 1 — Enjin Faraid

**Objektif:** Package Dart tulen yang menerima struktur keluarga dan mengembalikan pembahagian faraid yang betul, disokong 120+ kes ujian.

**Ini fasa paling kritikal dalam keseluruhan projek.** Jangan tulis satu baris UI sehingga fasa ini lulus.

### 1.1 Kenapa pure Dart, bukan dalam app

- Boleh diuji dalam milisaat, tanpa emulator
- Boleh diserahkan kepada penasihat Syariah sebagai artifak berasingan untuk semakan
- Boleh diguna semula: web, backend, CLI
- Memaksa pemisahan bersih antara hukum dan paparan

### 1.2 Antara muka awam

```dart
// packages/faraid_engine/lib/faraid_engine.dart

class FaraidInput {
  final Ruleset ruleset;              // Malaysia/Syafie v1
  final Gender deceasedGender;
  final Money netEstate;              // harta pusaka BERSIH
  final List<HeirClaim> claims;       // waris yang hidup + kiraan
}

class HeirClaim {
  final HeirType type;                // enum, lihat 1.3
  final int count;                    // cth. 3 anak lelaki
  final bool nasabConfirmed;          // dari Nasab Engine
}

class FaraidResult {
  final Money netEstate;
  final List<HeirShare> shares;
  final List<BlockedHeir> blocked;    // + sebab
  final CalculationTrace trace;       // setiap langkah, untuk audit
  final List<Warning> warnings;
  final String rulesetVersion;
}

class HeirShare {
  final HeirType type;
  final int count;
  final Fraction shareEach;           // pecahan tepat, BUKAN double
  final Fraction shareTotal;
  final Money amountEach;
  final ShareBasis basis;             // fardu / asabah / radd / aul
  final String reasonCode;            // kunci untuk teks penerangan
}
```

**Peraturan besi:** Semua aritmetik pecahan guna integer `Fraction` (pengangka/penyebut dengan BigInt), **tidak pernah** `double`. Faraid melibatkan penyebut seperti 24, 27, 72 dan ralat titik terapung akan menghasilkan pembahagian yang salah. Guna package `fraction` atau tulis sendiri — tulis sendiri lebih selamat.

### 1.3 Senarai jenis waris

Enum mesti lengkap dari awal walaupun tidak semua dilaksanakan dalam MVP:

```
Ashab al-Furud (waris berbahagian tetap):
  husband, wife
  father, mother
  daughter, sonsDaughter
  fullSister, paternalSister, maternalSibling
  paternalGrandfather, maternalGrandmother, paternalGrandmother

Asabah (waris baki):
  son, sonsSon
  fullBrother, paternalBrother
  fullBrothersSon, paternalBrothersSon
  fullPaternalUncle, paternalUncle
  fullPaternalUnclesSon, paternalUnclesSon
```

Setiap satu perlu darjah: `sonsSon` boleh sampai beberapa peringkat ke bawah, `paternalGrandfather` beberapa peringkat ke atas.

### 1.4 Aliran pengiraan

```
FaraidInput
    ↓
1. Validation          — input munasabah? jantina konsisten?
    ↓
2. Nasab Filter        — buang waris yang nasabnya tidak sabit
    ↓
3. Hajb Engine         — tentukan siapa terdinding (hirman & nuqsan)
    ↓
4. Furud Assignment    — berikan bahagian tetap
    ↓
5. Asabah Resolution   — tentukan asabah bi-nafsihi / bi-ghayrihi / ma'a-ghayrihi
    ↓
6. Aul / Radd          — laraskan jika jumlah > 1 atau < 1
    ↓
7. Tashih              — cari asal masalah supaya semua bahagian integer
    ↓
8. Special Cases       — umariyyatain, musyarakah, akdariyyah, jadd wal-ikhwah
    ↓
9. Money Distribution  — agih harta bersih
    ↓
10. Trace & Validate   — jumlah = 100%? setiap langkah direkod?
    ↓
FaraidResult
```

### 1.5 Skop MVP vs kemudian

| Ciri | MVP (Fasa 1) | Kemudian |
|---|:---:|:---:|
| Fardu asas | ✅ | |
| Asabah bi-nafsihi | ✅ | |
| Asabah bi-ghayrihi | ✅ | |
| Asabah ma'a-ghayrihi | ✅ | |
| Hajb hirman & nuqsan | ✅ | |
| Aul | ✅ | |
| Radd | ✅ | |
| Tashih | ✅ | |
| Umariyyatain | ✅ | |
| Datuk bersama adik-beradik | ✅ | |
| Akdariyyah | ✅ | |
| Musyarakah | | ✅ |
| Munasakhat | | ✅ |
| Takharuj | | ✅ |
| Zawil arham | | ✅ |
| Mafqud (waris hilang) | | ✅ |
| Hamlun (kandungan dalam rahim) | | ✅ |
| Khunsa | | ✅ |
| Mazhab selain Syafie | | ✅ |

Yang di lajur "Kemudian" mesti **dikesan dan dibendera**, bukan dikira salah. Kalau input mengandungi keadaan di luar skop, enjin mengembalikan `warnings` dan status `requiresManualReview` — jangan sekali-kali teka.

### 1.6 Test suite

Ini yang membezakan enjin yang boleh dipercayai daripada yang "nampak macam betul".

```
packages/faraid_engine/test/
├── cases/
│   ├── basic_001_to_030.yaml       # kes asas
│   ├── hajb_031_to_060.yaml        # pendindingan
│   ├── aul_061_to_080.yaml
│   ├── radd_081_to_095.yaml
│   ├── tashih_096_to_105.yaml
│   ├── special_106_to_120.yaml     # umariyyatain, akdariyyah, datuk
│   └── nasab_121_to_130.yaml       # nasab tidak sabit
└── engine_test.dart
```

Format setiap kes:

```yaml
- id: FRD-047
  name: "Suami + ibu + bapa (Umariyyatain)"
  source: "Kitab al-Faraid, bab umariyyatain"
  verified_by: "pending"
  input:
    deceased_gender: female
    net_estate: 120000
    heirs:
      - { type: husband, count: 1 }
      - { type: mother, count: 1 }
      - { type: father, count: 1 }
  expected:
    asal_masalah: 6
    shares:
      - { type: husband, fraction: "1/2", amount: 60000, basis: fardu }
      - { type: mother,  fraction: "1/6", amount: 20000, basis: fardu, note: "1/3 daripada baki" }
      - { type: father,  fraction: "1/3", amount: 40000, basis: asabah }
```

**Prosedur:**

1. Tulis 120 kes daripada kitab faraid muktabar dan contoh rasmi e-Faraid
2. Setiap kes ada medan `source` — dari mana ia diambil
3. Setiap kes ada medan `verified_by` — kosong sehingga penasihat sahkan
4. Enjin tidak boleh ditandakan siap sehingga **100% lulus**
5. Jalankan silang-semak: masukkan 20 kes rawak ke dalam e-Faraid MAIS dan bandingkan output

> **Idea:** Bina CLI kecil `dart run faraid_engine:check case.yaml` supaya penasihat Syariah boleh semak enjin tanpa perlu buka app langsung. Ini menurunkan halangan untuk mereka membantu dengan besar.

### 1.7 Trace — ciri yang orang lain tak ada

Setiap keputusan direkodkan:

```dart
CalculationTrace(steps: [
  TraceStep("hajb", "Saudara lelaki seibu-sebapa terdinding oleh anak lelaki",
            affected: [fullBrother]),
  TraceStep("furud", "Isteri diberikan 1/8 kerana si mati mempunyai anak",
            affected: [wife], fraction: Fraction(1,8)),
  TraceStep("asabah", "Baki 7/8 diagihkan kepada anak, lelaki 2 : perempuan 1"),
  TraceStep("tashih", "Asal masalah 8 dinaikkan kepada 24 supaya bahagian menjadi integer"),
])
```

Trace inilah yang menjadi sumber untuk butang **"Kenapa?"** dalam UI, dan ia datang daripada enjin, bukan daripada AI. AI hanya menukar trace kepada ayat Bahasa Melayu yang mesra.

### Definition of Done — Fasa 1

- [ ] Package `faraid_engine` berdiri sendiri, tiada kebergantungan Flutter
- [ ] 120+ kes ujian ditulis dengan `source` didokumenkan
- [ ] 100% kes lulus
- [ ] Semua aritmetik guna `Fraction`, tiada `double` dalam laluan pengiraan
- [ ] Trace dihasilkan untuk setiap pengiraan
- [ ] Keadaan di luar skop dibendera, bukan diteka
- [ ] CLI semakan berfungsi
- [ ] Sekurang-kurangnya 20 kes disilang-semak dengan e-Faraid
- [ ] Tag `v0.1.0-engine`

---

## FASA 2 — Model Data & Graf Keluarga

**Objektif:** Package `family_graph` yang menyimpan hubungan, menerbitkan hubungan tidak langsung, dan mengeluarkan senarai waris untuk enjin faraid.

### 2.1 Prinsip model data

Simpan **hubungan langsung sahaja**. Terbitkan yang selebihnya.

```
Disimpan:          Diterbitkan:
  father             sibling, half-sibling
  mother             grandparent (semua peringkat)
  spouse             grandchild
                     uncle, aunt, nephew, niece, cousin
                     laluan paternal vs maternal
```

Sebabnya bukan penjimatan storan — ia mengelakkan data bercanggah. Kalau kau simpan "abang" sebagai fakta berasingan, seseorang boleh memadamkan bapa dan tinggalkan hubungan abang yang menggantung tanpa asas.

### 2.2 Skema teras

```dart
class Person {
  String id;                 // UUID
  String familyId;
  String name;
  String? fullName;
  Gender gender;             // male | female
  DateTime? birthDate;
  LifeStatus status;         // alive | deceased | unknown
  DateTime? deathDate;
  String? photoPath;
  String? notes;
  bool isSelf;               // penanda "saya"
}

class ParentLink {
  String id;
  String childId;
  String parentId;
  ParentRole role;           // father | mother
  NasabStatus nasabStatus;   // lihat 2.3
  LinkKind kind;             // biological | adoptive | step
  bool isPrivate;            // default true untuk nasab sensitif
}

class SpouseLink {
  String id;
  String personAId;
  String personBId;
  MarriageStatus status;     // married | divorced | widowed
  DateTime? marriageDate;
  DateTime? endDate;
  int? order;                // untuk poligami: isteri pertama, kedua...
}
```

**Perhatikan:** `ParentLink` berasingan untuk bapa dan ibu. Ini membolehkan sistem mewakili "ibu disahkan, bapa tidak sabit" tanpa memaksa pengguna berbohong atau memadam sesiapa.

### 2.3 Lapisan Nasab

Ini yang membezakan WARIS daripada mana-mana app family tree biasa.

```dart
enum NasabStatus {
  confirmed,              // 🟢 nasab sabit
  unknown,                // 🟡 pengguna tidak pasti
  notEstablished,         // 🟠 nasab tidak sabit
  disputed,               // 🔴 ada percanggahan
  requiresAuthorityReview // ⚠️ perlu semakan pihak berautoriti
}
```

**Peraturan UI yang tidak boleh dilanggar:**

| Jangan tulis | Tulis |
|---|---|
| ❌ "Anak luar nikah" | ✅ "Nasab bapa: tidak disahkan" |
| ❌ "Anak haram" | ✅ "Status nasab: perlu semakan" |
| ❌ Label merah menyerlah | ✅ Penanda neutral, kelabu |

App **tidak** mengesan status nasab secara automatik daripada tarikh lahir berbanding tarikh nikah. Ia hanya boleh membendera *"maklumat ini mungkin memerlukan semakan"* dan berhenti di situ. Penentuan nasab melibatkan undang-undang negeri dan fakta yang app tidak tahu.

Semua medan nasab `isPrivate = true` secara lalai. Ahli keluarga lain yang dijemput hanya nampak "Ali — ahli keluarga", bukan status nasabnya.

### 2.4 Relationship Resolver

```dart
abstract class RelationshipResolver {
  List<Person> fathersOf(String personId, {int degree = 1});
  List<Person> childrenOf(String personId, {NasabStatus? minStatus});
  List<Person> siblingsOf(String personId, SiblingKind kind);
  // kind: full | paternal | maternal
  List<Person> ancestorsPaternal(String personId);
  List<Person> descendantsMale(String personId);
  RelationshipLabel describe(String fromId, String toId);
  // "Rahman ialah bapa saudara sebelah bapa kepada Ali"
}
```

### 2.5 Heir Extractor — jambatan ke enjin faraid

Ini komponen yang menukar graf kepada `FaraidInput`:

```dart
FaraidInput extractHeirs({
  required String deceasedId,
  required FamilyGraph graph,
  required DateTime simulationDate,
  required Ruleset ruleset,
});
```

Logiknya:

1. Ambil semua orang dalam graf
2. Tapis kepada yang **hidup pada tarikh simulasi**
3. Untuk setiap seorang, tentukan hubungan faraid kepada si mati
4. **Guna lapisan nasab, bukan lapisan hubungan keluarga** — anak yang nasabnya tidak sabit kepada si mati tidak dimasukkan sebagai anak
5. Kumpulkan mengikut `HeirType` dan kira bilangan
6. Bendera apa-apa yang tidak dapat ditentukan

> **Ini titik di mana kebanyakan app tersilap.** Mereka menganggap garisan dalam family tree = nasab faraid. WARIS memisahkannya, dan itulah sebabnya kes anak angkat, anak tiri dan nasab tidak sabit boleh dikendalikan dengan betul.

### 2.6 Storan tempatan (Drift / SQLite)

```sql
CREATE TABLE persons (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  name TEXT NOT NULL,
  full_name TEXT,
  gender TEXT NOT NULL,
  birth_date INTEGER,
  status TEXT NOT NULL DEFAULT 'alive',
  death_date INTEGER,
  photo_path TEXT,
  notes TEXT,
  is_self INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE parent_links (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES persons(id),
  parent_id TEXT NOT NULL REFERENCES persons(id),
  role TEXT NOT NULL,
  nasab_status TEXT NOT NULL DEFAULT 'confirmed',
  kind TEXT NOT NULL DEFAULT 'biological',
  is_private INTEGER DEFAULT 1,
  UNIQUE(child_id, role, parent_id)
);

CREATE TABLE spouse_links (
  id TEXT PRIMARY KEY,
  person_a_id TEXT NOT NULL REFERENCES persons(id),
  person_b_id TEXT NOT NULL REFERENCES persons(id),
  status TEXT NOT NULL,
  marriage_date INTEGER,
  end_date INTEGER,
  marriage_order INTEGER
);

CREATE TABLE simulations (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  deceased_id TEXT NOT NULL,
  simulation_date INTEGER NOT NULL,
  snapshot_json TEXT NOT NULL,      -- immutable
  result_json TEXT NOT NULL,
  ruleset_version TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
```

**Guna soft delete** (`deleted_at`) di mana-mana. Memadam seseorang daripada family tree secara kekal boleh merosakkan simulasi lama secara senyap.

### 2.7 Immutable snapshot

Bila pengguna menjalankan simulasi, sistem menyalin keadaan keluarga penuh ke dalam `snapshot_json` dan mengira daripada salinan itu.

Kesannya: pengguna simulasi Ahmad hari ini, tambah cucu baru bulan depan, dan simulasi lama **tidak berubah**. Setiap simulasi adalah rekod sejarah yang boleh dirujuk balik.

### 2.8 Pengesanan pertindihan

Bila pengguna menambah "Abdullah" dan sudah ada "Abdullah" dalam graf:

```
Kemungkinan orang yang sama

👴 Abdullah
   Bapa kepada Ahmad · 72 tahun

[ Guna yang sedia ada ]   [ Cipta baharu ]
```

**Tidak pernah gabung secara automatik.** Dua orang boleh berkongsi nama. Cadangkan sahaja.

Padanan berdasarkan: kesamaan nama (Levenshtein) + jantina sepadan + tarikh lahir munasabah + kedekatan dalam graf.

### 2.9 Pengesahan data

Sistem membendera keadaan yang tidak munasabah tanpa menghalang pengguna:

| Semakan | Mesej |
|---|---|
| Anak lahir selepas kematian bapa > 9 bulan | ⚠️ Tarikh mungkin perlu disemak |
| Anak lebih tua daripada ibu bapa | ⚠️ Maklumat mungkin tidak konsisten |
| Kitaran dalam graf (A bapa kepada B, B bapa kepada A) | 🚫 Halang — mustahil |
| Dua bapa berbeza untuk seorang anak | ⚠️ Percanggahan nasab |
| Umur perkahwinan tidak munasabah | ⚠️ Semak tarikh |

Bendera, bukan halangan — kecuali kitaran graf yang mesti dihalang kerana ia akan menyebabkan resolver berulang tanpa henti.

### Definition of Done — Fasa 2

- [ ] Package `family_graph` berdiri sendiri
- [ ] Skema Drift dimigrasi dan diuji
- [ ] Resolver menerbitkan sibling, grandparent, uncle, cousin dengan betul
- [ ] `extractHeirs()` menghasilkan `FaraidInput` yang sah
- [ ] Lapisan nasab menapis waris dengan betul
- [ ] Snapshot immutable berfungsi
- [ ] 40+ ujian unit untuk resolver
- [ ] Ujian integrasi: graf → extractor → enjin → keputusan
- [ ] Tag `v0.2.0-graph`

---

## FASA 3 — Aplikasi Flutter: Family Network UI

**Objektif:** App yang boleh dipasang di mana pengguna boleh membina rangkaian keluarga secara visual. Belum ada simulasi.

### 3.1 Interaksi utama — "Start With One Person"

Skrin pertama selepas pemasangan:

```
┌────────────────────────────────┐
│                                │
│                                │
│              👤                │
│             Saya               │
│                                │
│                                │
│      Ketik untuk bermula       │
│                                │
└────────────────────────────────┘
```

Satu avatar. Tiada borang. Tiada menu.

Ketik avatar → bottom sheet muncul:

```
┌────────────────────────────────┐
│  Hubungkan seseorang           │
│                                │
│  ❤️  Pasangan                  │
│  👨  Bapa                      │
│  👩  Ibu                       │
│  👦  Anak lelaki               │
│  👧  Anak perempuan            │
│  👫  Adik-beradik              │
│                                │
│         Lagi...                │
└────────────────────────────────┘
```

Pilih → mini form (nama, jantina jika perlu, hidup/meninggal) → **Tambah** → nod baharu muncul dengan animasi, garisan hubungan tumbuh.

Ulang. Rangkaian membesar secara organik.

**Kenapa ini lebih baik daripada onboarding berbentuk borang:** pengguna tidak rasa dia mengisi pangkalan data. Dia rasa dia **melukis keluarganya**. Beban kognitif hampir sifar, dan setiap penambahan memberi ganjaran visual segera.

### 3.2 Medan minimum

| Wajib | Pilihan |
|---|---|
| Nama | Nama penuh |
| Jantina (auto jika hubungan menentukannya) | Tarikh lahir |
| Hidup / meninggal | Tarikh kematian |
| | Foto |
| | Nota |

Progressive disclosure: minta data tambahan **hanya bila pengguna cuba melakukan sesuatu yang memerlukannya**. Tarikh lahir hanya diminta bila ia mempengaruhi pengiraan.

### 3.3 Rendering graf

Guna `CustomPainter` di dalam `InteractiveViewer`. Jangan guna package graf sedia ada — keperluan susun atur keluarga (pasangan bersebelahan, adik-beradik berkongsi baris, berbilang perkahwinan) terlalu spesifik.

**Algoritma susun atur:**

1. Kumpulkan orang mengikut generasi (BFS dari orang fokus)
2. Dalam setiap generasi, letakkan unit pasangan bersebelahan
3. Pusatkan ibu bapa di atas titik tengah anak-anak
4. Selesaikan pertindihan mendatar dengan penolakan berulang
5. Cache susun atur; kira semula hanya bila graf berubah

**Gerak isyarat:**

| Gerakan | Kesan |
|---|---|
| Ketik nod | Kad profil |
| Ketik dua kali | Fokus pada orang itu |
| Tekan lama | Menu tindakan pantas |
| Cubit | Zum |
| Seret | Pan |
| Ketik garisan | Maklumat hubungan |

### 3.4 Mod Fokus — wajib

Keluarga 150 orang akan menjadi kekusutan yang tidak boleh dibaca. Lalai kepada mod fokus:

```
Fokus: Ahmad

    Datuk & Nenek
          ↓
      Ibu bapa
          ↓
   AHMAD ─ Aisyah
          ↓
      Anak-anak
```

Hanya 3 generasi kelihatan pada satu masa. Butang "Kembangkan" untuk pergi lebih jauh. Butang "Lihat semua" untuk paparan penuh dengan amaran bahawa ia mungkin padat.

### 3.5 Kad profil

```
┌───────────────────────────┐
│           👨              │
│         Ahmad             │
│        42 tahun           │
│         🟢 Hidup          │
│                           │
│  Bapa      Abdullah       │
│  Ibu       Aminah         │
│  Isteri    Aisyah         │
│  Anak      3              │
│                           │
│  ＋ Hubungkan             │
│  ✏️ Sunting               │
│                           │
│  ⚖️ Simulasi kematian     │   ← Fasa 4
│  👰 Semak wali            │   ← Fasa 6 (perempuan sahaja)
└───────────────────────────┘
```

Tindakan bersifat kontekstual — muncul berdasarkan siapa yang dipilih, bukan bersembunyi dalam menu.

### 3.6 Cadangan pintar

Selepas setiap penambahan, cadangkan langkah seterusnya tanpa memaksa:

- Selepas tambah pasangan → 💡 *Tambah anak?*
- Selepas tambah anak → 💡 *Tambah datuk nenek mereka?*
- Selepas tambah bapa → 💡 *Tambah ibu bapa kepada bapa?*
- Selepas 10 ahli → 💡 *Rangkaian keluarga anda dah mula terbentuk*

Sentiasa ada **Langkau**. Ini cadangan, bukan tugasan.

### 3.7 Arah reka bentuk

**Bukan** klise app Islamik: corak masjid, bulan sabit di setiap skrin, emas di mana-mana, kecerunan hijau, tipografi Arab yang berat.

**Sebaliknya:** Premium Calm — dekat dengan app perbankan moden dan app kesihatan moden, dengan identiti Islam yang halus.

| Elemen | Nilai |
|---|---|
| Latar (terang) | `#FAF9F6` off-white suam |
| Latar (gelap) | `#12130F` hampir hitam |
| Aksen utama | `#0F5132` emerald pekat |
| Sekunder | `#8FA68E` sage lembut |
| Sorotan | `#D4B896` pasir suam |
| Bahaya | `#A94442` merah tenang |
| Jaya | `#5A8A6B` hijau lembut |
| Radius kad | 20–28px |
| Fon | Inter / Plus Jakarta Sans |
| Fon Arab | Noto Naskh Arabic |

Bottom sheet untuk hampir semua tindakan. Sasaran sentuh besar. Animasi 200–300ms, memudahkan kefahaman dan bukan hiasan.

**Sokong mod gelap dari hari pertama.** App ini akan dibuka dalam keadaan emosi yang berat — selepas kematian, lewat malam. Mod gelap bukan kemewahan.

### 3.8 Bahasa

- **Bahasa Melayu sebagai lalai**, English sebagai pilihan kedua
- Semua string dalam fail ARB (`flutter_localizations`) dari awal — jangan hard-code
- Istilah teknikal faraid kekal dalam bentuk asal (`asabah`, `hajb`, `aul`, `radd`) dengan takrif yang boleh diketik
- Nada: hormat, tenang, tidak menghukum. App ini bercakap tentang kematian dan keluarga.

### Definition of Done — Fasa 3

- [ ] App berjalan pada emulator dan peranti sebenar
- [ ] Boleh membina rangkaian 30+ orang tanpa masalah
- [ ] Susun atur graf stabil dan boleh dibaca
- [ ] Mod fokus berfungsi
- [ ] Data kekal selepas app ditutup
- [ ] Mod gelap lengkap
- [ ] Semua string dilokalkan
- [ ] Tiada ranap dalam sesi 30 minit

---

## FASA 4 — Death Simulation

**Objektif:** Sambungkan graf keluarga kepada enjin faraid. Ini di mana produk menjadi hidup.

### 4.1 Aliran

```
Kad profil Ahmad
      ↓
[ ⚖️ Simulasi kematian ]
      ↓
"Jika Ahmad meninggal dunia hari ini..."
[ Teruskan ]
      ↓
Sistem cipta snapshot immutable
      ↓
Graf → Heir Extractor → Enjin Faraid
      ↓
Paparkan waris (dengan animasi berturutan)
      ↓
[ Masukkan nilai harta ]  ← boleh dilangkau
      ↓
Keputusan: bahagian + jumlah + Kenapa?
      ↓
Simpan ke sejarah simulasi
```

### 4.2 Skrin waris

```
Jika Ahmad meninggal hari ini

WARIS YANG DIKENAL PASTI

🟢 Isteri — Aisyah
🟢 Anak lelaki — Ali, Umar
🟢 Anak perempuan — Sara
🟢 Ibu — Aminah

TIDAK MEWARISI

🔴 Saudara lelaki — Rahman
   Terdinding oleh anak lelaki      [ Kenapa? ]

🔴 Saudara perempuan — Zainab
   Terdinding oleh anak lelaki      [ Kenapa? ]
```

Waris muncul satu per satu dengan sedikit jeda. Ini bukan gimik — ia membantu pengguna memproses maklumat yang secara emosi berat, dan menjadikan proses penapisan itu sendiri kelihatan.

### 4.3 Input harta

Boleh dilangkau sepenuhnya. Pengguna mungkin hanya mahu tahu *siapa*, bukan *berapa*.

```
HARTA PUSAKA

Jumlah aset kasar        RM 850,000

Tolakan:
  Pengurusan jenazah     RM  10,000
  Hutang                 RM  50,000
  Wasiat                 RM  30,000
  Tuntutan berkaitan     RM  20,000
  ─────────────────────────────────
Harta pusaka bersih      RM 740,000
```

**Penting:** app mesti membezakan **aset kasar** daripada **harta pusaka bersih**. Wasiat, hibah dan harta sepencarian **tidak** ditolak secara automatik dalam MVP — ia direkod sebagai item dengan status:

```
Wasiat            🟢 Ada  🟡 Tidak pasti  ⚪ Tiada
Hibah             🟢 Ada  🟡 Tidak pasti  ⚪ Tiada
Harta sepencarian 🟡 Perlu semakan
```

dengan nota: *"Item ini boleh mempengaruhi jumlah harta pusaka yang boleh dibahagikan. Sila dapatkan pengesahan profesional."*

Membuat andaian di sini adalah salah yang mahal.

### 4.4 Skrin keputusan

```
HARTA PUSAKA BERSIH
RM 740,000

        ◉  (donut chart)

┌──────────────────────────────┐
│ 🟢 Isteri — Aisyah           │
│    1/8                       │
│    RM 92,500                 │
│    [ Kenapa? ▼ ]             │
└──────────────────────────────┘

┌──────────────────────────────┐
│ 🟢 Anak lelaki — Ali         │
│    7/30                      │
│    RM 172,666.67             │
│    [ Kenapa? ▼ ]             │
└──────────────────────────────┘
...

Asal masalah: 24 → ditashih kepada 120
```

Tunjukkan **asal masalah** dan tashih. Ini menandakan kepada pengguna berpengetahuan bahawa enjin ini serius, dan menjadi bahan pendidikan untuk yang lain.

### 4.5 Enjin "Kenapa?"

Ketik "Kenapa?" → bottom sheet dengan penerangan yang **dijana daripada trace enjin**:

```
Kenapa isteri mendapat 1/8?

Isteri menerima 1/4 daripada harta pusaka apabila
si mati tidak mempunyai anak atau cucu.

Apabila si mati mempunyai anak — seperti dalam
kes ini — bahagian isteri berkurang kepada 1/8.

Ahmad mempunyai 3 orang anak, jadi Aisyah
menerima 1/8.

Rujukan: Ruleset Malaysia/Syafie v1.0
```

Untuk MVP, penerangan datang daripada **templat tetap** yang dipetakan kepada `reasonCode` dalam trace. AI ditambah kemudian dalam Fasa 8 sebagai lapisan pilihan, dan hanya menulis semula trace yang sudah disahkan.

> **AI tidak pernah menentukan angka. Tidak dalam MVP, tidak selamanya.**

### 4.6 Sejarah simulasi

```
SIMULASI SAYA

⚖️ Ahmad          2 Sep 2026
   5 waris · RM 740,000

⚖️ Aisyah         2 Sep 2026
   4 waris · RM 300,000

⚖️ Abdullah       28 Ogos 2026
   6 waris · tiada harta dimasukkan
```

Setiap satu boleh dibuka semula. Setiap satu adalah snapshot beku.

### 4.7 Penafian — di setiap skrin keputusan

Bukan pop-up yang boleh ditolak sekali dan hilang. Ia berada di kaki setiap keputusan:

> **WARIS menyediakan simulasi dan panduan berdasarkan maklumat yang anda masukkan. Ia bukan pengesahan rasmi waris, keputusan faraid, atau penentuan sah wali nikah. Untuk kes sebenar, sila dapatkan pengesahan daripada Mahkamah Syariah atau pihak berautoriti yang berkaitan.**

Ini bukan sekadar perlindungan undang-undang. Ia keputusan reka bentuk yang membina kepercayaan — app yang jujur tentang hadnya lebih dipercayai daripada app yang berlagak muktamad.

### Definition of Done — Fasa 4

- [ ] Simulasi berfungsi hujung ke hujung daripada kad profil
- [ ] Snapshot immutable disimpan dengan betul
- [ ] Waris yang terdinding dipaparkan dengan sebab
- [ ] Input harta berfungsi dan boleh dilangkau
- [ ] Penerangan "Kenapa?" untuk semua `reasonCode` MVP
- [ ] Sejarah simulasi berfungsi
- [ ] Penafian pada setiap skrin keputusan
- [ ] Ujian hujung ke hujung: bina keluarga → simulasi → sahkan angka terhadap kes ujian Fasa 1

---

## FASA 5 — APK Pertama

**Objektif:** Fail APK yang boleh ditandatangan, dipasang dan diedarkan.

### 5.1 Persediaan Android

`android/app/build.gradle`:

```gradle
android {
    namespace "my.sakuradigital.waris"
    compileSdk 35

    defaultConfig {
        applicationId "my.sakuradigital.waris"
        minSdk 23              // Android 6.0 — liputan ~99%
        targetSdk 35
        versionCode 1
        versionName "0.1.0"
    }
}
```

`minSdk 23` diperlukan untuk penyulitan dan biometrik yang munasabah.

### 5.2 Keystore

```bash
keytool -genkey -v -keystore waris-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias waris
```

Buat `android/key.properties`:

```properties
storePassword=<...>
keyPassword=<...>
keyAlias=waris
storeFile=../../waris-release.jks
```

> **Kritikal:** Simpan `waris-release.jks` dan kata laluannya dalam **sekurang-kurangnya dua lokasi berasingan** (pengurus kata laluan + storan luar talian terenkripsi). Kalau hilang, kau **tidak boleh** mengemas kini app di Play Store selamanya. Ini kesilapan yang tidak boleh diperbaiki.
>
> Kedua-dua fail ini masuk `.gitignore`. Jangan sekali-kali commit.

### 5.3 Konfigurasi keluaran

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                      'proguard-rules.pro'
    }
}
```

### 5.4 Kebenaran — minimum mutlak

`AndroidManifest.xml` hanya:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

CAMERA dan READ_MEDIA_IMAGES hanya untuk foto avatar dan diminta secara runtime bila digunakan sahaja.

**Jangan minta:** lokasi, kenalan, telefon, SMS, storan penuh. App yang memegang salasilah keluarga dan maklumat aset mesti kelihatan sangat berhemah dengan kebenaran. Pengguna akan menyemak.

### 5.5 Arahan build

```bash
# Bersihkan
flutter clean && flutter pub get
cd app

# Jalankan semua ujian dahulu
melos run test          # mesti 100% hijau

# APK universal — untuk edaran terus / ujian
flutter build apk --release

# APK per-ABI — saiz lebih kecil
flutter build apk --split-per-abi --release

# App Bundle — untuk Play Store (Fasa 8)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 5.6 Senarai semak sebelum keluaran

- [ ] Ikon app pada semua ketumpatan (guna `flutter_launcher_icons`)
- [ ] Skrin splash (guna `flutter_native_splash`)
- [ ] Nama app betul dalam BM dan EN
- [ ] `versionCode` dinaikkan
- [ ] Mod keluaran diuji pada peranti sebenar, bukan hanya debug
- [ ] Diuji pada Android 6, 10, 14 sekurang-kurangnya
- [ ] Diuji pada telefon skrin kecil (5") dan tablet
- [ ] Tiada log `print()` yang tertinggal dalam laluan keluaran
- [ ] Saiz APK di bawah 40MB
- [ ] Ujian pemasangan bersih: pasang, bina keluarga, tutup, buka semula, data masih ada

### 5.7 Edaran ujian

Sebelum Play Store, edarkan APK kepada 10–20 penguji:

- Keluarga terdekat (kes penggunaan sebenar)
- 2–3 orang berpengetahuan agama (semak istilah dan nada)
- 2–3 orang bukan teknikal (semak sama ada UX benar-benar mudah)

Kumpulkan maklum balas melalui borang mudah. Perkara yang mesti disoal:

1. Berapa lama untuk memasukkan keluarga anda?
2. Adakah anda faham keputusan simulasi?
3. Ada apa-apa yang terasa tidak selesa atau tidak menghormati?
4. Apa yang anda jangka ada tetapi tiada?

Soalan ketiga adalah yang paling penting dan yang paling mudah dilupakan.

### Definition of Done — Fasa 5

- [ ] APK ditandatangan berjaya dibina
- [ ] Dipasang dan berjalan pada minimum 3 peranti berbeza
- [ ] Keystore disandarkan di dua lokasi
- [ ] 10+ penguji telah menggunakannya
- [ ] Maklum balas dikumpul dan diasingkan kepada pepijat / permintaan ciri
- [ ] Tag `v0.3.0-apk`

**🎯 Milestone tercapai: WARIS wujud sebagai app sebenar.**

---

## FASA 6 — Wali, Nasab & Mahram

**Objektif:** Enjin kedua dan ketiga di atas graf yang sama.

### 6.1 Enjin Wali — pendekatan berhati-hati

Wali membawa risiko perundangan **lebih tinggi** daripada faraid. Faraid agak seragam. Susunan wali, wali hakim dan wali adhal berbeza dari segi prosedur mengikut negeri dan melibatkan bidang kuasa Mahkamah Syariah.

**Keputusan reka bentuk:** Sehingga penasihat Syariah mengesahkan ruleset dan sanggup dinamakan, modul wali diposisikan sebagai **pendidikan**, bukan penentuan.

Perbezaan dalam perkataan:

| ❌ Jangan | ✅ Ya |
|---|---|
| "Wali nikah Aisyah ialah Abdullah" | "Berdasarkan susunan wali nasab, calon yang paling hampir ialah bapa — Abdullah" |
| "Wali sah" | "Calon wali" |
| "Keputusan" | "Panduan" |

### 6.2 Aliran

```
Aisyah (perempuan)
      ↓
[ 👰 Semak wali ]
      ↓
Enjin membaca nasab sebelah bapa
      ↓
Menapis mengikut kelayakan (hidup, lelaki, nasab sabit, baligh)
      ↓
Susun mengikut keutamaan dalam ruleset
      ↓
Paparkan calon + rantaian + sebab
```

### 6.3 Output

```
SEMAK WALI — Aisyah

Calon paling hampir
🟢 Bapa — Abdullah

Sebab
Bapa berada pada kedudukan pertama dalam
susunan wali nasab, dan beliau masih hidup.

Rantaian nasab
  Aisyah
    ↑ bapa
  Abdullah
    ↑ bapa
  Ibrahim (datuk sebelah bapa)

Calon seterusnya jika bapa tiada
  ⚪ Datuk sebelah bapa — Ibrahim
  ⚪ Saudara lelaki seibu-sebapa — (tiada dalam rekod)

⚠️ Ini panduan pendidikan sahaja. Penentuan wali
   yang sah dibuat oleh Pejabat Agama atau
   Mahkamah Syariah negeri anda.
```

Menunjukkan **calon seterusnya** menjadikan ini alat pendidikan dan bukan kotak hitam. Pengguna belajar susunannya, bukan sekadar menerima satu nama.

### 6.4 Keadaan pengecualian — mesti dikendalikan

Enjin mesti mengesan dan membendera, bukan meneka:

| Keadaan | Tindakan |
|---|---|
| Tiada wali nasab dalam rekod | ⚠️ Rujuk pihak berautoriti — kemungkinan wali hakim |
| Nasab bapa tidak sabit | ⚠️ Rantaian wali tidak boleh dibina daripada individu tersebut |
| Semua calon telah meninggal | ⚠️ Rujuk pihak berautoriti |
| Wali ghaib / tidak dapat dihubungi | ⚠️ Prosedur khusus negeri diperlukan |
| Wali enggan (adhal) | ⚠️ Perkara ini dirujuk kepada Mahkamah Syariah |
| Data tidak lengkap | 🟡 Lengkapkan maklumat untuk panduan yang lebih tepat |

App **tidak pernah** cuba menyelesaikan keadaan ini sendiri.

### 6.5 Enjin Mahram — idea tambahan

Ini enjin ketiga yang murah untuk dibina dan tiada risiko perundangan seperti wali. Graf yang sama menjawab: **siapa mahram saya?**

Kegunaan sebenar:

- Perancangan musafir — siapa boleh menemani
- Menjelaskan hubungan keluarga dalam keluarga besar yang bercampur
- Pendidikan untuk remaja yang belajar tentang hubungan keluarga

```
MAHRAM — Aisyah

Mahram nasab (kekal)
  Bapa · Abdullah
  Datuk · Ibrahim
  Anak lelaki · Ali
  Saudara lelaki · Umar
  Bapa saudara sebelah bapa · Rahman
  Anak saudara lelaki · Zaid

Mahram susuan
  (tiada dalam rekod)  [ + Tambah hubungan susuan ]

Mahram semenda
  Bapa mertua · Sulaiman

Bukan mahram
  Sepupu · Karim
  Ipar lelaki · Hasan
```

**Kenapa aku cadangkan ini:** ia menambah nilai harian kepada app yang selainnya hanya dibuka semasa krisis. Seseorang mungkin membuka WARIS untuk semak mahram sebelum umrah — dan itu memberi app sebab untuk hidup dalam telefon mereka antara kematian.

Ia juga memerlukan penambahan model data: **hubungan susuan** (`radha`), yang tidak wujud dalam graf nasab biasa.

```dart
class MilkKinshipLink {
  String id;
  String childId;
  String milkMotherId;
  int? feedingCount;      // ≥5 kali dalam kebanyakan pendapat
  bool isConfirmed;
}
```

### 6.6 Nasab UI

Bila menambah anak, tanya dengan lembut:

```
Siapa bapa kepada Ali?

○ Ahmad
○ Orang lain
○ Belum disahkan
○ Saya tidak pasti
```

Empat pilihan. Tiada satu pun menghukum. "Belum disahkan" dan "Saya tidak pasti" adalah pilihan yang sah dan tidak menghalang pengguna daripada meneruskan.

Kesan pada enjin dikendalikan secara senyap di belakang — pengguna tidak perlu memahami perkataan *nasab* untuk mendapat keputusan yang betul.

### Definition of Done — Fasa 6

- [ ] Ruleset wali ditulis dan disemak penasihat Syariah
- [ ] 30+ kes ujian wali lulus
- [ ] Semua keadaan pengecualian membendera dengan betul
- [ ] Enjin mahram berfungsi termasuk hubungan susuan
- [ ] UI nasab tidak menggunakan bahasa menghukum di mana-mana
- [ ] Data nasab private secara lalai

---

## FASA 7 — Estate, Dokumen & Laporan

**Objektif:** Ciri yang mengubah WARIS daripada alat simulasi kepada rekod keluarga.

### 7.1 Pengurus aset

Kategori sejajar dengan yang digunakan dalam alat rasmi Malaysia:

```
Hartanah      Rumah · Tanah · Bangunan
Kenderaan     Kereta · Motosikal
Kewangan      Bank · KWSP · ASNB · Tabung Haji · Saham · Unit amanah
Fizikal       Emas · Barang kemas · Perniagaan · Tunai
Lain-lain     Insurans · Takaful · Aset digital
```

Liabiliti:

```
Pinjaman rumah · Pinjaman kereta · Pinjaman peribadi
Kad kredit · Hutang individu · Zakat tertunggak · Nazar
```

Setiap item: nama, kategori, nilai anggaran, pemilik, nota, status pengesahan.

### 7.2 Peti dokumen

Simpan dokumen sensitif dengan penyulitan tempatan:

```
📁 Dokumen Keluarga
   Sijil nikah
   Sijil kelahiran
   Geran tanah
   Penyata bank
   Wasiat
   Dokumen hibah
   Polisi insurans
```

**Keperluan keselamatan — tidak boleh berkompromi:**

- Sulitkan di device sebelum sebarang muat naik (AES-256, kunci dalam Android Keystore)
- Kunci biometrik untuk membuka peti
- Muat naik cloud adalah **pilihan**, bukan lalai
- Supabase Storage dengan RLS ketat jika cloud digunakan
- Kebenaran per-dokumen untuk ahli keluarga yang dijemput
- Padam bermakna padam sebenar, termasuk daripada storan

### 7.3 Senarai semak selepas kematian

Bila simulasi ditukar kepada peristiwa sebenar, app beralih daripada mod perancangan kepada mod bantuan:

```
BILA BERLAKU KEMATIAN

01  Dapatkan sijil kematian
02  Kenal pasti waris
03  Kumpulkan dokumen aset
04  Semak hutang si mati
05  Semak wasiat dan hibah
06  Semak harta sepencarian
07  Mohon sijil faraid jika diperlukan
08  Tentukan saluran pentadbiran pusaka
      · Pusaka kecil (< RM2 juta, tanpa wasiat) → JKPTG
      · Pusaka besar / ada wasiat → Mahkamah Tinggi
      · Amanah Raya bagi kes tertentu
09  Laksanakan pembahagian
10  Kemas kini hak milik
```

Setiap langkah boleh ditanda selesai, ada nota ringkas, dan pautan ke sumber rasmi.

> **Ini mungkin ciri paling bernilai dalam seluruh app** dan ia hampir tidak memerlukan kejuruteraan. Keluarga yang baru kehilangan seseorang tidak tahu langkah pertama. Senarai semak yang tenang dan tersusun pada saat itu adalah pertolongan sebenar.

### 7.4 Laporan PDF

Guna package `pdf` untuk Dart. Hasilkan:

```
LAPORAN SIMULASI PUSAKA

Si mati:            Ahmad bin Abdullah
Tarikh simulasi:    2 September 2026
Ruleset:            Malaysia / Syafie v1.0

[ Rajah salasilah keluarga ]

WARIS YANG DIKENAL PASTI
┌────────────────┬─────────┬────────────┐
│ Waris          │ Bahagian│ Anggaran   │
├────────────────┼─────────┼────────────┤
│ Isteri         │ 1/8     │ RM 92,500  │
│ Anak lelaki ×2 │ 7/15    │ RM 345,333 │
│ Anak perempuan │ 7/30    │ RM 172,667 │
│ Ibu            │ 1/6     │ RM 123,333 │
└────────────────┴─────────┴────────────┘

Asal masalah: 24 → tashih 120

WARIS YANG TERDINDING
Saudara lelaki — terdinding oleh anak lelaki

PENAFIAN
[ teks penafian penuh ]
```

**Kawalan privasi pada eksport:** pengguna memilih apa yang disertakan.

```
☑ Nama
☑ Hubungan
☐ Tarikh lahir
☐ Nilai aset
☐ Nombor telefon
☐ Status nasab
```

Salasilah keluarga adalah dokumen yang orang suka kongsi. Nilai aset dan status nasab bukan. Asingkan kedua-duanya.

### Definition of Done — Fasa 7

- [ ] Aset dan liabiliti berfungsi
- [ ] Peti dokumen tersulit dengan kunci biometrik
- [ ] Senarai semak kematian lengkap dengan rujukan rasmi
- [ ] Eksport PDF berfungsi dengan kawalan privasi
- [ ] Rajah salasilah dirender dalam PDF

---

## FASA 8 — Cloud, Kolaborasi & Monetisasi

**Objektif:** Sync, perkongsian keluarga, pembayaran, keluaran Play Store.

### 8.1 Model sync

App kekal **local-first**. Cloud adalah lapisan tambahan.

```
SQLite (sumber kebenaran)
      ↕ sync
Supabase Postgres (backup + kolaborasi)
```

Strategi konflik: **last-write-wins pada peringkat medan** dengan cap masa, kecuali perubahan hubungan yang mencipta **permintaan perubahan** untuk kelulusan pemilik.

### 8.2 Skema Supabase + RLS

```sql
create table families (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users not null,
  name text not null,
  is_premium boolean default false,
  created_at timestamptz default now()
);

create table family_members (
  family_id uuid references families on delete cascade,
  user_id uuid references auth.users,
  role text not null check (role in ('owner','admin','editor','viewer')),
  primary key (family_id, user_id)
);

alter table persons enable row level security;

create policy "ahli keluarga boleh baca"
  on persons for select
  using (
    family_id in (
      select family_id from family_members
      where user_id = auth.uid()
    )
  );

create policy "editor boleh tulis"
  on persons for insert
  with check (
    family_id in (
      select family_id from family_members
      where user_id = auth.uid()
        and role in ('owner','admin','editor')
    )
  );
```

**Tulis ujian pgTAP untuk setiap dasar RLS.** Data ini adalah salasilah keluarga dan maklumat kewangan. Dasar RLS yang salah adalah pelanggaran privasi, bukan pepijat.

Medan nasab memerlukan dasar **lebih ketat**: hanya pemilik dan admin, tidak pernah editor atau viewer.

### 8.3 Kolaborasi keluarga

```
Ahmad — Pemilik
Aisyah — Editor
Ali — Viewer
Rahman — Editor
```

Bila editor menambah seseorang:

```
PERUBAHAN MENUNGGU KELULUSAN

Rahman menambah:
  👴 Pak Long Sulaiman
  Saudara lelaki kepada Abdullah

[ Terima ]  [ Tolak ]  [ Lihat butiran ]
```

Tanpa kelulusan, salasilah keluarga akan rosak dalam masa seminggu. Ini bukan kerumitan berlebihan — ia keperluan.

### 8.4 Monetisasi — keputusan muktamad

**Free + Premium Lifetime. Tiada langganan bulanan atau tahunan.**

Alasannya kukuh: app ini mungkin tidak dibuka selama enam bulan, kemudian dibuka pada hari kematian dalam keluarga. Melihat *"Langganan anda telah tamat"* pada saat itu adalah kegagalan produk yang mendalam, bukan sekadar geseran.

| | FREE | PREMIUM LIFETIME |
|---|---|---|
| Ahli keluarga | 30 | Tanpa had |
| Family tree & network view | ✅ | ✅ |
| Simulasi kematian | ✅ | ✅ |
| Pengiraan faraid asas | ✅ | ✅ |
| Semak wali asas | ✅ | ✅ |
| Semak mahram | ✅ | ✅ |
| Pusat pembelajaran | ✅ | ✅ |
| Sejarah simulasi | 3 terakhir | Tanpa had |
| Perbandingan senario | — | ✅ |
| Pengurus aset & liabiliti | — | ✅ |
| Peti dokumen | — | ✅ (2GB) |
| Kolaborasi keluarga | — | ✅ |
| Laporan PDF | — | ✅ |
| Garis masa keluarga | — | ✅ |
| Warisan keluarga (cerita, foto) | — | ✅ |
| Sandaran cloud | — | ✅ |
| Pembantu AI | — | ✅ (had penggunaan adil) |

**Harga kerja:** RM 59.90 sekali bayar.

**Perkara yang tidak boleh diletakkan di belakang paywall:**

Ilmu asas. Sesiapa boleh tahu siapa waris mereka tanpa membayar sesen. Kalau kita kunci itu, WARIS menjadi "kalkulator yang nak duit" dan kehilangan hak moral untuk wujud.

Yang dimonetisasi ialah **kuantiti, kedalaman, storan, kolaborasi dan kemudahan** — bukan akses kepada hukum.

### 8.5 Premium melekat pada keluarga, bukan individu

Ini keputusan yang paling berharga dalam model.

Ahmad membeli Premium sekali. **Family Network Ahmad** menjadi Premium. Kemudian dia menjemput isteri, adik, anak dan ibu — semua mereka boleh menyumbang kepada rangkaian yang sama tanpa membayar apa-apa.

Dua kesan:

1. Ia sejajar dengan niat produk — memelihara institusi keluarga, bukan mengutip yuran per-kepala
2. Ia menjadi enjin pertumbuhan organik. Setiap jemputan membawa pengguna baharu yang mungkin kemudiannya membeli Premium untuk rangkaian keluarga mereka sendiri

```
Ahmad beli Premium
      ↓
Jemput isteri → dia tambah keluarga sebelah dia
      ↓
Jemput abang → dia tambah cabang sebelah bapa
      ↓
Abang buka WARIS untuk keluarga dia sendiri
      ↓
Abang beli Premium
```

Tiada program rujukan yang dipaksa. Pertumbuhan datang daripada sifat produk itu sendiri.

### 8.6 Had penggunaan adil

Lifetime bermakna **ciri tanpa had**, bukan **kos tanpa had**.

| Sumber | Had |
|---|---|
| Ahli keluarga | Tanpa had |
| Simulasi | Tanpa had |
| Semak wali & mahram | Tanpa had |
| Storan dokumen | 2 GB (tambahan sebagai add-on pilihan) |
| Pertanyaan AI | 100/bulan (jauh melebihi penggunaan biasa) |

Nyatakan had ini dengan jelas pada skrin pembelian. Jangan sembunyikan.

### 8.7 Pelaksanaan pembayaran

- Google Play Billing — produk **non-consumable** bernama `waris_premium_lifetime`
- Guna RevenueCat untuk mengelakkan menulis logik pengesahan resit sendiri
- Sahkan pembelian sebelah pelayan sebelum menandakan `families.is_premium = true`
- Simpan status premium dalam SQLite tempatan supaya app berfungsi luar talian
- Semak semula secara berkala, tetapi **jangan sekali-kali kunci pengguna keluar** kerana kegagalan rangkaian

Idea tambahan yang sejajar dengan niat produk:

- **Hadiah Premium** — beli untuk keluarga lain (RM 59.90)
- **Tajaan** — individu atau NGO menaja 10, 50, 100 keluarga pada harga pukal

### 8.8 Play Store

Diperlukan:

- Ikon 512×512, grafik ciri 1024×500
- 4–8 tangkapan skrin telefon + 2 tablet
- Penerangan pendek (80 aksara) dan penuh (4000)
- **Dasar privasi** — wajib, hosted di domain kau
- Borang Keselamatan Data — isi dengan jujur; app ini mengumpul data peribadi sensitif
- Penilaian kandungan
- Akaun Pengecam Pembangun ($25 sekali bayar)

**Dasar privasi mesti menyatakan dengan jelas:**

- Data keluarga disimpan secara tempatan secara lalai
- Sync cloud adalah pilihan dan memerlukan tindakan pengguna
- Data tidak pernah dijual atau dikongsi dengan pengiklan
- Pengguna boleh mengeksport dan memadam semua data
- Data nasab tidak pernah dikongsi dengan ahli keluarga lain tanpa kebenaran eksplisit

Lancarkan melalui **ujian tertutup** (20 penguji, seminggu) → **ujian terbuka** (2 minggu) → **pengeluaran**. Jangan terus ke pengeluaran.

### Definition of Done — Fasa 8

- [ ] Sync berfungsi dua hala tanpa kehilangan data
- [ ] Semua dasar RLS diuji dengan pgTAP
- [ ] Aliran kolaborasi keluarga dengan kelulusan berfungsi
- [ ] IAP diuji dalam ujian tertutup
- [ ] Premium mengalir dengan betul kepada semua ahli keluarga
- [ ] Dasar privasi diterbitkan
- [ ] Borang Keselamatan Data lengkap dan jujur
- [ ] Ujian tertutup selesai

---

# BAHAGIAN C — IDEA TAMBAHAN

Berikut adalah cadangan yang tidak ada dalam perbincangan asal. Setiap satu disertakan dengan penilaian jujur sama ada ia berbaloi.

## C1. Enjin Mahram ⭐ Sangat disyorkan

Sudah diterangkan dalam Fasa 6. Ringkasnya: graf yang sama, risiko perundangan yang jauh lebih rendah daripada wali, dan ia memberi app sebab untuk dibuka pada hari biasa dan bukan hanya semasa krisis.

**Kos:** rendah. **Nilai:** tinggi.

## C2. Trace sebagai bahan pendidikan

Trace enjin faraid sudah merekod setiap langkah. Dedahkan ia sebagai mod pembelajaran pilihan:

```
[ Tunjuk langkah pengiraan ]

1. Asal masalah ditetapkan: 24
2. Isteri: 1/8 × 24 = 3 saham
3. Ibu: 1/6 × 24 = 4 saham
4. Baki: 24 − 7 = 17 saham kepada anak
5. Nisbah anak 2:2:1 = 5 bahagian
6. 17 tidak boleh dibahagi 5 → tashih
7. Asal masalah × 5 = 120
...
```

Pelajar dan pelajar pengajian Islam akan menghargai ini, dan ia tidak memerlukan kejuruteraan tambahan — trace sudah wujud.

**Kos:** hampir sifar. **Nilai:** sederhana, tetapi ia membina kredibiliti.

## C3. Perbandingan senario

```
Senario A: Ahmad meninggal
Senario B: Ahmad dan Aisyah meninggal
Senario C: Ahmad meninggal selepas bapanya

              A         B         C
Waris         5         4         6
Isteri     1/8       —         1/8
Anak      7/8      100%      2/3
Ibu        1/6       —         1/6
```

Ini yang mendedahkan sesuatu yang orang tidak jangka: **urutan kematian mengubah pembahagian dengan ketara**. Ia berguna untuk perancangan pusaka sebenar.

**Kos:** sederhana. **Nilai:** tinggi — ini ciri Premium yang kukuh.

## C4. "Apa yang tidak lengkap?"

Bukan skor peratusan yang samar, tetapi senarai yang boleh ditindak:

```
UNTUK SIMULASI YANG LEBIH TEPAT

⚠️ Status hidup Aminah (ibu) tidak diketahui
   Ini mempengaruhi 3 simulasi

⚠️ Tarikh lahir Ali tiada
   Diperlukan untuk semakan konsistensi

💡 Anda belum menambah adik-beradik bapa
   Mereka mungkin menjadi waris dalam sesetengah keadaan
```

Setiap item menerangkan **kenapa** ia penting. Ini jauh lebih memotivasikan daripada "Family Readiness 78%".

**Kos:** rendah. **Nilai:** tinggi untuk kelengkapan data.

## C5. Warisan keluarga — nilai emosi

Ciri Premium: simpan cerita, foto lama, tempat asal, pesanan untuk generasi akan datang.

```
👴 Abdullah bin Hassan
   1938 – 2019

   Asal: Kampung Losong, Kuala Terengganu
   Pekerjaan: Nelayan, kemudian guru

   🎙️ "Cerita Tok Ayah tentang banjir 1967"
      (audio 4:32)

   📷 12 gambar
```

Ini bukan faraid. Ia sebab untuk keluarga kembali kepada app antara peristiwa besar, dan ia menjadikan pembelian Premium terasa seperti melabur dalam sesuatu yang kekal, bukan membuka kunci ciri.

**Kos:** sederhana (storan media). **Nilai:** tinggi untuk pengekalan.

## C6. Eksport GEDCOM

GEDCOM ialah format standard salasilah keluarga sejagat. Menyokong import/eksport bermakna:

- Pengguna tidak terkurung — mereka boleh keluar bila-bila masa
- Data mereka selamat walaupun WARIS berhenti wujud
- Boleh import dari Ancestry, MyHeritage, FamilySearch

Nilai kepercayaan ini lebih besar daripada kos pelaksanaan. App yang membiarkan kau pergi adalah app yang kau percaya untuk tinggal.

**Kos:** sederhana. **Nilai:** tinggi untuk kepercayaan.

## C7. Mod pelawat untuk orang tua

Warga emas selalunya penyimpan pengetahuan salasilah keluarga, tetapi paling kurang selesa dengan app.

Mod pelawat: skrin mudah, teks besar, hanya soalan.

```
        Siapa nama bapa
        kepada Abdullah?

     [ ______________ ]

        [ Seterusnya ]
```

Anak menghantar pautan kepada ibu bapa, mereka menjawab lima soalan pada telefon mereka sendiri, dan graf terisi. Tiada akaun diperlukan.

**Kos:** sederhana. **Nilai:** tinggi — ini menyelesaikan masalah sebenar dalam mengumpul data salasilah.

## C8. Mod Amanah

Ciri yang tidak ada dalam mana-mana app faraid setahu aku.

Pengguna menetapkan seorang **penerima amanah** — biasanya pasangan atau anak dewasa. Jika pengguna tidak membuka app selama tempoh yang ditetapkan (contohnya 180 hari) **dan** tidak membalas tiga peringatan, penerima amanah diberikan akses terhad kepada:

- Salasilah keluarga
- Inventori aset (senarai, bukan dokumen)
- Senarai semak selepas kematian

Bukan dokumen. Bukan kata laluan. Cukup untuk keluarga tahu di mana hendak bermula.

Ini perlu dilaksanakan dengan sangat berhati-hati — pengesahan berbilang, tempoh bertenang, keupayaan untuk membatalkan. Tetapi ia menangani senario sebenar yang menjadi punca app ini wujud: seseorang meninggal, dan keluarga tidak tahu apa-apa.

**Kos:** tinggi (kompleks, sensitif). **Nilai:** sangat tinggi. Pertimbangkan untuk fasa lewat.

## C9. Perkara yang aku cadangkan JANGAN buat

Setakat pentingnya senarai idea, senarai ini sama penting.

| Idea | Kenapa jangan |
|---|---|
| Rangkaian sosial / carian keluarga awam | Kebimbangan privasi yang besar; mengubah produk sepenuhnya |
| Ujian DNA / integrasi genealogi | Di luar skop; menimbulkan persoalan nasab yang app tidak layak jawab |
| Sembang AI sebagai antara muka utama | Faraid memerlukan ketepatan, bukan perbualan |
| Kalkulator zakat | Domain berbeza; menyahfokuskan produk |
| Peringatan solat, arah kiblat | Bloat "app Islamik" klasik; sudah ada beribu |
| Iklan | Tidak sesuai sama sekali untuk app yang memegang salasilah keluarga |
| Menjual keputusan faraid sebagai perkhidmatan sah | Kita bukan pihak berautoriti dan tidak boleh berpura-pura |
| Auto-detect anak luar nikah dari tarikh | Salah dari segi teknikal dan moral |

---

# BAHAGIAN D — RUJUKAN PANTAS

## D1. Ringkasan garis masa

| Fasa | Kerja | Anggaran (separuh masa) |
|---|---|---|
| 0 | Persediaan | 1–2 minggu |
| 1 | Enjin faraid | 4–6 minggu |
| 2 | Graf keluarga | 3–4 minggu |
| 3 | UI Family Network | 4–6 minggu |
| 4 | Death Simulation | 2–3 minggu |
| 5 | **APK pertama** | 1 minggu |
| 6 | Wali, nasab, mahram | 4–5 minggu |
| 7 | Estate, dokumen, PDF | 3–4 minggu |
| 8 | Cloud, monetisasi, Play Store | 4–6 minggu |

**Ke APK pertama: kira-kira 15–22 minggu.**
**Ke keluaran Play Store: kira-kira 26–37 minggu.**

Anggaran ini mengandaikan kerja separuh masa di sekitar perniagaan dan keluarga. Fasa 1 adalah yang paling mudah dipandang remeh — jangan cuba memampatkannya.

## D2. Kad arahan untuk Claude Code

Gunakan arahan ini semasa membina:

```
FASA 0
"Mulakan monorepo Flutter bernama waris menggunakan Melos. Cipta
package: faraid_engine, wali_engine, mahram_engine, family_graph
(semua pure Dart) dan app (Flutter). Sediakan git dengan .gitignore
yang mengecualikan keystore dan rahsia."

FASA 1
"Dalam packages/faraid_engine, laksanakan kelas Fraction menggunakan
BigInt tanpa aritmetik titik terapung. Kemudian laksanakan enum
HeirType lengkap seperti dalam SPEC 1.3."

"Laksanakan Hajb Engine mengikut SPEC 1.4 langkah 3. Tulis ujian
untuk setiap peraturan pendindingan."

"Baca test/cases/*.yaml dan bina test runner yang mengesahkan output
enjin terhadap setiap kes yang dijangka."

FASA 2
"Dalam packages/family_graph, laksanakan model Person, ParentLink,
SpouseLink mengikut SPEC 2.2, dan RelationshipResolver mengikut
SPEC 2.4."

"Laksanakan extractHeirs() yang menukar FamilyGraph kepada
FaraidInput, menghormati NasabStatus mengikut SPEC 2.5."

FASA 3
"Bina skrin Family Network menggunakan CustomPainter dalam
InteractiveViewer, dengan algoritma susun atur SPEC 3.3."

"Laksanakan aliran Tap → Connect → bottom sheet → tambah orang
dengan animasi kemunculan nod."

FASA 4
"Bina aliran simulasi kematian: kad profil → snapshot → extractHeirs
→ faraid_engine → skrin keputusan dengan bottom sheet Kenapa."

FASA 5
"Konfigurasi penandatanganan keluaran Android mengikut SPEC 5.3 dan
bina APK keluarga."
```

## D3. Peraturan yang mesti dipatuhi sepanjang projek

1. **Enjin sebelum UI.** Sentiasa.
2. **Pecahan, bukan titik terapung.** Dalam mana-mana laluan pengiraan.
3. **Nasab menapis waris.** Bukan graf keluarga.
4. **Snapshot immutable.** Simulasi tidak pernah berubah selepas dicipta.
5. **AI menerangkan, tidak pernah menentukan.**
6. **Bendera ketidakpastian, jangan teka.**
7. **Tiada bahasa menghukum** dalam mana-mana string UI.
8. **Penafian pada setiap skrin keputusan.**
9. **Ilmu asas kekal percuma.**
10. **Commit setiap hari.** Tag setiap milestone.

## D4. Sumber rujukan

**Hukum & prosedur**
- e-Faraid MAIS — kalkulator dan bahan pendidikan
- Kalkulator Faraid MyGovernment
- Jabatan Mufti Wilayah Persekutuan — Bayan Linnas dan Irsyad al-Fatwa mengenai nasab dan wali
- JKPTG — prosedur pusaka kecil
- Amanah Raya Berhad — pentadbiran pusaka

**Teknikal**
- docs.flutter.dev
- supabase.com/docs — terutamanya bahagian RLS
- drift.simonbinder.eu
- docs.codemagic.io — untuk build iOS dari Windows

**Untuk semakan**
- Jabatan Mufti Negeri Terengganu
- Fakulti Syariah dan Undang-undang, UniSZA

---

## Nota penutup

Perkara yang paling mudah dipandang remeh dalam projek ini bukanlah UI graf yang cantik atau animasi yang licin. Ia adalah **ketepatan enjin faraid**, dan ia satu-satunya bahagian yang kalau salah, akan menyebabkan kemudaratan sebenar kepada keluarga sebenar.

Bina enjin itu dahulu. Uji sehingga membosankan. Dapatkan ia disemak oleh orang yang layak. Selepas itu semua yang lain adalah kerja kejuruteraan biasa.

Dan ingat prinsip yang menjadikan produk ini bernilai sejak awal:

> **Kau tidak membina kalkulator faraid. Kau membina cara untuk keluarga Muslim mengenali diri mereka sendiri — dan faraid hanyalah salah satu soalan yang mereka boleh tanya.**
