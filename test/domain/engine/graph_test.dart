import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/domain/engine/cycle_detector.dart';
import 'package:logic_circuit_builder/domain/engine/toposort.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';

import '../../fixtures/circuit_builder.dart';

void main() {
  group('toposort', () {
    test('orders drivers before consumers', () {
      final b = CircuitBuilder.pins(inputs: 2, outputs: 1);
      final and = b.gate(GateType.and, id: 'and');
      final not = b.gate(GateType.not, id: 'not');
      b
        ..wire(b.input(0), and.at(0))
        ..wire(b.input(1), and.at(1))
        ..wire(and.out, not.at(0))
        ..wire(not.out, b.lamp(0));

      final order = b.build().toposort().valueOrNull!;

      expect(order.indexOf('in_0'), lessThan(order.indexOf('and')));
      expect(order.indexOf('in_1'), lessThan(order.indexOf('and')));
      expect(order.indexOf('and'), lessThan(order.indexOf('not')));
      expect(order.indexOf('not'), lessThan(order.indexOf('out_0')));
      expect(order, hasLength(5));
    });

    test('is deterministic across runs', () {
      CircuitBuilder freshBuilder() {
        final b = CircuitBuilder.pins(inputs: 2, outputs: 1);
        final or = b.gate(GateType.or, id: 'or');
        b
          ..wire(b.input(0), or.at(0))
          ..wire(b.input(1), or.at(1))
          ..wire(or.out, b.lamp(0));
        return b;
      }

      final first = freshBuilder().build().toposort().valueOrNull;
      final second = freshBuilder().build().toposort().valueOrNull;
      expect(first, second);
    });

    test('handles a disconnected component', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1)
        ..gate(GateType.not, id: 'orphan');
      final order = b.build().toposort().valueOrNull!;
      expect(order, contains('orphan'));
      expect(order, hasLength(3));
    });

    test('an empty circuit sorts to an empty order', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 0);
      expect(b.build().toposort().valueOrNull, isEmpty);
    });
  });

  group('cycle detection', () {
    test('an acyclic circuit reports no cycle', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1);
      final not = b.gate(GateType.not, id: 'not');
      b
        ..wire(b.input(0), not.at(0))
        ..wire(not.out, b.lamp(0));

      expect(b.build().hasCycle(), isFalse);
      expect(b.build().findCycle(), isNull);
    });

    test('a two-gate feedback loop is detected and does not hang', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 1);
      final a = b.gate(GateType.not, id: 'a');
      final c = b.gate(GateType.not, id: 'c');
      b
        ..wire(a.out, c.at(0), id: 'loop_a')
        ..wire(c.out, a.at(0), id: 'loop_b')
        ..wire(c.out, b.lamp(0), id: 'tap');

      final circuit = b.build();
      expect(circuit.hasCycle(), isTrue);

      final cycle = circuit.findCycle()!;
      expect(cycle.componentIds, containsAll(['a', 'c']));
      expect(cycle.wireIds, containsAll(['loop_a', 'loop_b']));
      // The tap out of the loop is not itself part of the loop.
      expect(cycle.wireIds, isNot(contains('tap')));
    });

    test('a gate wired to itself is a cycle', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 0);
      final g = b.gate(GateType.buffer, id: 'self');
      b.wire(g.out, g.at(0), id: 'selfloop');

      final cycle = b.build().findCycle()!;
      expect(cycle.componentIds, contains('self'));
      expect(cycle.wireIds, contains('selfloop'));
    });

    test('toposort surfaces the cycle instead of a partial order', () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 0);
      final a = b.gate(GateType.buffer, id: 'a');
      final c = b.gate(GateType.buffer, id: 'c');
      b
        ..wire(a.out, c.at(0))
        ..wire(c.out, a.at(0));

      final result = b.build().toposort();
      expect(result.isErr, isTrue);
      expect(result.errorOrNull!.componentIds, containsAll(['a', 'c']));
    });
  });
}
