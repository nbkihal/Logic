import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/domain/engine/gate_logic.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/logic.dart';

const l = Logic.low;
const h = Logic.high;
const x = Logic.floating;

/// Expects [type] to map each `[inputs] -> output` pair in [cases].
void expectTable(GateType type, Map<List<Logic>, Logic> cases) {
  cases.forEach((inputs, expected) {
    expect(
      GateLogic.evaluate(type, inputs),
      expected,
      reason: '${type.name}(${inputs.map((i) => i.glyph).join(',')})',
    );
  });
}

void main() {
  group('two-valued behaviour', () {
    test('NOT', () {
      expectTable(GateType.not, {
        [l]: h,
        [h]: l,
      });
    });

    test('BUFFER passes through', () {
      expectTable(GateType.buffer, {
        [l]: l,
        [h]: h,
        [x]: x,
      });
    });

    test('AND', () {
      expectTable(GateType.and, {
        [l, l]: l,
        [l, h]: l,
        [h, l]: l,
        [h, h]: h,
      });
    });

    test('OR', () {
      expectTable(GateType.or, {
        [l, l]: l,
        [l, h]: h,
        [h, l]: h,
        [h, h]: h,
      });
    });

    test('NAND', () {
      expectTable(GateType.nand, {
        [l, l]: h,
        [l, h]: h,
        [h, l]: h,
        [h, h]: l,
      });
    });

    test('NOR', () {
      expectTable(GateType.nor, {
        [l, l]: h,
        [l, h]: l,
        [h, l]: l,
        [h, h]: l,
      });
    });

    test('XOR', () {
      expectTable(GateType.xor, {
        [l, l]: l,
        [l, h]: h,
        [h, l]: h,
        [h, h]: l,
      });
    });

    test('XNOR', () {
      expectTable(GateType.xnor, {
        [l, l]: h,
        [l, h]: l,
        [h, l]: l,
        [h, h]: h,
      });
    });
  });

  group('tri-state: a dominating value wins', () {
    test('NOT of floating stays floating', () {
      expect(GateLogic.not(x), x);
    });

    test('AND with a 0 is 0 even when the other input floats', () {
      expectTable(GateType.and, {
        [l, x]: l,
        [x, l]: l,
        [h, x]: x,
        [x, h]: x,
        [x, x]: x,
      });
    });

    test('OR with a 1 is 1 even when the other input floats', () {
      expectTable(GateType.or, {
        [h, x]: h,
        [x, h]: h,
        [l, x]: x,
        [x, l]: x,
        [x, x]: x,
      });
    });

    test('NAND and NOR invert the dominated result', () {
      expectTable(GateType.nand, {
        [l, x]: h,
        [h, x]: x,
      });
      expectTable(GateType.nor, {
        [h, x]: l,
        [l, x]: x,
      });
    });

    test('XOR has no dominating value, so any X floats the result', () {
      expectTable(GateType.xor, {
        [l, x]: x,
        [h, x]: x,
        [x, x]: x,
      });
      expectTable(GateType.xnor, {
        [l, x]: x,
        [h, x]: x,
      });
    });
  });

  group('degenerate inputs', () {
    test('no inputs float rather than throw', () {
      for (final type in GateType.values.where((t) => t.isGate)) {
        expect(
          GateLogic.evaluate(type, const []),
          x,
          reason: type.name,
        );
      }
    });

    test('sources are not evaluated here', () {
      expect(GateLogic.evaluate(GateType.input, const []), x);
      expect(GateLogic.evaluate(GateType.constant, const []), x);
    });
  });

  group('GateType metadata', () {
    test('port counts match the spec', () {
      expect(GateType.input.inputPortCount, 0);
      expect(GateType.constant.inputPortCount, 0);
      expect(GateType.output.inputPortCount, 1);
      expect(GateType.not.inputPortCount, 1);
      expect(GateType.buffer.inputPortCount, 1);
      for (final t in [
        GateType.and,
        GateType.or,
        GateType.nand,
        GateType.nor,
        GateType.xor,
        GateType.xnor,
      ]) {
        expect(t.inputPortCount, 2, reason: t.name);
      }
    });

    test('only the output lamp lacks an output port', () {
      for (final t in GateType.values) {
        expect(t.hasOutputPort, t != GateType.output, reason: t.name);
      }
    });

    test('pins, lamps and constants are free; operators count', () {
      expect(GateType.input.isGate, isFalse);
      expect(GateType.output.isGate, isFalse);
      expect(GateType.constant.isGate, isFalse);
      expect(GateType.and.isGate, isTrue);
      expect(GateType.buffer.isGate, isTrue);
    });
  });
}
