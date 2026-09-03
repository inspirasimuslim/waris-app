# Ruleset Faraid — Malaysia / Syafie v1.0

`rulesetVersion = "MY-SYAFIE-1.0"`

Dokumen ini ialah spesifikasi hukum yang dikodkan dalam `packages/faraid_engine`.
Ia ditulis untuk semakan penasihat Syariah. Setiap peraturan ada rujukan.

> Status semakan: **PENDING** — belum disahkan mana-mana penasihat (lihat DECISIONS D-004).

## 1. Ashab al-Furud dan bahagian tetap

| Waris | Syarat 1/2 | Syarat 1/4 | Syarat 1/8 | Syarat 2/3 | Syarat 1/3 | Syarat 1/6 |
|---|---|---|---|---|---|---|
| Suami | tiada far' warith | ada far' warith | — | — | — | — |
| Isteri | — | tiada far' warith | ada far' warith | — | — | — |
| Anak perempuan | seorang, tiada anak lelaki | — | — | ≥2, tiada anak lelaki | — | — |
| Cucu perempuan (dari anak lelaki) | seorang, tiada mu'assib/anak | — | — | ≥2, tiada mu'assib | — | bersama seorang anak perempuan (takmilah 2/3) |
| Ibu | — | — | — | — | tiada far' warith & tiada `jam' min al-ikhwah` | ada far' warith **atau** ≥2 adik-beradik |
| Bapa | — | — | — | — | — | ada far' warith lelaki (+ asabah jika far' perempuan sahaja) |
| Datuk (bapa kpd bapa) | seperti bapa ketika bapa tiada | | | | | 1/6 + asabah bila ada far' warith |
| Nenek (sahih) | — | — | — | — | — | 1/6 dikongsi, bila tiada ibu |
| Adik-beradik seibu | — | — | — | — | ≥2, kalalah | seorang, kalalah |
| Saudara perempuan seibu-sebapa | seorang, kalalah, tiada far'/asabah | — | — | ≥2 | — | — |
| Saudara perempuan sebapa | seorang, kalalah | — | — | ≥2, tiada s/p seibu-sebapa | — | bersama seorang s/p seibu-sebapa (takmilah) |

`far' warith` = keturunan yang mewarisi (anak lelaki/perempuan, cucu lelaki/perempuan
dari anak lelaki, ke bawah). `kalalah` = si mati tiada usul lelaki (bapa/datuk) dan
tiada far' warith.

## 2. Asabah

- **bi-nafsihi**: anak lelaki → cucu lelaki → bapa → datuk → saudara seibu-sebapa →
  saudara sebapa → anak saudara (s.i.s → sebapa) → bapa saudara (s.i.s → sebapa) →
  sepupu (s.i.s → sebapa). Urutan `jihah → darjah → kekuatan`.
- **bi-ghayrihi**: anak perempuan dengan anak lelaki; cucu perempuan dengan cucu lelaki
  setaraf/lebih rendah bila perlu; s/p s.i.s dengan saudara lelaki s.i.s; s/p sebapa
  dengan saudara lelaki sebapa. Nisbah lelaki:perempuan = 2:1.
- **ma'a-ghayrihi**: s/p s.i.s atau sebapa menjadi asabah bila bersama anak perempuan
  atau cucu perempuan.

## 3. Hajb

### Hajb hirman (gugur terus)
- Cucu (semua) terhijab oleh anak lelaki.
- Datuk terhijab oleh bapa.
- Nenek sebelah ibu terhijab oleh ibu. Nenek sebelah bapa terhijab oleh bapa dan ibu.
- Saudara seibu terhijab oleh far' warith (mutlak) dan usul lelaki (bapa, datuk).
- Saudara s.i.s terhijab oleh anak lelaki, cucu lelaki, bapa.
- Saudara sebapa terhijab oleh yang di atas + saudara lelaki s.i.s + s/p s.i.s yang jadi asabah ma'a-ghayrihi.
- Anak saudara terhijab oleh 6 di atas + datuk + saudara sebapa.
- ... (rantaian penuh dalam kod: `lib/src/hajb.dart`).

### Hajb nuqsan (kurang bahagian)
- Suami 1/2 → 1/4; isteri 1/4 → 1/8 (ada far' warith).
- Ibu 1/3 → 1/6 (ada far' warith atau ≥2 adik-beradik).
- Ibu 1/3 → 1/3 daripada baki (umariyyatain, lihat §5).

## 4. Aul dan Radd

- **Aul**: bila jumlah saham furud > asal masalah, naikkan asal masalah kepada jumlah saham.
  Asal masalah yang boleh di-'aul: 6 (→7,8,9,10), 12 (→13,15,17), 24 (→27).
- **Radd**: bila jumlah saham < asal masalah dan tiada asabah, agih baki mengikut nisbah
  furud, **kecuali** suami/isteri (tidak menerima radd; baki kepada waris furud lain,
  atau kepada Baitulmal jika tiada). MVP: radd termasuk semua furud bukan pasangan.

## 5. Kes khas

- **Umariyyatain / Gharrawain**: (suami/isteri) + ibu + bapa. Ibu ambil 1/3 **baki**
  selepas bahagian pasangan, bukan 1/3 harta. Bapa ambil selebihnya (asabah).
- **Musyarakah (Himariyyah)**: MVP — **dibendera** `requiresManualReview`, tidak dikira.
- **Akdariyyah**: suami + ibu + datuk + seorang s/p s.i.s (atau sebapa). Datuk & s/p
  digabung, kemudian s/p ambil separuh bahagian datuk. Asal masalah 6 → aul 9 → tashih 27.
- **Jadd wal-ikhwah** (datuk bersama saudara): datuk ambil yang terbaik daripada:
  (a) 1/3 harta, (b) muqasamah dengan saudara sebagai seorang lelaki, (c) 1/6 harta
  bila ada far' warith. Saudara sebapa dikira bersama s.i.s untuk mu'addah kemudian
  s.i.s "menolak" sebapa.

## 6. Tashih

Bila mana-mana saham tidak integer selepas pembahagian kepada individu, cari
`gcd`/`lcm` antara saham setiap kumpulan dan bilangan ahlinya; darabkan asal masalah
dengan faktor tashih supaya semua bahagian individu jadi integer.

## 7. Di luar skop MVP (mesti dibendera, bukan diteka)

munasakhat, takharuj, zawil arham, mafqud, hamlun (janin), khunsa, mazhab selain
Syafie, musyarakah. Enjin pulangkan `warnings` + `requiresManualReview`.
