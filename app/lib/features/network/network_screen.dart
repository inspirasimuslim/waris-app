import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import 'connect_sheet.dart';
import 'graph_view.dart';
import 'profile_card.dart';

/// Homepage WARIS: Family Network, bukan dashboard kad (SPEC A3 prinsip 3).
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(familyGraphProvider);
    final self = ref.watch(selfPersonProvider);
    final suggestion = ref.watch(smartSuggestionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Keluarga saya')),
      body: graphAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ralat: $e')),
        data: (graph) {
          if (graph.persons.isEmpty || self == null) {
            return _StartWithOnePerson(
              onCreate: (name) async {
                final repo = ref.read(familyRepositoryProvider);
                final me = await repo.addPerson(
                  name: name,
                  gender: Gender.male,
                  isSelf: true,
                );
                ref.read(focusPersonIdProvider.notifier).state = me.id;
              },
            );
          }
          final focusId = ref.watch(focusPersonIdProvider) ?? self.id;
          return Column(
            children: [
              if (suggestion != null)
                _SuggestionBar(
                  text: suggestion,
                  onDismiss: () => ref
                      .read(smartSuggestionProvider.notifier)
                      .state = null,
                ),
              Expanded(
                child: FamilyGraphView(
                  graph: graph,
                  focusId: focusId,
                  onTapPerson: (p) => showProfileCard(context, ref, p),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: self == null
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('fab_connect'),
              onPressed: () => showConnectSheet(
                context,
                ref,
                ref.read(focusPersonIdProvider) ?? self.id,
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Hubungkan'),
            ),
    );
  }
}

class _StartWithOnePerson extends StatefulWidget {
  const _StartWithOnePerson({required this.onCreate});
  final Future<void> Function(String name) onCreate;

  @override
  State<_StartWithOnePerson> createState() => _StartWithOnePersonState();
}

class _StartWithOnePersonState extends State<_StartWithOnePerson> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 44)),
          const SizedBox(height: 12),
          Text('Saya', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('btn_start'),
            onPressed: () => _askName(context),
            child: const Text('Ketik untuk bermula'),
          ),
        ],
      ),
    );
  }

  Future<void> _askName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nama anda'),
        content: TextField(
          key: const ValueKey('field_self_name'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Mula'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await widget.onCreate(name.trim());
    }
  }
}

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Text('💡  '),
            Expanded(child: Text(text)),
            TextButton(onPressed: onDismiss, child: const Text('Langkau')),
          ],
        ),
      ),
    );
  }
}
