import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:family_graph/family_graph.dart';
import 'package:uuid/uuid.dart';

/// Akses kepada graf keluarga tempatan. Local-first (SPEC A5): graf hidup di
/// device dan berfungsi sepenuhnya tanpa internet.
abstract class FamilyRepository {
  FamilyGraph get graph;

  /// Aliran yang memancarkan graf terkini setiap kali ia berubah.
  Stream<FamilyGraph> watch();

  Future<void> load();

  Future<Person> addPerson({
    required String name,
    required Gender gender,
    LifeStatus status = LifeStatus.alive,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isSelf = false,
  });

  Future<void> updatePerson(Person person);

  /// Sambungkan [otherId] kepada [anchorId] melalui hubungan LANGSUNG sahaja
  /// (SPEC A3 prinsip 2 & 4). [relation] ialah salah satu:
  /// spouse, father, mother, son, daughter, sibling.
  Future<void> connect({
    required String anchorId,
    required String otherId,
    required DirectRelation relation,
    NasabStatus nasabStatus = NasabStatus.confirmed,
  });

  Future<void> save();
}

enum DirectRelation { spouse, father, mother, son, daughter, siblingFull }

/// Simpanan dalam-memori dengan kegigihan JSON pada cakera (SPEC Fasa 3 DoD:
/// "Data kekal selepas app ditutup"). Lapisan Drift/SQLite penuh dijadualkan
/// selepas APK pertama (lihat DECISIONS D-016).
class InMemoryFamilyRepository implements FamilyRepository {
  InMemoryFamilyRepository({required this.familyId, this.file});

  final String familyId;

  /// Fail JSON kegigihan; `null` bermakna tiada kegigihan (ujian).
  final File? file;

  final _uuid = const Uuid();
  late FamilyGraph _graph = FamilyGraph(familyId: familyId);
  final _listeners = <MultiStreamController<FamilyGraph>>{};

  @override
  FamilyGraph get graph => _graph;

  @override
  Stream<FamilyGraph> watch() => Stream<FamilyGraph>.multi((controller) {
        controller.add(_graph); // nilai semasa serta-merta
        _listeners.add(controller);
        controller.onCancel = () => _listeners.remove(controller);
      });

  void _emit() {
    // Instance BAHARU setiap kali supaya Riverpod (yang menyahduplikasi state
    // yang `==`) mengesan perubahan walaupun kandungan diubah di tempat.
    _graph = FamilyGraph(
      familyId: _graph.familyId,
      persons: _graph.persons.toList(),
      parentLinks: _graph.parentLinks.toList(),
      spouseLinks: _graph.spouseLinks.toList(),
    );
    for (final l in _listeners.toList()) {
      l.add(_graph);
    }
  }

  @override
  Future<void> load() async {
    final f = file;
    if (f != null && await f.exists()) {
      final json = jsonDecode(await f.readAsString()) as Map<String, Object?>;
      _graph = FamilyGraph.fromJson(json);
    }
    _emit();
  }

  @override
  Future<void> save() async {
    final f = file;
    if (f == null) return;
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(_graph.toJson()));
  }

  @override
  Future<Person> addPerson({
    required String name,
    required Gender gender,
    LifeStatus status = LifeStatus.alive,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isSelf = false,
  }) async {
    final p = Person(
      id: _uuid.v4(),
      familyId: familyId,
      name: name.trim(),
      gender: gender,
      status: status,
      birthDate: birthDate,
      deathDate: deathDate,
      isSelf: isSelf,
    );
    _graph.addPerson(p);
    _emit();
    await save();
    return p;
  }

  @override
  Future<void> updatePerson(Person person) async {
    _graph.addPerson(person); // gantikan mengikut id
    _emit();
    await save();
  }

  @override
  Future<void> connect({
    required String anchorId,
    required String otherId,
    required DirectRelation relation,
    NasabStatus nasabStatus = NasabStatus.confirmed,
  }) async {
    switch (relation) {
      case DirectRelation.spouse:
        _graph.addSpouseLink(SpouseLink(
          id: _uuid.v4(),
          personAId: anchorId,
          personBId: otherId,
          status: MarriageStatus.married,
        ));
      case DirectRelation.father:
        _graph.addParentLink(_parent(otherId, anchorId, ParentRole.father, nasabStatus));
      case DirectRelation.mother:
        _graph.addParentLink(_parent(otherId, anchorId, ParentRole.mother, nasabStatus));
      case DirectRelation.son:
      case DirectRelation.daughter:
        // "otherId" ialah anak kepada anchor. Peranan ibu bapa ditentukan oleh
        // jantina anchor.
        final anchor = _graph.requirePerson(anchorId);
        _graph.addParentLink(_parent(
          anchorId,
          otherId,
          anchor.gender == Gender.male ? ParentRole.father : ParentRole.mother,
          nasabStatus,
        ));
      case DirectRelation.siblingFull:
        // Adik-beradik disimpan sebagai kongsi ibu bapa (SPEC 2.1: simpan
        // hubungan langsung, terbitkan yang lain). Jika anchor sudah ada ibu
        // bapa, gunakan yang sama; jika tidak, cipta ibu bapa "placeholder".
        _shareParents(anchorId, otherId);
    }
    _emit();
    await save();
  }

  ParentLink _parent(
          String parentId, String childId, ParentRole role, NasabStatus n) =>
      ParentLink(
        id: _uuid.v4(),
        childId: childId,
        parentId: parentId,
        role: role,
        nasabStatus: n,
      );

  void _shareParents(String anchorId, String siblingId) {
    for (final role in ParentRole.values) {
      var link = _graph.parentLink(anchorId, role);
      if (link == null) {
        final placeholder = Person(
          id: _uuid.v4(),
          familyId: familyId,
          name: role == ParentRole.father ? 'Bapa' : 'Ibu',
          gender: role == ParentRole.father ? Gender.male : Gender.female,
          status: LifeStatus.unknown,
        );
        _graph.addPerson(placeholder);
        link = _parent(placeholder.id, anchorId, role, NasabStatus.confirmed);
        _graph.addParentLink(link);
      }
      _graph.addParentLink(
          _parent(link.parentId, siblingId, role, NasabStatus.confirmed));
    }
  }
}
