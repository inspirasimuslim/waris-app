import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../simulation/simulation_screen.dart';
import 'connect_sheet.dart';
import 'graph_view.dart';
import 'profile_card.dart';

/// Homepage WARIS: Family Network, bukan dashboard kad (SPEC A3 prinsip 3).
class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  int _up = 1;
  int _down = 1;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(familyGraphProvider);
    final self = ref.watch(selfPersonProvider);
    final suggestion = ref.watch(smartSuggestionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keluarga saya'),
        actions: [
          IconButton(
            key: const ValueKey('btn_history'),
            icon: const Icon(Icons.history),
            tooltip: 'Simulasi saya',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SimulationHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
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
          final focusPerson = graph.person(focusId) ?? self;
          return Column(
            children: [
              _FocusBar(
                name: focusPerson.name,
                showAll: _showAll,
                onExpand: () => setState(() {
                  _up += 1;
                  _down += 1;
                }),
                onToggleAll: () => setState(() => _showAll = !_showAll),
                onResetToSelf: focusId == self.id
                    ? null
                    : () => ref.read(focusPersonIdProvider.notifier).state =
                        self.id,
              ),
              if (suggestion != null)
                _SuggestionBar(
                  text: suggestion,
                  onDismiss: () =>
                      ref.read(smartSuggestionProvider.notifier).state = null,
                ),
              Expanded(
                child: FamilyGraphView(
                  graph: graph,
                  focusId: focusId,
                  generationsUp: _up,
                  generationsDown: _down,
                  showAll: _showAll,
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

/// Penunjuk Mod Fokus (SPEC 3.4): hanya 3 generasi kelihatan pada satu masa.
class _FocusBar extends StatelessWidget {
  const _FocusBar({
    required this.name,
    required this.showAll,
    required this.onExpand,
    required this.onToggleAll,
    required this.onResetToSelf,
  });
  final String name;
  final bool showAll;
  final VoidCallback onExpand;
  final VoidCallback onToggleAll;
  final VoidCallback? onResetToSelf;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            const Icon(Icons.center_focus_strong, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Fokus: $name',
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis),
            ),
            if (onResetToSelf != null)
              TextButton(onPressed: onResetToSelf, child: const Text('Saya')),
            if (!showAll)
              TextButton(
                key: const ValueKey('btn_expand'),
                onPressed: onExpand,
                child: const Text('Kembangkan'),
              ),
            TextButton(
              key: const ValueKey('btn_show_all'),
              onPressed: onToggleAll,
              child: Text(showAll ? 'Mod fokus' : 'Lihat semua'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWithOnePerson extends StatelessWidget {
  const _StartWithOnePerson({required this.onCreate});
  final Future<void> Function(String name) onCreate;

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
      await onCreate(name.trim());
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
