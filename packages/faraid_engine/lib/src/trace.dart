import 'enums.dart';
import 'fraction.dart';

/// Satu langkah dalam jejak pengiraan (SPEC 1.7). Sumber untuk butang "Kenapa?".
class TraceStep {
  const TraceStep(
    this.phase,
    this.message, {
    this.affected = const [],
    this.fraction,
    this.reasonCode,
  });

  /// Fasa aliran pengiraan: `validation`, `nasab`, `hajb`, `furud`,
  /// `asabah`, `aul`, `radd`, `tashih`, `special`, `money`, `validate`.
  final String phase;
  final String message;
  final List<HeirType> affected;
  final Fraction? fraction;
  final String? reasonCode;

  Map<String, Object?> toJson() => {
        'phase': phase,
        'message': message,
        if (affected.isNotEmpty)
          'affected': affected.map((e) => e.name).toList(),
        if (fraction != null) 'fraction': fraction.toString(),
        if (reasonCode != null) 'reasonCode': reasonCode,
      };

  @override
  String toString() => '[$phase] $message';
}

class CalculationTrace {
  CalculationTrace([List<TraceStep>? steps]) : steps = steps ?? <TraceStep>[];

  final List<TraceStep> steps;

  void add(
    String phase,
    String message, {
    List<HeirType> affected = const [],
    Fraction? fraction,
    String? reasonCode,
  }) {
    steps.add(TraceStep(
      phase,
      message,
      affected: affected,
      fraction: fraction,
      reasonCode: reasonCode,
    ));
  }

  List<Map<String, Object?>> toJson() =>
      steps.map((s) => s.toJson()).toList(growable: false);
}

class Warning {
  const Warning(this.level, this.code, this.message);
  final WarningLevel level;
  final String code;
  final String message;

  Map<String, Object?> toJson() =>
      {'level': level.name, 'code': code, 'message': message};

  @override
  String toString() => '${level.name.toUpperCase()} $code: $message';
}
