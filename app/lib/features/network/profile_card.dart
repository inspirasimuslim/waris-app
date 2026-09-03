import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../simulation/simulation_screen.dart';
import 'connect_sheet.dart';

/// Kad profil kontekstual (SPEC 3.5). Tindakan muncul berdasarkan siapa yang
/// dipilih, bukan bersembunyi dalam menu.
Future<void> showProfileCard(BuildContext context, WidgetRef ref, Person person) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ProfileCard(person: person),
  );
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(familyGraphProvider).asData?.value;
    final resolver = graph == null ? null : RelationshipResolver(graph);
    final deceased = person.status == LifeStatus.deceased;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(
                      person.name.isEmpty
                          ? '?'
                          : person.name.characters.first,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(person.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(deceased ? '🔴 Meninggal' : '🟢 Hidup'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (resolver != null) ..._relations(context, resolver),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('btn_profile_connect'),
              onPressed: () {
                // Tangkap navigator SEBELUM pop; `context` kad profil mati
                // selepas pop (punca ranap sebelum ini).
                final navigator = Navigator.of(context);
                navigator.pop();
                showConnectSheet(navigator.context, ref, person.id);
              },
              icon: const Icon(Icons.add),
              label: const Text('Hubungkan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('btn_focus_person'),
              onPressed: () {
                ref.read(focusPersonIdProvider.notifier).state = person.id;
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Fokus pada orang ini'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('btn_simulate_death'),
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                openSimulation(navigator.context, ref, person);
              },
              icon: const Icon(Icons.balance),
              label: const Text('Simulasi kematian'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _relations(BuildContext context, RelationshipResolver r) {
    final father = r.parentOf(person.id, ParentRole.father);
    final mother = r.parentOf(person.id, ParentRole.mother);
    final spouses = r.currentSpouses(person.id);
    final children = r.childrenOf(person.id);
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(width: 96, child: Text(label)),
              Expanded(child: Text(value)),
            ],
          ),
        );
    return [
      if (father != null) row('Bapa', father.name),
      if (mother != null) row('Ibu', mother.name),
      if (spouses.isNotEmpty) row('Pasangan', spouses.map((p) => p.name).join(', ')),
      if (children.isNotEmpty) row('Anak', '${children.length}'),
    ];
  }
}
