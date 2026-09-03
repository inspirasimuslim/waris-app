import 'package:faraid_engine/faraid_engine.dart';
import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/providers.dart';
import 'why_templates.dart';

final _rm = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 2);

void openSimulation(BuildContext context, WidgetRef ref, Person deceased) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SimulationFlow(deceasedId: deceased.id, deceasedName: deceased.name),
  ));
}

class SimulationFlow extends ConsumerStatefulWidget {
  const SimulationFlow({
    super.key,
    required this.deceasedId,
    required this.deceasedName,
  });
  final String deceasedId;
  final String deceasedName;

  @override
  ConsumerState<SimulationFlow> createState() => _SimulationFlowState();
}

class _SimulationFlowState extends ConsumerState<SimulationFlow> {
  int _step = 0; // 0 intro, 1 waris, 2 harta, 3 keputusan
  SimulationSnapshot? _snapshot;
  Money? _netEstate;

  Future<void> _runSnapshot() async {
    final repo = ref.read(familyRepositoryProvider);
    final snap = await repo.runSimulation(
      deceasedId: widget.deceasedId,
      simulationDate: DateTime.now(),
      netEstate: _netEstate,
    );
    setState(() {
      _snapshot = snap;
      _step = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simulasi — ${widget.deceasedName}')),
      body: switch (_step) {
        0 => _Intro(name: widget.deceasedName, onContinue: _runSnapshot),
        1 => _HeirList(
            snapshot: _snapshot!,
            onNext: () => setState(() => _step = 2),
          ),
        2 => _EstateInput(
            onDone: (net) async {
              _netEstate = net;
              await _runSnapshot();
              setState(() => _step = 3);
            },
            onSkip: () => setState(() => _step = 3),
          ),
        _ => _ResultView(snapshot: _snapshot!),
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.name, required this.onContinue});
  final String name;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Jika $name meninggal dunia hari ini...',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Sistem akan mencipta snapshot beku keadaan keluarga anda dan '
            'mengira daripada salinan itu. Data sebenar tidak berubah.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('btn_sim_continue'),
            onPressed: onContinue,
            child: const Text('Teruskan'),
          ),
        ],
      ),
    );
  }
}

class _HeirList extends StatelessWidget {
  const _HeirList({required this.snapshot, required this.onNext});
  final SimulationSnapshot snapshot;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final r = snapshot.result;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (r.status == ResultStatus.requiresManualReview)
                _WarningBanner(warnings: r.warnings),
              Text('WARIS YANG DIKENAL PASTI',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final s in r.shares)
                ListTile(
                  key: ValueKey('heir_${s.type.name}'),
                  leading: const Text('🟢'),
                  title: Text('${heirLabel(s.type)}'
                      '${s.count > 1 ? ' ×${s.count}' : ''}'),
                  subtitle: Text('Bahagian ${s.shareTotal}'),
                ),
              if (r.blocked.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('TIDAK MEWARISI',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                for (final b in r.blocked)
                  ListTile(
                    leading: const Text('🔴'),
                    title: Text(heirLabel(b.type)),
                    subtitle: Text(b.reason),
                  ),
              ],
              if (snapshot.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('UNTUK SIMULASI YANG LEBIH TEPAT',
                    style: Theme.of(context).textTheme.labelLarge),
                for (final n in snapshot.notes)
                  ListTile(leading: const Text('⚠️'), title: Text(n)),
              ],
            ],
          ),
        ),
        const _DisclaimerFooter(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const ValueKey('btn_sim_to_estate'),
            onPressed: onNext,
            child: const Text('Masukkan nilai harta (boleh dilangkau)'),
          ),
        ),
      ],
    );
  }
}

class _EstateInput extends StatefulWidget {
  const _EstateInput({required this.onDone, required this.onSkip});
  final Future<void> Function(Money net) onDone;
  final VoidCallback onSkip;

  @override
  State<_EstateInput> createState() => _EstateInputState();
}

class _EstateInputState extends State<_EstateInput> {
  final _gross = TextEditingController();
  final _funeral = TextEditingController();
  final _debt = TextEditingController();
  final _wasiat = TextEditingController();

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  Money get _net => Money.ringgit(
      (_n(_gross) - _n(_funeral) - _n(_debt) - _n(_wasiat)).clamp(0, 1e15));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Aset kasar dan tolakan. Wasiat/hibah/harta sepencarian '
            'TIDAK ditolak automatik — sila dapatkan pengesahan profesional.'),
        const SizedBox(height: 12),
        _field(_gross, 'Jumlah aset kasar', const ValueKey('field_gross')),
        _field(_funeral, 'Pengurusan jenazah', null),
        _field(_debt, 'Hutang', null),
        _field(_wasiat, 'Wasiat', null),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: Listenable.merge([_gross, _funeral, _debt, _wasiat]),
          builder: (_, _) => Text('Harta pusaka bersih: ${_rm.format(_net.ringgit)}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('btn_estate_done'),
          onPressed: () => widget.onDone(_net),
          child: const Text('Kira dengan nilai ini'),
        ),
        TextButton(
          key: const ValueKey('btn_estate_skip'),
          onPressed: widget.onSkip,
          child: const Text('Langkau — tunjuk siapa sahaja'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, Key? key) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          key: key,
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            prefixText: 'RM ',
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.snapshot});
  final SimulationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final r = snapshot.result;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (r.netEstate != null)
                Text('HARTA PUSAKA BERSIH\n${_rm.format(r.netEstate!.ringgit)}',
                    style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Asal masalah: ${r.asalMasalah}'
                  '${r.asalMasalahAfterTashih != r.asalMasalah ? ' → ditashih kepada ${r.asalMasalahAfterTashih}' : ''}'),
              const SizedBox(height: 12),
              for (final s in r.shares)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${heirLabel(s.type)}'
                            '${s.count > 1 ? ' ×${s.count}' : ''}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${s.shareTotal}'
                            '${s.count > 1 ? '  (setiap seorang ${s.shareEach})' : ''}'),
                        if (s.amountTotal != null)
                          Text(_rm.format(s.amountTotal!.ringgit)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: ValueKey('btn_why_${s.type.name}'),
                            onPressed: () => _showWhy(context, s, r),
                            child: const Text('Kenapa? ▼'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const _DisclaimerFooter(),
      ],
    );
  }

  void _showWhy(BuildContext context, HeirShare s, FaraidResult r) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kenapa ${heirLabel(s.type)} mendapat ${s.shareTotal}?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(whyText(s, r)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.warnings});
  final List<Warning> warnings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Kes ini memerlukan semakan manual',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final w in warnings) Text('• ${w.message}'),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
      child: Text(disclaimerText,
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Sejarah simulasi (SPEC 4.6).
class SimulationHistoryScreen extends ConsumerWidget {
  const SimulationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sims = ref.watch(simulationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi saya')),
      body: sims.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Belum ada simulasi'))
            : ListView(
                children: [
                  for (final s in list)
                    ListTile(
                      leading: const Text('⚖️'),
                      title: Text(s.graph.person(s.deceasedId)?.name ?? '—'),
                      subtitle: Text(
                        '${DateFormat('d MMM yyyy', 'ms').format(s.createdAt)} · '
                        '${s.result.shares.length} waris · '
                        '${s.netEstate == null ? 'tiada harta dimasukkan' : _rm.format(s.netEstate!.ringgit)}',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Simulasi lalu')),
                            body: _ResultView(snapshot: s),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
