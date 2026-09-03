/// Status hidup seseorang (SPEC 2.2).
enum LifeStatus { alive, deceased, unknown }

/// Peranan ibu bapa dalam [ParentLink].
enum ParentRole { father, mother }

/// Jenis pertalian ibu bapa–anak.
enum LinkKind { biological, adoptive, step }

/// Status perkahwinan dalam [SpouseLink].
enum MarriageStatus { married, divorced, widowed }

/// Lapisan nasab (SPEC 2.3). Membezakan WARIS daripada family tree biasa.
///
/// Urutan enum = urutan kekuatan; `confirmed` paling kuat.
enum NasabStatus {
  /// 🟢 nasab sabit.
  confirmed,

  /// 🟡 pengguna tidak pasti.
  unknown,

  /// 🟠 nasab tidak sabit.
  notEstablished,

  /// 🔴 ada percanggahan.
  disputed,

  /// ⚠️ perlu semakan pihak berautoriti.
  requiresAuthorityReview;

  /// Adakah status ini cukup kuat untuk pewarisan faraid?
  ///
  /// Hanya [confirmed] melayakkan seseorang sebagai waris nasab. Semua yang
  /// lain ditapis keluar oleh Heir Extractor (SPEC 2.5 langkah 4) — enjin
  /// tidak pernah meneka.
  bool get inheritsByNasab => this == NasabStatus.confirmed;
}

/// Jenis pertalian darah untuk pelabelan hubungan.
enum SiblingKind { full, paternal, maternal }
