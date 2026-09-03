/// Jantina si mati / waris.
enum Gender { male, female }

/// Ruleset yang dikodkan. MVP: Malaysia / Syafie sahaja, tetapi tidak
/// hard-coded — enjin membaca ruleset sebagai parameter (SPEC prinsip 11).
enum Ruleset {
  malaysiaSyafieV1('MY-SYAFIE-1.0');

  const Ruleset(this.version);
  final String version;
}

/// Asas sesuatu bahagian diberikan.
enum ShareBasis { fardu, asabah, radd, aul, blocked }

/// Jenis asabah.
enum AsabahKind { biNafsihi, biGhayrihi, maaGhayrihi }

/// Status keseluruhan keputusan enjin.
enum ResultStatus {
  ok,

  /// Ada keadaan di luar skop MVP — angka TIDAK boleh dipercayai bulat-bulat.
  requiresManualReview,

  /// Input tidak sah — tiada pengiraan dibuat.
  invalidInput,
}

/// Keterukan amaran.
enum WarningLevel { info, caution, blocking }

/// Senarai lengkap jenis waris (SPEC 1.3). Tidak semua dilaksanakan dalam MVP;
/// yang di luar skop dibendera, bukan dikira salah.
enum HeirType {
  // --- Ashab al-Furud ---
  husband(Gender.male, furud: true),
  wife(Gender.female, furud: true),
  father(Gender.male, furud: true, asabah: true),
  mother(Gender.female, furud: true),
  daughter(Gender.female, furud: true, asabahBiGhayrihi: true),
  sonsDaughter(Gender.female, furud: true, asabahBiGhayrihi: true),
  fullSister(Gender.female, furud: true, asabahBiGhayrihi: true, asabahMaaGhayrihi: true),
  paternalSister(Gender.female, furud: true, asabahBiGhayrihi: true, asabahMaaGhayrihi: true),
  maternalSibling(Gender.male, furud: true, genderNeutral: true),
  paternalGrandfather(Gender.male, furud: true, asabah: true),
  maternalGrandmother(Gender.female, furud: true),
  paternalGrandmother(Gender.female, furud: true),

  // --- Asabah bi-nafsihi ---
  son(Gender.male, asabah: true),
  sonsSon(Gender.male, asabah: true),
  fullBrother(Gender.male, asabah: true),
  paternalBrother(Gender.male, asabah: true),
  fullBrothersSon(Gender.male, asabah: true),
  paternalBrothersSon(Gender.male, asabah: true),
  fullPaternalUncle(Gender.male, asabah: true),
  paternalUncle(Gender.male, asabah: true),
  fullPaternalUnclesSon(Gender.male, asabah: true),
  paternalUnclesSon(Gender.male, asabah: true);

  const HeirType(
    this.gender, {
    this.furud = false,
    this.asabah = false,
    this.asabahBiGhayrihi = false,
    this.asabahMaaGhayrihi = false,
    this.genderNeutral = false,
  });

  /// Jantina lazim. Untuk [maternalSibling] jantina tidak mempengaruhi bahagian
  /// ([genderNeutral] = true).
  final Gender gender;

  /// Boleh menerima bahagian tetap (fardu).
  final bool furud;

  /// Boleh menjadi asabah bi-nafsihi.
  final bool asabah;

  /// Boleh menjadi asabah bi-ghayrihi (ditarik oleh saudara lelaki setaraf).
  final bool asabahBiGhayrihi;

  /// Boleh menjadi asabah ma'a-ghayrihi (bersama anak/cucu perempuan).
  final bool asabahMaaGhayrihi;

  /// Bahagian sama tanpa mengira jantina (waris seibu).
  final bool genderNeutral;
}
