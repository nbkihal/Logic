import '../../core/result.dart';
import '../models/circuit.dart';
import 'cycle_detector.dart';

/// Dependency ordering for evaluation.
extension CircuitToposort on Circuit {
  /// Component ids in an order where every driver precedes its consumers.
  ///
  /// Sources (input pins and constants) come first. Ties break on id so the
  /// order is deterministic — the signal-flow animation replays the same way
  /// every time.
  Result<List<String>, CycleError> toposort() {
    final adj = adjacency;
    final indegree = <String, int>{for (final id in components.keys) id: 0};
    for (final targets in adj.values) {
      for (final t in targets) {
        indegree[t] = (indegree[t] ?? 0) + 1;
      }
    }

    final ready = <String>[
      for (final e in indegree.entries)
        if (e.value == 0) e.key,
    ]..sort();

    final order = <String>[];
    while (ready.isNotEmpty) {
      final id = ready.removeAt(0);
      order.add(id);
      final unlocked = <String>[];
      for (final next in adj[id] ?? const <String>{}) {
        final left = (indegree[next] ?? 0) - 1;
        indegree[next] = left;
        if (left == 0) unlocked.add(next);
      }
      if (unlocked.isNotEmpty) {
        unlocked.sort();
        ready
          ..addAll(unlocked)
          ..sort();
      }
    }

    if (order.length != components.length) {
      return Result.err(findCycle()!);
    }
    return Result.ok(order);
  }
}
