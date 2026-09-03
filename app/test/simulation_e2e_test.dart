import 'package:faraid_engine/faraid_engine.dart';
import 'package:family_graph/family_graph.dart' show LifeStatus;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:waris_app/core/theme.dart';
import 'package:waris_app/data/family_repository.dart';
import 'package:waris_app/features/network/network_screen.dart';
import 'package:waris_app/features/simulation/simulation_screen.dart';
import 'package:waris_app/l10n/app_localizations.dart';
import 'package:waris_app/state/providers.dart';

Widget _harness(FamilyRepository repo, {Widget? home}) => ProviderScope(
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
        home: home ?? const NetworkScreen(),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting('ms'));

  testWidgets(
      'hujung-ke-hujung: bina keluarga -> simulasi -> angka padan Fasa 1 (FRD-106 umariyyatain)',
      (tester) async {
    final repo = InMemoryFamilyRepository(familyId: 'e2e');
    await repo.load();
    final d = await repo.addPerson(
        name: 'Fatimah', gender: Gender.female, isSelf: true);
    final h = await repo.addPerson(name: 'Ali', gender: Gender.male);
    final f = await repo.addPerson(name: 'Bapa', gender: Gender.male);
    final m = await repo.addPerson(name: 'Ibu', gender: Gender.female);
    await repo.connect(
        anchorId: d.id, otherId: h.id, relation: DirectRelation.spouse);
    await repo.connect(
        anchorId: d.id, otherId: f.id, relation: DirectRelation.father);
    await repo.connect(
        anchorId: d.id, otherId: m.id, relation: DirectRelation.mother);

    await tester.pumpWidget(_harness(repo,
        home: SimulationFlow(deceasedId: d.id, deceasedName: 'Fatimah')));
    await tester.pumpAndSettle();

    // Intro -> Teruskan
    await tester.tap(find.byKey(const ValueKey('btn_sim_continue')));
    await tester.pumpAndSettle();

    // Skrin waris: suami, bapa, ibu dikenal pasti
    expect(find.byKey(const ValueKey('heir_husband')), findsOneWidget);
    expect(find.byKey(const ValueKey('heir_father')), findsOneWidget);
    expect(find.byKey(const ValueKey('heir_mother')), findsOneWidget);
    // Penafian pada skrin
    expect(find.textContaining('bukan pengesahan rasmi'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('btn_sim_to_estate')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('field_gross')), '120000');
    await tester.tap(find.byKey(const ValueKey('btn_estate_done')));
    await tester.pumpAndSettle();

    // Keputusan: padan FRD-106 (H 1/2=RM60000, M 1/6=RM20000, F 1/3=RM40000)
    final snap = repo.simulations.first;
    final r = snap.result;
    Fraction sh(HeirType t) => r.shares.firstWhere((s) => s.type == t).shareTotal;
    Money amt(HeirType t) =>
        r.shares.firstWhere((s) => s.type == t).amountTotal!;
    expect(sh(HeirType.husband), Fraction(1, 2));
    expect(sh(HeirType.mother), Fraction(1, 6));
    expect(sh(HeirType.father), Fraction(1, 3));
    expect(amt(HeirType.husband), Money.ringgit(60000));
    expect(amt(HeirType.mother), Money.ringgit(20000));
    expect(amt(HeirType.father), Money.ringgit(40000));
    expect(r.asalMasalah, 6);

    // Butang "Kenapa?" membuka penerangan daripada trace
    await tester.ensureVisible(find.byKey(const ValueKey('btn_why_mother')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn_why_mother')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/3 daripada BAKI'), findsOneWidget);
  });

  testWidgets('snapshot direkod dalam sejarah simulasi (SPEC 4.6)',
      (tester) async {
    final repo = InMemoryFamilyRepository(familyId: 'hist');
    await repo.load();
    final d =
        await repo.addPerson(name: 'Ahmad', gender: Gender.male, isSelf: true);
    final w = await repo.addPerson(name: 'Aisyah', gender: Gender.female);
    final s1 = await repo.addPerson(name: 'Ali', gender: Gender.male);
    await repo.connect(
        anchorId: d.id, otherId: w.id, relation: DirectRelation.spouse);
    await repo.connect(
        anchorId: d.id, otherId: s1.id, relation: DirectRelation.son);

    await repo.runSimulation(
        deceasedId: d.id, simulationDate: DateTime(2026, 9, 3));

    await tester.pumpWidget(_harness(repo, home: const SimulationHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.textContaining('waris'), findsWidgets);
  });

  testWidgets('kes di luar skop MVP dibendera pada skrin waris', (tester) async {
    final repo = InMemoryFamilyRepository(familyId: 'flag');
    await repo.load();
    // Musyarakah: suami + ibu + 2 saudara seibu + saudara lelaki s.i.s
    final d =
        await repo.addPerson(name: 'Zahra', gender: Gender.female, isSelf: true);
    final h = await repo.addPerson(name: 'Umar', gender: Gender.male);
    final mo = await repo.addPerson(name: 'Ibu', gender: Gender.female);
    final ms1 = await repo.addPerson(name: 'MS1', gender: Gender.male);
    final ms2 = await repo.addPerson(name: 'MS2', gender: Gender.female);
    final fb = await repo.addPerson(name: 'FB', gender: Gender.male);
    await repo.connect(
        anchorId: d.id, otherId: h.id, relation: DirectRelation.spouse);
    await repo.connect(
        anchorId: d.id, otherId: mo.id, relation: DirectRelation.mother);
    // saudara seibu: kongsi ibu sahaja. Bapa si mati mesti telah meninggal
    // supaya kalalah + musyarakah terpakai.
    final fatherOfDeceased = await repo.addPerson(
        name: 'BapaZ',
        gender: Gender.male,
        status: LifeStatus.deceased,
        deathDate: DateTime(2000));
    await repo.connect(
        anchorId: d.id, otherId: fatherOfDeceased.id,
        relation: DirectRelation.father);
    for (final ms in [ms1, ms2]) {
      await repo.connect(
          anchorId: mo.id, otherId: ms.id, relation: DirectRelation.son);
    }
    // saudara s.i.s: kongsi kedua ibu bapa
    await repo.connect(
        anchorId: fatherOfDeceased.id, otherId: fb.id,
        relation: DirectRelation.son);
    await repo.connect(
        anchorId: mo.id, otherId: fb.id, relation: DirectRelation.son);

    await tester.pumpWidget(_harness(repo,
        home: SimulationFlow(deceasedId: d.id, deceasedName: 'Zahra')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn_sim_continue')));
    await tester.pumpAndSettle();

    expect(repo.simulations.first.result.status,
        ResultStatus.requiresManualReview);
    expect(find.textContaining('semakan manual'), findsWidgets);
  });
}
