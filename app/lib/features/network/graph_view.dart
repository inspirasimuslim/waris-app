import 'package:family_graph/family_graph.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Susun atur graf mengikut generasi (BFS dari orang fokus) dengan pasangan
/// bersebelahan, dilukis oleh [CustomPainter] dalam [InteractiveViewer]
/// (SPEC 3.3). Ringkas untuk MVP; penolakan berulang penuh menyusul.
class FamilyGraphView extends StatelessWidget {
  const FamilyGraphView({
    super.key,
    required this.graph,
    required this.focusId,
    required this.onTapPerson,
  });

  final FamilyGraph graph;
  final String focusId;
  final void Function(Person person) onTapPerson;

  @override
  Widget build(BuildContext context) {
    final layout = _GraphLayout.compute(graph, focusId);
    final size = layout.canvasSize;
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.4,
      maxScale: 3,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _EdgePainter(
                layout: layout,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            for (final node in layout.nodes.values)
              Positioned(
                left: node.center.dx - _nodeW / 2,
                top: node.center.dy - _nodeH / 2,
                width: _nodeW,
                height: _nodeH,
                child: _PersonNode(
                  person: node.person,
                  isFocus: node.person.id == focusId,
                  onTap: () => onTapPerson(node.person),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _nodeW = 108.0;
const _nodeH = 104.0;
const _hGap = 28.0;
const _vGap = 120.0;

class _Node {
  _Node(this.person, this.generation);
  final Person person;
  final int generation;
  Offset center = Offset.zero;
}

class _GraphLayout {
  _GraphLayout(this.nodes, this.canvasSize, this.edges);
  final Map<String, _Node> nodes;
  final Size canvasSize;
  final List<(String, String)> edges; // (parentId, childId)

  static _GraphLayout compute(FamilyGraph graph, String focusId) {
    final resolver = RelationshipResolver(graph);
    final gen = <String, int>{focusId: 0};
    final queue = <String>[focusId];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      final g = gen[id]!;
      for (final role in ParentRole.values) {
        final p = resolver.parentOf(id, role);
        if (p != null && !gen.containsKey(p.id)) {
          gen[p.id] = g - 1;
          queue.add(p.id);
        }
      }
      for (final c in resolver.childrenOf(id)) {
        if (!gen.containsKey(c.id)) {
          gen[c.id] = g + 1;
          queue.add(c.id);
        }
      }
      for (final s in resolver.currentSpouses(id)) {
        if (!gen.containsKey(s.id)) {
          gen[s.id] = g;
          queue.add(s.id);
        }
      }
    }

    final byGen = <int, List<String>>{};
    for (final e in gen.entries) {
      byGen.putIfAbsent(e.value, () => []).add(e.key);
    }
    final gens = byGen.keys.toList()..sort();
    final nodes = <String, _Node>{};
    var maxRowWidth = 0.0;
    for (var row = 0; row < gens.length; row++) {
      final ids = byGen[gens[row]]!;
      final rowWidth = ids.length * (_nodeW + _hGap);
      maxRowWidth = rowWidth > maxRowWidth ? rowWidth : maxRowWidth;
      for (var i = 0; i < ids.length; i++) {
        final node = _Node(graph.requirePerson(ids[i]), gens[row]);
        node.center = Offset(
          i * (_nodeW + _hGap) + _nodeW / 2 + 40,
          row * (_nodeH + _vGap) + _nodeH / 2 + 40,
        );
        nodes[ids[i]] = node;
      }
    }

    final edges = <(String, String)>[];
    for (final l in graph.parentLinks) {
      if (nodes.containsKey(l.parentId) && nodes.containsKey(l.childId)) {
        edges.add((l.parentId, l.childId));
      }
    }

    return _GraphLayout(
      nodes,
      Size(maxRowWidth + 80, gens.length * (_nodeH + _vGap) + 80),
      edges,
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.layout, required this.color});
  final _GraphLayout layout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final (parentId, childId) in layout.edges) {
      final p = layout.nodes[parentId]!.center;
      final c = layout.nodes[childId]!.center;
      final mid = (p.dy + c.dy) / 2;
      final path = Path()
        ..moveTo(p.dx, p.dy + _nodeH / 2)
        ..lineTo(p.dx, mid)
        ..lineTo(c.dx, mid)
        ..lineTo(c.dx, c.dy - _nodeH / 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.layout != layout;
}

class _PersonNode extends StatelessWidget {
  const _PersonNode({
    required this.person,
    required this.isFocus,
    required this.onTap,
  });
  final Person person;
  final bool isFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deceased = person.status == LifeStatus.deceased;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WarisRadius.chip),
        onTap: onTap,
        child: AnimatedContainer(
          duration: WarisMotion.fast,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(WarisRadius.chip),
            border: Border.all(
              color: isFocus ? scheme.primary : scheme.outlineVariant,
              width: isFocus ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: person.gender == Gender.male
                    ? WarisColors.secondary
                    : WarisColors.highlight,
                child: Text(
                  person.name.isEmpty ? '?' : person.name.characters.first,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                deceased ? 'Meninggal' : 'Hidup',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: deceased ? WarisColors.danger : WarisColors.success,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
