import 'package:faraid_engine/faraid_engine.dart';

/// Templat penerangan TETAP untuk butang "Kenapa?" (SPEC 4.5). Dipetakan
/// kepada `reasonCode` dalam trace enjin. AI (Fasa 8) hanya menulis semula
/// templat yang sudah disahkan — tidak pernah menentukan angka.
String whyText(HeirShare share, FaraidResult result) {
  final each = share.shareEach;
  final t = _heirLabel(share.type, share.count);
  final base = switch (share.reasonCode) {
    R.husbandHalf =>
      'Suami menerima 1/2 apabila si mati tidak mempunyai anak atau cucu '
          '(keturunan yang mewarisi).',
    R.husbandQuarter =>
      'Suami menerima 1/4 (bukan 1/2) kerana si mati mempunyai keturunan yang '
          'mewarisi.',
    R.wifeQuarter =>
      'Isteri menerima 1/4 apabila si mati tidak mempunyai keturunan yang '
          'mewarisi. Jika lebih seorang isteri, 1/4 itu dikongsi sama rata.',
    R.wifeEighth =>
      'Isteri menerima 1/8 (bukan 1/4) kerana si mati mempunyai keturunan yang '
          'mewarisi. Dikongsi sama rata antara isteri-isteri.',
    R.motherThird =>
      'Ibu menerima 1/3 apabila si mati tiada keturunan yang mewarisi dan '
          'kurang daripada dua orang adik-beradik.',
    R.motherSixth =>
      'Ibu menerima 1/6 (bukan 1/3) kerana si mati mempunyai keturunan yang '
          'mewarisi, atau mempunyai dua atau lebih adik-beradik.',
    R.motherThirdOfRemainder =>
      'Kes ini melibatkan pasangan, ibu dan bapa sahaja (umariyyatain). Ibu '
          'mengambil 1/3 daripada BAKI selepas bahagian pasangan, bukan 1/3 '
          'daripada keseluruhan harta.',
    R.fatherSixth =>
      'Bapa menerima 1/6 sebagai bahagian tetap kerana si mati mempunyai anak '
          'lelaki atau cucu lelaki.',
    R.fatherSixthPlusAsabah =>
      'Bapa menerima 1/6 sebagai bahagian tetap, DAN mengambil baki harta '
          'sebagai asabah kerana si mati hanya mempunyai keturunan perempuan.',
    R.fatherAsabah =>
      'Bapa mengambil baki harta sebagai asabah kerana si mati tiada keturunan '
          'lelaki.',
    R.daughterHalf =>
      'Seorang anak perempuan (tanpa anak lelaki) menerima 1/2.',
    R.daughterTwoThirds =>
      'Dua atau lebih anak perempuan (tanpa anak lelaki) berkongsi 2/3 sama '
          'rata.',
    R.daughterAsabahBiGhayrihi =>
      'Anak perempuan menjadi asabah bersama anak lelaki. Baki dibahagi dengan '
          'nisbah lelaki 2 : perempuan 1.',
    R.sonsDaughterSixth =>
      'Cucu perempuan menerima 1/6 untuk melengkapkan 2/3 bersama seorang anak '
          'perempuan.',
    R.sonAsabah || R.asabahBiNafsihi =>
      'Waris ini mengambil baki harta sebagai asabah (waris baki), selepas '
          'semua bahagian tetap diagihkan.',
    R.grandmotherSixth =>
      'Nenek menerima 1/6, dikongsi jika ada lebih daripada seorang nenek.',
    R.maternalSiblingSixth =>
      'Seorang saudara seibu menerima 1/6 (kes kalalah — si mati tiada '
          'keturunan dan tiada usul lelaki).',
    R.maternalSiblingThird =>
      'Dua atau lebih saudara seibu berkongsi 1/3 SAMA RATA (lelaki dan '
          'perempuan sama).',
    R.fullSisterHalf || R.paternalSisterHalf =>
      'Seorang saudara perempuan menerima 1/2 dalam kes kalalah.',
    R.fullSisterTwoThirds || R.paternalSisterTwoThirds =>
      'Dua atau lebih saudara perempuan berkongsi 2/3.',
    R.fullSisterAsabahMaaGhayrihi || R.paternalSisterAsabahMaaGhayrihi =>
      'Saudara perempuan menjadi asabah ma\'a-ghayrihi (bersama anak/cucu '
          'perempuan) dan mengambil baki harta.',
    R.fullSisterAsabahBiGhayrihi || R.paternalSisterAsabahBiGhayrihi =>
      'Saudara perempuan menjadi asabah bersama saudara lelaki. Nisbah 2 : 1.',
    R.paternalSisterSixth =>
      'Saudara perempuan sebapa menerima 1/6 untuk melengkapkan 2/3 bersama '
          'seorang saudara perempuan seibu-sebapa.',
    R.grandfatherBestOfThree =>
      'Datuk bersama adik-beradik: enjin memilih bahagian TERBAIK untuk datuk '
          'antara 1/3 baki, muqasamah (dikira seperti seorang saudara lelaki), '
          'atau 1/6 harta.',
    R.grandfatherSixth || R.grandfatherSixthPlusAsabah || R.grandfatherAsabah =>
      'Datuk mengambil tempat bapa apabila bapa tiada, dengan syarat yang sama.',
    R.akdariyyah =>
      'Kes Akdariyyah (suami + ibu + datuk + seorang saudara perempuan). Asal '
          'masalah 6 di-aul kepada 9, kemudian bahagian datuk dan saudara '
          'perempuan digabung dan dibahagi 2 : 1, ditashih kepada 27.',
    R.umariyyatain =>
      'Kes Umariyyatain: ibu mengambil 1/3 daripada baki selepas bahagian '
          'pasangan.',
    _ => 'Bahagian ini ditentukan oleh ruleset ${result.rulesetVersion}.',
  };

  final buffer = StringBuffer(base);
  if (share.basis == ShareBasis.aul) {
    buffer.write('\n\nJumlah semua bahagian tetap melebihi 1, jadi asal '
        'masalah di-AUL — setiap bahagian dikecilkan secara berkadar.');
  } else if (share.basis == ShareBasis.radd) {
    buffer.write('\n\nTiada waris baki (asabah), dan jumlah bahagian tetap '
        'kurang daripada 1. Baki di-RADD (dikembalikan) kepada waris bukan '
        'pasangan mengikut nisbah.');
  }
  buffer.write('\n\n$t menerima $each bagi setiap seorang.');
  buffer.write('\n\nRujukan: Ruleset ${result.rulesetVersion}. '
      'Ini panduan, bukan pengesahan rasmi.');
  return buffer.toString();
}

String _heirLabel(HeirType t, int count) {
  final s = switch (t) {
    HeirType.husband => 'Suami',
    HeirType.wife => count > 1 ? 'Setiap isteri' : 'Isteri',
    HeirType.father => 'Bapa',
    HeirType.mother => 'Ibu',
    HeirType.son => count > 1 ? 'Setiap anak lelaki' : 'Anak lelaki',
    HeirType.daughter => count > 1 ? 'Setiap anak perempuan' : 'Anak perempuan',
    HeirType.paternalGrandfather => 'Datuk sebelah bapa',
    HeirType.maternalGrandmother => 'Nenek sebelah ibu',
    HeirType.paternalGrandmother => 'Nenek sebelah bapa',
    HeirType.sonsSon => count > 1 ? 'Setiap cucu lelaki' : 'Cucu lelaki',
    HeirType.sonsDaughter =>
      count > 1 ? 'Setiap cucu perempuan' : 'Cucu perempuan',
    HeirType.fullBrother =>
      count > 1 ? 'Setiap saudara lelaki s.i.s' : 'Saudara lelaki s.i.s',
    HeirType.fullSister =>
      count > 1 ? 'Setiap saudara perempuan s.i.s' : 'Saudara perempuan s.i.s',
    HeirType.paternalBrother => 'Saudara lelaki sebapa',
    HeirType.paternalSister => 'Saudara perempuan sebapa',
    HeirType.maternalSibling =>
      count > 1 ? 'Setiap saudara seibu' : 'Saudara seibu',
    _ => t.name,
  };
  return s;
}

/// Label ringkas untuk skrin waris.
String heirLabel(HeirType t) => _heirLabel(t, 1);

/// Penafian yang WAJIB pada setiap skrin keputusan (SPEC 4.7).
const disclaimerText =
    'WARIS menyediakan simulasi dan panduan berdasarkan maklumat yang anda '
    'masukkan. Ia bukan pengesahan rasmi waris, keputusan faraid, atau '
    'penentuan sah wali nikah. Untuk kes sebenar, sila dapatkan pengesahan '
    'daripada Mahkamah Syariah atau pihak berautoriti yang berkaitan.';
