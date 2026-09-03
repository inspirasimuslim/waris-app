import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/family_repository.dart';
import '../../state/providers.dart';

/// Pilihan hubungan untuk "Tap → Connect → pilih hubungan" (SPEC 3.1).
class _Rel {
  const _Rel(this.label, this.emoji, this.relation, this.forcedGender);
  final String label;
  final String emoji;
  final DirectRelation relation;
  final Gender? forcedGender;
}

const _relations = <_Rel>[
  _Rel('Pasangan', '❤️', DirectRelation.spouse, null),
  _Rel('Bapa', '👨', DirectRelation.father, Gender.male),
  _Rel('Ibu', '👩', DirectRelation.mother, Gender.female),
  _Rel('Anak lelaki', '👦', DirectRelation.son, Gender.male),
  _Rel('Anak perempuan', '👧', DirectRelation.daughter, Gender.female),
  _Rel('Adik-beradik', '👫', DirectRelation.siblingFull, null),
];

Future<void> showConnectSheet(BuildContext context, WidgetRef ref, String anchorId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ConnectSheet(anchorId: anchorId),
  );
}

class _ConnectSheet extends ConsumerWidget {
  const _ConnectSheet({required this.anchorId});
  final String anchorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hubungkan seseorang',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final r in _relations)
              ListTile(
                key: ValueKey('rel_${r.relation.name}'),
                leading: Text(r.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(r.label),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _showAddPerson(context, ref, anchorId, r);
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddPerson(
    BuildContext context, WidgetRef ref, String anchorId, _Rel rel) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _AddPersonForm(anchorId: anchorId, rel: rel),
    ),
  );
}

class _AddPersonForm extends ConsumerStatefulWidget {
  const _AddPersonForm({required this.anchorId, required this.rel});
  final String anchorId;
  final _Rel rel;

  @override
  ConsumerState<_AddPersonForm> createState() => _AddPersonFormState();
}

class _AddPersonFormState extends ConsumerState<_AddPersonForm> {
  final _name = TextEditingController();
  late Gender _gender = widget.rel.forcedGender ?? Gender.male;
  bool _alive = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    final repo = ref.read(familyRepositoryProvider);
    final p = await repo.addPerson(
      name: _name.text,
      gender: _gender,
      status: _alive ? LifeStatus.alive : LifeStatus.deceased,
    );
    await repo.connect(
      anchorId: widget.anchorId,
      otherId: p.id,
      relation: widget.rel.relation,
    );
    ref.read(smartSuggestionProvider.notifier).state =
        _suggestionFor(widget.rel.relation);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final needsGender = widget.rel.forcedGender == null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.rel.emoji}  ${widget.rel.label}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('field_name'),
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (needsGender) ...[
              const SizedBox(height: 12),
              SegmentedButton<Gender>(
                segments: const [
                  ButtonSegment(value: Gender.male, label: Text('Lelaki')),
                  ButtonSegment(value: Gender.female, label: Text('Perempuan')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Hidup')),
                ButtonSegment(value: false, label: Text('Meninggal')),
              ],
              selected: {_alive},
              onSelectionChanged: (s) => setState(() => _alive = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('btn_add_person'),
              onPressed: _busy ? null : _submit,
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

String _suggestionFor(DirectRelation r) => switch (r) {
      DirectRelation.spouse => 'Tambah anak?',
      DirectRelation.son || DirectRelation.daughter => 'Tambah datuk nenek mereka?',
      DirectRelation.father => 'Tambah ibu bapa kepada bapa?',
      DirectRelation.mother => 'Tambah ibu bapa kepada ibu?',
      DirectRelation.siblingFull => 'Tambah anak-anak mereka?',
    };
