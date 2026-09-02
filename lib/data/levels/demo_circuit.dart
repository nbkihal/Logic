import '../../domain/models/circuit.dart';
import '../../domain/models/component.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/port.dart';
import '../../domain/models/wire.dart';

/// Phase 2 scaffolding: a hard-coded board so the renderer has something to
/// draw before any editing exists.
///
/// It is chosen to exercise every visual state at once — an energised wire, a
/// de-energised one, a floating one, fan-out from a single pin, a lit lamp
/// and a dark one. Phase 3 replaces this with the level's real starting
/// fixtures and deletes the file.
abstract final class DemoCircuit {
  static Circuit build() {
    Component at(String id, GateType type, int x, int y, {bool on = false}) =>
        Component(id: id, type: type, gridX: x, gridY: y, inputValue: on);

    final components = <Component>[
      // Half-adder fixtures: A is on, B is off.
      at('in_0', GateType.input, 0, -3, on: true),
      at('in_1', GateType.input, 0, 2),
      at('out_0', GateType.output, 18, -3),
      at('out_1', GateType.output, 18, 2),
      // SUM and CARRY.
      at('xor', GateType.xor, 8, -3),
      at('and', GateType.and, 8, 2),
      // A stranded pair, left unwired on purpose: its input floats, so the
      // wire it drives renders dashed.
      at('not', GateType.not, 6, 7),
      at('or', GateType.or, 12, 7),
    ];

    final wires = <Wire>[
      _wire('w0', 'in_0', 'xor', 0),
      _wire('w1', 'in_1', 'xor', 1),
      _wire('w2', 'in_0', 'and', 0),
      _wire('w3', 'in_1', 'and', 1),
      _wire('w4', 'xor', 'out_0', 0),
      _wire('w5', 'and', 'out_1', 0),
      _wire('w6', 'not', 'or', 0),
    ];

    return Circuit(
      components: {for (final c in components) c.id: c},
      wires: {for (final w in wires) w.id: w},
    );
  }

  static Wire _wire(String id, String from, String to, int inputIndex) => Wire(
        id: id,
        from: Port.output(from),
        to: Port.input(to, inputIndex),
      );
}
