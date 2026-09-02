import 'component.dart';
import 'gate_type.dart';
import 'port.dart';
import 'wire.dart';

/// The immutable graph of components and wires currently on the board.
///
/// Ordering convention: input pins and output lamps are ordered by component
/// id, lexicographically. Level fixtures are named `in_0..in_n` and
/// `out_0..out_n` so that order matches truth-table column order, with the
/// first input (`in_0`) as the **most-significant bit** (CLAUDE.md §5).
class Circuit {
  const Circuit({required this.components, required this.wires});

  const Circuit.empty()
      : components = const {},
        wires = const {};

  final Map<String, Component> components;
  final Map<String, Wire> wires;

  Circuit copyWith({
    Map<String, Component>? components,
    Map<String, Wire>? wires,
  }) =>
      Circuit(
        components: components ?? this.components,
        wires: wires ?? this.wires,
      );

  Iterable<Component> componentsOfType(GateType type) =>
      components.values.where((c) => c.type == type);

  /// Input pins in truth-table column order.
  List<Component> get inputPins => _sortedById(GateType.input);

  /// Output lamps in truth-table column order.
  List<Component> get outputLamps => _sortedById(GateType.output);

  List<Component> _sortedById(GateType type) {
    final list = componentsOfType(type).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// Number of components that count toward the gate budget.
  int get gateCount => components.values.where((c) => c.countsAsGate).length;

  /// The wire feeding [portId], or null when that input port is floating.
  Wire? wiresInto(String portId) {
    for (final w in wires.values) {
      if (w.to.id == portId) return w;
    }
    return null;
  }

  /// Every wire leaving [portId] — fan-out is unlimited.
  List<Wire> wiresFrom(String portId) =>
      wires.values.where((w) => w.from.id == portId).toList();

  bool isInputPortConnected(String portId) => wiresInto(portId) != null;

  /// Every input port that must be driven for the circuit to be complete:
  /// all gate inputs plus every output lamp's input.
  List<Port> get requiredInputPorts => [
        for (final c in components.values) ...c.inputPorts,
      ];

  /// Input ports with no wire — these evaluate to `Logic.floating`.
  List<Port> get floatingPorts =>
      requiredInputPorts.where((p) => !isInputPortConnected(p.id)).toList();

  /// A circuit is complete when no required input port is floating
  /// (CLAUDE.md §6.3). Incomplete is not the same as wrong.
  bool get isComplete => floatingPorts.isEmpty;

  /// Adjacency by component id, following wires from driver to consumer.
  Map<String, Set<String>> get adjacency {
    final adj = <String, Set<String>>{
      for (final id in components.keys) id: <String>{},
    };
    for (final w in wires.values) {
      final from = w.fromComponentId;
      final to = w.toComponentId;
      if (adj.containsKey(from) && components.containsKey(to)) {
        adj[from]!.add(to);
      }
    }
    return adj;
  }

  Component? componentOf(Port port) => components[port.componentId];

  @override
  String toString() =>
      'Circuit(${components.length} components, ${wires.length} wires)';
}
