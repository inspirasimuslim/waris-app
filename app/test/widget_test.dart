import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waris_app/core/theme.dart';
import 'package:waris_app/data/family_repository.dart';
import 'package:waris_app/features/network/network_screen.dart';
import 'package:waris_app/l10n/app_localizations.dart';
import 'package:waris_app/state/providers.dart';

Widget _harness(FamilyRepository repo) => ProviderScope(
      overrides: [familyRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: warisLightTheme(),
        locale: const Locale('ms'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const NetworkScreen(),
      ),
    );

Future<InMemoryFamilyRepository> _repo() async {
  final r = InMemoryFamilyRepository(familyId: 'test');
  await r.load();
  return r;
}

void main() {
  testWidgets('Start With One Person -> cipta "Saya"', (tester) async {
    final repo = await _repo();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('btn_start')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('btn_start')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('field_self_name')), 'Ahmad');
    await tester.tap(find.text('Mula'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(repo.graph.persons.length, 1);
    expect(repo.graph.persons.first.isSelf, isTrue);
    expect(find.byKey(const ValueKey('fab_connect')), findsOneWidget);
    // Nod dirender.
    expect(find.text('Ahmad'), findsWidgets);
  });

  testWidgets('bottom sheet Hubungkan menunjukkan pilihan hubungan',
      (tester) async {
    final repo = await _repo();
    await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fab_connect')));
    await tester.pumpAndSettle();

    expect(find.text('Hubungkan seseorang'), findsOneWidget);
    for (final k in ['spouse', 'father', 'mother', 'son', 'daughter', 'siblingFull']) {
      expect(find.byKey(ValueKey('rel_$k')), findsOneWidget);
    }
  });

  testWidgets(
      'REGRESI: pilih jenis hubungan tidak meranapkan app (borang di tempat)',
      (tester) async {
    final repo = await _repo();
    await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fab_connect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rel_spouse')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // dulu: Null check on MediaQuery
    expect(find.byKey(const ValueKey('field_name')), findsOneWidget);

    // Butang kembali pulang ke senarai hubungan tanpa ranap.
    await tester.tap(find.byKey(const ValueKey('btn_add_person_back')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hubungkan seseorang'), findsOneWidget);
  });

  testWidgets(
      'REGRESI: "Hubungkan" dari kad profil tidak meranapkan (context selepas pop)',
      (tester) async {
    final repo = await _repo();
    final me =
        await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    final dad = await repo.addPerson(name: 'Abdullah', gender: Gender.male);
    await repo.connect(
        anchorId: me.id, otherId: dad.id, relation: DirectRelation.father);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abdullah').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn_profile_connect')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hubungkan seseorang'), findsOneWidget);
  });

  testWidgets(
      'REGRESI: "Simulasi kematian" dari kad profil membuka aliran tanpa ranap',
      (tester) async {
    final repo = await _repo();
    final me =
        await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    final w = await repo.addPerson(name: 'Aisyah', gender: Gender.female);
    await repo.connect(
        anchorId: me.id, otherId: w.id, relation: DirectRelation.spouse);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ahmad').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('btn_simulate_death')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn_simulate_death')),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('btn_sim_continue')), findsOneWidget);
  });

  testWidgets('tambah orang: Bapa -> isi nama -> nod baharu muncul',
      (tester) async {
    final repo = await _repo();
    await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fab_connect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rel_father')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('field_name')), 'Abdullah');
    await tester.tap(find.byKey(const ValueKey('btn_add_person')));
    await tester.pumpAndSettle();

    expect(repo.graph.persons.any((p) => p.name == 'Abdullah'), isTrue);
    final link = repo.graph.parentLink(
      repo.graph.persons.firstWhere((p) => p.isSelf).id,
      ParentRole.father,
    );
    expect(link, isNotNull);
    expect(find.text('Abdullah'), findsWidgets);
  });

  testWidgets('ketik nod membuka kad profil', (tester) async {
    final repo = await _repo();
    final me =
        await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    final dad = await repo.addPerson(name: 'Abdullah', gender: Gender.male);
    await repo.connect(
        anchorId: me.id, otherId: dad.id, relation: DirectRelation.father);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abdullah').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('btn_profile_connect')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn_focus_person')), findsOneWidget);
  });

  testWidgets('cadangan pintar muncul selepas menambah pasangan',
      (tester) async {
    final repo = await _repo();
    await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fab_connect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rel_spouse')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('field_name')), 'Aisyah');
    await tester.tap(find.byKey(const ValueKey('btn_add_person')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tambah anak?'), findsOneWidget);
  });
}
