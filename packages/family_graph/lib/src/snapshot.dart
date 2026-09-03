import 'dart:convert';

import 'package:faraid_engine/faraid_engine.dart';

import 'graph.dart';
import 'heir_extractor.dart';

/// Rekod simulasi kematian yang BEKU (SPEC 2.7). Selepas dicipta, ia tidak
/// pernah berubah walaupun graf sebenar dikemas kini kemudian.
class SimulationSnapshot {
  SimulationSnapshot({
    required this.id,
    required this.familyId,
    required this.deceasedId,
    required this.simulationDate,
    required this.createdAt,
    required this.graphJson,
    required this.result,
    required this.notes,
  });

  final String id;
  final String familyId;
  final String deceasedId;
  final DateTime simulationDate;
  final DateTime createdAt;

  /// Salinan penuh graf pada masa simulasi (immutable).
  final Map<String, Object?> graphJson;

  final FaraidResult result;
  final List<String> notes;

  /// Bina simulasi: salin graf, ekstrak waris, jalankan enjin.
  factory SimulationSnapshot.run({
    required String id,
    required FamilyGraph graph,
    required String deceasedId,
    required DateTime simulationDate,
    DateTime? createdAt,
    Money? netEstate,
    Ruleset ruleset = Ruleset.malaysiaSyafieV1,
    FaraidEngine engine = const FaraidEngine(),
  }) {
    final frozen = graph.deepCopy();
    final extraction = HeirExtractor(frozen).extractHeirs(
      deceasedId: deceasedId,
      simulationDate: simulationDate,
      ruleset: ruleset,
      netEstate: netEstate,
    );
    final result = engine.calculate(extraction.input);
    return SimulationSnapshot(
      id: id,
      familyId: frozen.familyId,
      deceasedId: deceasedId,
      simulationDate: simulationDate,
      createdAt: createdAt ?? DateTime.now(),
      graphJson: frozen.toJson(),
      result: result,
      notes: extraction.notes,
    );
  }

  FamilyGraph get graph => FamilyGraph.fromJson(graphJson);

  Map<String, Object?> toJson() => {
        'id': id,
        'familyId': familyId,
        'deceasedId': deceasedId,
        'simulationDate': simulationDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'rulesetVersion': result.rulesetVersion,
        'snapshotJson': jsonEncode(graphJson),
        'resultJson': jsonEncode(result.toJson()),
        'notes': notes,
      };
}
