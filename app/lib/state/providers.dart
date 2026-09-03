import 'package:family_graph/family_graph.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/family_repository.dart';

/// Diganti dalam `main()` dengan instance yang mempunyai fail kegigihan, dan
/// dalam ujian dengan repo tanpa fail.
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  throw UnimplementedError('familyRepositoryProvider mesti di-override');
});

/// Graf keluarga semasa (dipancarkan semula setiap perubahan).
final familyGraphProvider = StreamProvider<FamilyGraph>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.watch();
});

/// Orang yang menjadi fokus dalam Mod Fokus (SPEC 3.4). `null` = orang "Saya".
final focusPersonIdProvider = StateProvider<String?>((ref) => null);

/// Orang "Saya" (isSelf) jika sudah dibuat.
final selfPersonProvider = Provider<Person?>((ref) {
  final graph = ref.watch(familyGraphProvider).asData?.value;
  if (graph == null) return null;
  for (final p in graph.persons) {
    if (p.isSelf) return p;
  }
  return null;
});

/// Cadangan langkah seterusnya selepas penambahan (SPEC 3.6).
final smartSuggestionProvider = StateProvider<String?>((ref) => null);
