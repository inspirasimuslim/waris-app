/// Enjin faraid deterministik untuk WARIS (lihat SPEC bahagian FASA 1).
///
/// Pure Dart — tiada kebergantungan Flutter, DB, atau UI. Semua aritmetik
/// pecahan menggunakan `Fraction` (BigInt), tidak pernah `double`.
library;

export 'src/enums.dart';
export 'src/fraction.dart';
export 'src/money.dart';
export 'src/model.dart';
export 'src/reason_codes.dart';
export 'src/trace.dart';
export 'src/engine.dart';

const String rulesetMalaysiaSyafieV1 = 'MY-SYAFIE-1.0';
