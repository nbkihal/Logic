import '../models/circuit.dart';
import '../models/component.dart';
import '../models/gate_type.dart';
import '../models/logic.dart';
import '../models/port.dart';
import 'cycle_detector.dart';
import 'gate_logic.dart';
import 'toposort.dart';

/// The result of evaluating a circuit for one input assignment.
class SimulationResult {
  const SimulationResult({
    required this.portValues,
    required this.outputs,
    required this.isComplete,
    required this.cycle,
    required this.evaluationOrder,
  });

  /// Value at every port, keyed by port id. Feeds both the tester and the
  /// wire/lamp rendering.
  final Map<String, Logic> portValues;

  /// Values at the output lamps, in truth-table column order.
  final List<Logic> outputs;

  /// False when any required input port is floating.
  final bool isComplete;

  /// Non-null when the circuit loops back on itself; evaluation is skipped.
  final CycleError? cycle;

  /// Component ids in the order they were evaluated. The signal-flow
  /// animation replays this so the player watches computation propagate.
  final List<String> evaluationOrder;

  bool get hasCycle => cycle != null;

  /// True when the circuit could be evaluated at all.
  bool get isValid => cycle == null;

  Logic valueAt(String portId) => portValues[portId] ?? Logic.floating;

  static SimulationResult invalid(CycleError cycle) => SimulationResult(
        portValues: const {},
        outputs: const [],
        isComplete: false,
        cycle: cycle,
        evaluationOrder: const [],
      );
}

/// Pure combinational evaluation (CLAUDE.md §6.2).
abstract final class Simulator {
  /// Evaluates [circuit] under [inputAssignment].
  ///
  /// [inputAssignment] is keyed by input-pin component id; a pin missing from
  /// the map falls back to its own [Component.inputValue]. Same inputs, same
  /// outputs, no side effects — the animation layer replays this freely.
  static SimulationResult evaluate(
    Circuit circuit, {
    Map<String, bool> inputAssignment = const {},
  }) {
    final sorted = circuit.toposort();
    final cycle = sorted.errorOrNull;
    if (cycle != null) return SimulationResult.invalid(cycle);

    final order = sorted.valueOrNull!;
    final values = <String, Logic>{};

    for (final id in order) {
      final component = circuit.components[id]!;

      // Pull each input port's value across its wire, or float it.
      final inputs = <Logic>[];
      for (final port in component.inputPorts) {
        final wire = circuit.wiresInto(port.id);
        final value = wire == null
            ? Logic.floating
            : values[wire.from.id] ?? Logic.floating;
        values[port.id] = value;
        inputs.add(value);
      }

      if (!component.hasOutputPort) continue;

      final out = switch (component.type) {
        GateType.input =>
          Logic.fromBool(inputAssignment[id] ?? component.inputValue),
        GateType.constant => Logic.fromBool(component.constantValue),
        _ => GateLogic.evaluate(component.type, inputs),
      };
      values[Port.outputId(id)] = out;
    }

    return SimulationResult(
      portValues: values,
      outputs: [
        for (final lamp in circuit.outputLamps)
          values[Port.inputId(lamp.id, 0)] ?? Logic.floating,
      ],
      isComplete: circuit.isComplete,
      cycle: null,
      evaluationOrder: order,
    );
  }

  /// Assignment for combination [index], with the first input pin as the
  /// most-significant bit (CLAUDE.md §5).
  static Map<String, bool> assignmentFor(Circuit circuit, int index) {
    final pins = circuit.inputPins;
    return {
      for (var bit = 0; bit < pins.length; bit++)
        pins[bit].id: (index >> (pins.length - 1 - bit)) & 1 == 1,
    };
  }
}
