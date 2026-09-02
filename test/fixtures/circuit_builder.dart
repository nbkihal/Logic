import 'package:logic_circuit_builder/data/levels/level_repository.dart';
import 'package:logic_circuit_builder/domain/models/circuit.dart';
import 'package:logic_circuit_builder/domain/models/component.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/level.dart';
import 'package:logic_circuit_builder/domain/models/port.dart';
import 'package:logic_circuit_builder/domain/models/wire.dart';

/// A terse way to spell out a circuit in tests.
///
/// Starts from a level's fixtures (or bare pins/lamps), adds gates, and wires
/// them up:
///
/// ```dart
/// final b = CircuitBuilder.forLevel(level);
/// final g = b.gate(GateType.and);
/// b.wire(b.input(0), g.at(0));
/// b.wire(g.out, b.lamp(0));
/// ```
class CircuitBuilder {
  CircuitBuilder._(this._components);

  factory CircuitBuilder.forLevel(Level level) => CircuitBuilder._(
        Map<String, Component>.from(
          LevelFixtures.startingCircuit(level).components,
        ),
      );

  factory CircuitBuilder.pins({required int inputs, required int outputs}) {
    final components = <String, Component>{};
    for (var i = 0; i < inputs; i++) {
      final id = LevelFixtures.inputId(i);
      components[id] =
          Component(id: id, type: GateType.input, gridX: 0, gridY: i * 4);
    }
    for (var i = 0; i < outputs; i++) {
      final id = LevelFixtures.outputId(i);
      components[id] =
          Component(id: id, type: GateType.output, gridX: 18, gridY: i * 4);
    }
    return CircuitBuilder._(components);
  }

  final Map<String, Component> _components;
  final Map<String, Wire> _wires = {};
  int _nextGate = 0;
  int _nextWire = 0;

  /// Adds a gate and returns a handle to its ports.
  GateHandle gate(GateType type, {String? id}) {
    final gateId = id ?? 'g${_nextGate++}';
    _components[gateId] =
        Component(id: gateId, type: type, gridX: 6, gridY: _nextGate * 3);
    return GateHandle(gateId);
  }

  /// Adds a constant source pinned to [value].
  GateHandle constant({required bool value, String? id}) {
    final constId = id ?? 'k${_nextGate++}';
    _components[constId] = Component(
      id: constId,
      type: GateType.constant,
      gridX: 3,
      gridY: _nextGate * 3,
      constantValue: value,
    );
    return GateHandle(constId);
  }

  /// The output port of input pin [index].
  Port input(int index) => Port.output(LevelFixtures.inputId(index));

  /// The input port of output lamp [index].
  Port lamp(int index) => Port.input(LevelFixtures.outputId(index), 0);

  void wire(Port from, Port to, {String? id}) {
    final wireId = id ?? 'w${_nextWire++}';
    _wires[wireId] = Wire(id: wireId, from: from, to: to);
  }

  /// Sets an input pin's stored toggle state.
  void toggle(int index, {required bool value}) {
    final id = LevelFixtures.inputId(index);
    _components[id] = _components[id]!.copyWith(inputValue: value);
  }

  Circuit build() => Circuit(
        components: Map.unmodifiable(_components),
        wires: Map.unmodifiable(_wires),
      );
}

/// Port accessors for a placed gate.
class GateHandle {
  const GateHandle(this.id);

  final String id;

  /// Input port [index] of this gate.
  Port at(int index) => Port.input(id, index);

  Port get out => Port.output(id);
}
