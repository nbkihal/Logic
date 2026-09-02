import '../models/circuit.dart';

/// The circuit wires back into itself. The MVP is combinational only, so this
/// is an invalid state rather than a supported one (CLAUDE.md §6.4).
class CycleError {
  const CycleError({required this.componentIds, required this.wireIds});

  /// Components that sit on a loop. Downstream components that merely read a
  /// looping value are excluded, so highlighting points at the actual fault.
  final Set<String> componentIds;

  /// Wires to highlight while the loop is on screen.
  final Set<String> wireIds;

  static const message =
      'This wiring loops back on itself — remove a wire to continue.';

  @override
  String toString() => 'CycleError(${componentIds.length} components)';
}

/// Cycle detection over the component graph.
extension CircuitCycles on Circuit {
  /// True when the circuit contains a feedback loop.
  ///
  /// Runs in O(V + E) and never recurses, so a loop cannot hang the app.
  bool hasCycle() => findCycle() != null;

  /// The offending components and wires, or null when the circuit is acyclic.
  CycleError? findCycle() {
    final adj = adjacency;
    final indegree = <String, int>{for (final id in components.keys) id: 0};
    for (final targets in adj.values) {
      for (final t in targets) {
        indegree[t] = (indegree[t] ?? 0) + 1;
      }
    }

    final queue = <String>[
      for (final e in indegree.entries)
        if (e.value == 0) e.key,
    ];
    var settled = 0;
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      settled++;
      for (final next in adj[id] ?? const <String>{}) {
        final left = (indegree[next] ?? 0) - 1;
        indegree[next] = left;
        if (left == 0) queue.add(next);
      }
    }

    if (settled == components.length) return null;

    // Kahn's leaves behind the loops *and* everything downstream of them.
    // Peel off nodes with no incoming or no outgoing edge inside that
    // remainder until only genuine loop members are left, so the highlight
    // points at the fault rather than at its consequences.
    final onLoop = <String>{
      for (final e in indegree.entries)
        if (e.value > 0) e.key,
    };
    var peeled = true;
    while (peeled) {
      peeled = false;
      for (final id in onLoop.toList()) {
        final hasOutgoing = (adj[id] ?? const <String>{}).any(onLoop.contains);
        final hasIncoming = onLoop.any(
          (other) => (adj[other] ?? const <String>{}).contains(id),
        );
        if (!hasOutgoing || !hasIncoming) {
          onLoop.remove(id);
          peeled = true;
        }
      }
    }

    return CycleError(
      componentIds: onLoop,
      wireIds: {
        for (final w in wires.values)
          if (onLoop.contains(w.fromComponentId) &&
              onLoop.contains(w.toComponentId))
            w.id,
      },
    );
  }
}
