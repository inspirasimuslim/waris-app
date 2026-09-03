import 'package:faraid_engine/faraid_engine.dart' show Gender;

import 'enums.dart';

export 'package:faraid_engine/faraid_engine.dart' show Gender;

/// Seorang individu dalam graf keluarga (SPEC 2.2).
class Person {
  Person({
    required this.id,
    required this.familyId,
    required this.name,
    required this.gender,
    this.fullName,
    this.birthDate,
    this.status = LifeStatus.alive,
    this.deathDate,
    this.photoPath,
    this.notes,
    this.isSelf = false,
  });

  final String id;
  final String familyId;
  final String name;
  final String? fullName;
  final Gender gender;
  final DateTime? birthDate;
  final LifeStatus status;
  final DateTime? deathDate;
  final String? photoPath;
  final String? notes;
  final bool isSelf;

  /// Adakah orang ini hidup pada [date]?
  ///
  /// `deceased` dengan `deathDate` selepas [date] dikira masih hidup pada masa
  /// itu (berguna untuk simulasi bersejarah). `unknown` dianggap TIDAK hidup
  /// untuk tujuan pengiraan — enjin membendera, bukan meneka.
  bool isAliveOn(DateTime date) {
    switch (status) {
      case LifeStatus.alive:
        return true;
      case LifeStatus.unknown:
        return false;
      case LifeStatus.deceased:
        final d = deathDate;
        return d != null && d.isAfter(date);
    }
  }

  Person copyWith({
    String? name,
    String? fullName,
    Gender? gender,
    DateTime? birthDate,
    LifeStatus? status,
    DateTime? deathDate,
    String? photoPath,
    String? notes,
    bool? isSelf,
  }) =>
      Person(
        id: id,
        familyId: familyId,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        fullName: fullName ?? this.fullName,
        birthDate: birthDate ?? this.birthDate,
        status: status ?? this.status,
        deathDate: deathDate ?? this.deathDate,
        photoPath: photoPath ?? this.photoPath,
        notes: notes ?? this.notes,
        isSelf: isSelf ?? this.isSelf,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'familyId': familyId,
        'name': name,
        'fullName': fullName,
        'gender': gender.name,
        'birthDate': birthDate?.toIso8601String(),
        'status': status.name,
        'deathDate': deathDate?.toIso8601String(),
        'photoPath': photoPath,
        'notes': notes,
        'isSelf': isSelf,
      };

  static Person fromJson(Map<String, Object?> j) => Person(
        id: j['id']! as String,
        familyId: j['familyId']! as String,
        name: j['name']! as String,
        gender:
            (j['gender'] as String?) == 'female' ? Gender.female : Gender.male,
        fullName: j['fullName'] as String?,
        birthDate: _date(j['birthDate']),
        status: LifeStatus.values.byName((j['status'] as String?) ?? 'alive'),
        deathDate: _date(j['deathDate']),
        photoPath: j['photoPath'] as String?,
        notes: j['notes'] as String?,
        isSelf: (j['isSelf'] as bool?) ?? false,
      );
}

/// Pertalian anak → seorang ibu bapa (SPEC 2.2). Berasingan untuk bapa dan ibu
/// supaya "ibu disahkan, bapa tidak sabit" boleh diwakili.
class ParentLink {
  ParentLink({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.role,
    this.nasabStatus = NasabStatus.confirmed,
    this.kind = LinkKind.biological,
    this.isPrivate = true,
  });

  final String id;
  final String childId;
  final String parentId;
  final ParentRole role;
  final NasabStatus nasabStatus;
  final LinkKind kind;
  final bool isPrivate;

  /// Melayakkan pewarisan faraid: nasab sabit DAN pertalian biologi.
  /// Anak angkat / anak tiri tidak mewarisi melalui pertalian ini.
  bool get inherits =>
      nasabStatus.inheritsByNasab && kind == LinkKind.biological;

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId,
        'parentId': parentId,
        'role': role.name,
        'nasabStatus': nasabStatus.name,
        'kind': kind.name,
        'isPrivate': isPrivate,
      };

  static ParentLink fromJson(Map<String, Object?> j) => ParentLink(
        id: j['id']! as String,
        childId: j['childId']! as String,
        parentId: j['parentId']! as String,
        role: ParentRole.values.byName(j['role']! as String),
        nasabStatus:
            NasabStatus.values.byName((j['nasabStatus'] as String?) ?? 'confirmed'),
        kind: LinkKind.values.byName((j['kind'] as String?) ?? 'biological'),
        isPrivate: (j['isPrivate'] as bool?) ?? true,
      );
}

/// Pertalian perkahwinan (SPEC 2.2).
class SpouseLink {
  SpouseLink({
    required this.id,
    required this.personAId,
    required this.personBId,
    required this.status,
    this.marriageDate,
    this.endDate,
    this.order,
  });

  final String id;
  final String personAId;
  final String personBId;
  final MarriageStatus status;
  final DateTime? marriageDate;
  final DateTime? endDate;

  /// Untuk poligami: isteri pertama, kedua...
  final int? order;

  /// Adakah pasangan ini mewarisi antara satu sama lain? Hanya perkahwinan
  /// yang MASIH sah pada tarikh kematian (bukan cerai) melayakkan pewarisan.
  bool get inherits => status == MarriageStatus.married;

  bool involves(String personId) =>
      personId == personAId || personId == personBId;

  String other(String personId) => personId == personAId ? personBId : personAId;

  Map<String, Object?> toJson() => {
        'id': id,
        'personAId': personAId,
        'personBId': personBId,
        'status': status.name,
        'marriageDate': marriageDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'order': order,
      };

  static SpouseLink fromJson(Map<String, Object?> j) => SpouseLink(
        id: j['id']! as String,
        personAId: j['personAId']! as String,
        personBId: j['personBId']! as String,
        status: MarriageStatus.values.byName(j['status']! as String),
        marriageDate: _date(j['marriageDate']),
        endDate: _date(j['endDate']),
        order: j['order'] as int?,
      );
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String);
