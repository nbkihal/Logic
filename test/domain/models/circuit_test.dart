import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/domain/models/component.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/logic.dart';
import 'package:logic_circuit_builder/domain/models/port.dart';
import 'package:logic_circuit_builder/domain/models/truth_table.dart';
import 'package:logic_circuit_builder/domain/models/wire.dart';

import '../../fixtures/circuit_builder.dart';

void main() {
  group('Port ids', () {
    test('are stable and componentwise unique', () {
      expect(Port.input('g1', 0).id, 'g1:in0');
      expect(Port.input('g1', 1).id, 'g1:in1');
      expect(Port.output('g1').id, 'g1:out');
    });

    test('compare by id', () {
      expect(Port.input('g1', 0), Port.input('g1', 0));
      expect(Port.input('g1', 0), isNot(Port.input('g1', 1)));
      expect(Port.input('g1', 0), isNot(Port.output('g1')));
    });
  });

  group('Component', () {
    test('exposes ports matching its type', () {
      const and = Component(id: 'a', type: GateType.and, gridX: 0, gridY: 0);
      expect(and.inputPorts.map((p) => p.id), ['a:in0', 'a:in1']);
      expect(and.outputPort?.id, 'a:out');

      const lamp = Component(id: 'l', type: GateType.output, gridX: 0, gridY: 0);
      expect(lamp.inputPorts.map((p) => p.id), ['l:in0']);
      expect(lamp.outputPort, isNull);

      const pin = Component(id: 'p', type: GateType.input, gridX: 0, gridY: 0);
      expect(pin.inputPorts, isEmpty);
      expect(pin.outputPort?.id, 'p:out');
    });

    test('copyWith moves and toggles without changing identity', () {
      const pin = Component(id: 'p', type: GateType.input, gridX: 1, gridY: 2);
      final moved = pin.copyWith(gridX: 5, inputValue: true);

      expect(moved.id, 'p');
      expect(moved.type, GateType.input);
      expect(moved.gridX, 5);
      expect(moved.gridY, 2);
      expect(moved.inputValue, isTrue);
      expect(moved, isNot(pin));
    });
  });

  group('Wire', () {
    test('is well formed only output -> input', () {
      const good = Wire(id: 'w', from: Port(
        id: 'a:out',
        componentId: 'a',
        direction: PortDirection.output,
        index: 0,
      ), to: Port(
        id: 'b:in0',
        componentId: 'b',
        direction: PortDirection.input,
        index: 0,
      ));
      expect(good.isWellFormed, isTrue);

      final backwards = Wire(id: 'w', from: good.to, to: good.from);
      expect(backwards.isWellFormed, isFalse);
    });
  });

  group('Circuit queries', () {
    test('finds the single wire into an input port', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1);
      final not = b.gate(GateType.not, id: 'not');
      b
        ..wire(b.input(0), not.at(0), id: 'w0')
        ..wire(not.out, b.lamp(0), id: 'w1');

      final circuit = b.build();
      expect(circuit.wiresInto('not:in0')?.id, 'w0');
      expect(circuit.wiresInto('not:out'), isNull);
      expect(circuit.isInputPortConnected('not:in0'), isTrue);
      expect(circuit.isInputPortConnected('out_0:in0'), isTrue);
    });

    test('lists every wire leaving an output port (fan-out)', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 2);
      b
        ..wire(b.input(0), b.lamp(0), id: 'w0')
        ..wire(b.input(0), b.lamp(1), id: 'w1');

      expect(
        b.build().wiresFrom('in_0:out').map((w) => w.id).toSet(),
        {'w0', 'w1'},
      );
    });

    test('reports floating ports and completeness', () {
      final b = CircuitBuilder.pins(inputs: 1, outputs: 1);
      final and = b.gate(GateType.and, id: 'and');
      b.wire(b.input(0), and.at(0));

      final circuit = b.build();
      expect(circuit.isComplete, isFalse);
      expect(
        circuit.floatingPorts.map((p) => p.id).toSet(),
        {'and:in1', 'out_0:in0'},
      );

      b.wire(and.out, b.lamp(0));
      b.wire(b.input(0), and.at(1));
      expect(b.build().isComplete, isTrue);
    });

    test('orders pins and lamps by id', () {
      final circuit = CircuitBuilder.pins(inputs: 3, outputs: 2).build();
      expect(circuit.inputPins.map((c) => c.id), ['in_0', 'in_1', 'in_2']);
      expect(circuit.outputLamps.map((c) => c.id), ['out_0', 'out_1']);
    });

    test('copyWith swaps one map and keeps the other', () {
      final circuit = CircuitBuilder.pins(inputs: 1, outputs: 1).build();
      final cleared = circuit.copyWith(wires: const {});
      expect(cleared.components, same(circuit.components));
      expect(cleared.wires, isEmpty);
    });
  });

  group('TruthTable', () {
    const table = TruthTable(
      inputNames: ['A', 'B'],
      outputNames: ['Q'],
      rows: [
        [false],
        [true],
        [true],
        [false],
      ],
    );

    test('decodes combinations with the first input as MSB', () {
      expect(table.inputsAt(0), [false, false]);
      expect(table.inputsAt(1), [false, true]);
      expect(table.inputsAt(2), [true, false]);
      expect(table.inputsAt(3), [true, true]);
    });

    test('knows its own shape', () {
      expect(table.rowCount, 4);
      expect(table.isWellFormed, isTrue);

      const wrongShape = TruthTable(
        inputNames: ['A', 'B'],
        outputNames: ['Q'],
        rows: [
          [false],
        ],
      );
      expect(wrongShape.isWellFormed, isFalse);
    });

    test('compares by value, not identity', () {
      const same = TruthTable(
        inputNames: ['A', 'B'],
        outputNames: ['Q'],
        rows: [
          [false],
          [true],
          [true],
          [false],
        ],
      );
      const different = TruthTable(
        inputNames: ['A', 'B'],
        outputNames: ['Q'],
        rows: [
          [true],
          [true],
          [true],
          [false],
        ],
      );

      expect(table, same);
      expect(table.hashCode, same.hashCode);
      expect(table, isNot(different));
    });
  });

  group('Logic', () {
    test('carries a glyph so value never depends on color alone', () {
      expect(Logic.low.glyph, '0');
      expect(Logic.high.glyph, '1');
      expect(Logic.floating.glyph, 'X');
    });

    test('converts from bool', () {
      expect(Logic.fromBool(true), Logic.high);
      expect(Logic.fromBool(false), Logic.low);
    });
  });
}
