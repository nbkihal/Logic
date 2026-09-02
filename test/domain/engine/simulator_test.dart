import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/domain/engine/simulator.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/logic.dart';

import '../../fixtures/circuit_builder.dart';

void main() {
  group('single gate', () {
    test('reads the pin toggle stored on the component', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1)
        ..toggle(0, value: true);
      final not = b.gate(GateType.not, id: 'not');
      b
        ..wire(b.input(0), not.at(0))
        ..wire(not.out, b.lamp(0));

      final result = Simulator.evaluate(b.build());
      expect(result.outputs, [Logic.low]);
      expect(result.isComplete, isTrue);
      expect(result.hasCycle, isFalse);
    });

    test('an explicit assignment overrides the stored toggle', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1)
        ..toggle(0, value: true);
      final not = b.gate(GateType.not, id: 'not');
      b
        ..wire(b.input(0), not.at(0))
        ..wire(not.out, b.lamp(0));

      final result = Simulator.evaluate(
        b.build(),
        inputAssignment: const {'in_0': false},
      );
      expect(result.outputs, [Logic.high]);
    });

    test('a constant drives its pinned value', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 1);
      final k = b.constant(value: true, id: 'k');
      b.wire(k.out, b.lamp(0));

      expect(Simulator.evaluate(b.build()).outputs, [Logic.high]);
    });
  });

  group('multi-gate topological evaluation', () {
    // XOR built from AND/OR/NOT: (A OR B) AND NOT(A AND B).
    CircuitBuilder xorFromPrimitives() {
      final b = CircuitBuilder.pins(inputs: 2, outputs: 1);
      final or = b.gate(GateType.or, id: 'or');
      final and = b.gate(GateType.and, id: 'and');
      final not = b.gate(GateType.not, id: 'not');
      final out = b.gate(GateType.and, id: 'out_and');
      b
        ..wire(b.input(0), or.at(0))
        ..wire(b.input(1), or.at(1))
        ..wire(b.input(0), and.at(0))
        ..wire(b.input(1), and.at(1))
        ..wire(and.out, not.at(0))
        ..wire(or.out, out.at(0))
        ..wire(not.out, out.at(1))
        ..wire(out.out, b.lamp(0));
      return b;
    }

    test('computes XOR for every input combination', () {
      final circuit = xorFromPrimitives().build();
      const expected = [Logic.low, Logic.high, Logic.high, Logic.low];

      for (var i = 0; i < 4; i++) {
        final result = Simulator.evaluate(
          circuit,
          inputAssignment: Simulator.assignmentFor(circuit, i),
        );
        expect(result.outputs, [expected[i]], reason: 'combination $i');
      }
    });

    test('fan-out delivers one output to several consumers', () {
      final circuit = xorFromPrimitives().build();
      final result = Simulator.evaluate(
        circuit,
        inputAssignment: const {'in_0': true, 'in_1': false},
      );
      expect(result.valueAt('in_0:out'), Logic.high);
      expect(result.valueAt('or:in0'), Logic.high);
      expect(result.valueAt('and:in0'), Logic.high);
    });

    test('evaluation order puts every driver before its consumer', () {
      final circuit = xorFromPrimitives().build();
      final order = Simulator.evaluate(circuit).evaluationOrder;
      expect(order.indexOf('and'), lessThan(order.indexOf('not')));
      expect(order.indexOf('not'), lessThan(order.indexOf('out_and')));
      expect(order.indexOf('or'), lessThan(order.indexOf('out_and')));
    });

    test('half adder produces SUM and CARRY in column order', () {
      final b = CircuitBuilder.pins(inputs: 2, outputs: 2);
      final xor = b.gate(GateType.xor, id: 'xor');
      final and = b.gate(GateType.and, id: 'and');
      b
        ..wire(b.input(0), xor.at(0))
        ..wire(b.input(1), xor.at(1))
        ..wire(b.input(0), and.at(0))
        ..wire(b.input(1), and.at(1))
        ..wire(xor.out, b.lamp(0))
        ..wire(and.out, b.lamp(1));

      final circuit = b.build();
      const expected = [
        [Logic.low, Logic.low],
        [Logic.high, Logic.low],
        [Logic.high, Logic.low],
        [Logic.low, Logic.high],
      ];
      for (var i = 0; i < 4; i++) {
        final result = Simulator.evaluate(
          circuit,
          inputAssignment: Simulator.assignmentFor(circuit, i),
        );
        expect(result.outputs, expected[i], reason: 'combination $i');
      }
    });
  });

  group('incomplete circuits', () {
    test('an unwired lamp reads floating and the circuit is incomplete', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1);
      final result = Simulator.evaluate(b.build());

      expect(result.outputs, [Logic.floating]);
      expect(result.isComplete, isFalse);
      expect(result.hasCycle, isFalse);
    });

    test('a half-wired AND still resolves when 0 dominates', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1)
        ..toggle(0, value: false);
      final and = b.gate(GateType.and, id: 'and');
      b
        ..wire(b.input(0), and.at(0))
        ..wire(and.out, b.lamp(0));

      final result = Simulator.evaluate(b.build());
      expect(result.outputs, [Logic.low]);
      expect(result.isComplete, isFalse);
    });

    test('the same AND floats when the wired input is 1', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1)
        ..toggle(0, value: true);
      final and = b.gate(GateType.and, id: 'and');
      b
        ..wire(b.input(0), and.at(0))
        ..wire(and.out, b.lamp(0));

      expect(Simulator.evaluate(b.build()).outputs, [Logic.floating]);
    });
  });

  group('cycles', () {
    test('evaluation is refused, not attempted', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 1);
      final a = b.gate(GateType.buffer, id: 'a');
      final c = b.gate(GateType.not, id: 'c');
      b
        ..wire(a.out, c.at(0))
        ..wire(c.out, a.at(0))
        ..wire(c.out, b.lamp(0));

      final result = Simulator.evaluate(b.build());
      expect(result.hasCycle, isTrue);
      expect(result.isValid, isFalse);
      expect(result.outputs, isEmpty);
      expect(result.cycle!.componentIds, containsAll(['a', 'c']));
    });
  });

  group('assignmentFor', () {
    test('treats the first pin as the most-significant bit', () {
      final circuit = CircuitBuilder.pins(inputs: 3, outputs: 1).build();

      expect(
        Simulator.assignmentFor(circuit, 0),
        {'in_0': false, 'in_1': false, 'in_2': false},
      );
      expect(
        Simulator.assignmentFor(circuit, 1),
        {'in_0': false, 'in_1': false, 'in_2': true},
      );
      expect(
        Simulator.assignmentFor(circuit, 4),
        {'in_0': true, 'in_1': false, 'in_2': false},
      );
      expect(
        Simulator.assignmentFor(circuit, 7),
        {'in_0': true, 'in_1': true, 'in_2': true},
      );
    });
  });

  test('evaluate is pure — repeated calls agree', () {
    final b = CircuitBuilder.pins(inputs: 2, outputs: 1);
    final nand = b.gate(GateType.nand, id: 'nand');
    b
      ..wire(b.input(0), nand.at(0))
      ..wire(b.input(1), nand.at(1))
      ..wire(nand.out, b.lamp(0));

    final circuit = b.build();
    final first = Simulator.evaluate(circuit).portValues;
    final second = Simulator.evaluate(circuit).portValues;
    expect(first, second);
  });
}
