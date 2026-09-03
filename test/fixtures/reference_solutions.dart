import 'package:logic_circuit_builder/data/levels/levels_data.dart';
import 'package:logic_circuit_builder/domain/models/circuit.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/level.dart';

import 'circuit_builder.dart';
import 'synthesis.dart';

/// A known-good solution for every level.
///
/// These back the §15 guardrails: each one must satisfy `isSolved`, use only
/// gates from its level's palette, and come in at or under par — which is how
/// a par that is quietly impossible gets caught before a player meets it.
///
/// Most stages are covered by [LogicSynthesizer], which is also what sets
/// their par, so the two can never drift apart. A level appears in [_builders]
/// only when a person can do better than the synthesizer and the par was
/// tightened to match.
abstract final class ReferenceSolutions {
  static Circuit forLevel(int id) {
    final built = _builders[id];
    if (built != null) return built();
    final level = kLevels.firstWhere((l) => l.id == id);
    return LogicSynthesizer.forLevel(level).circuitFor(level);
  }

  static const Map<int, Circuit Function()> _builders = {
    1: _invert,
    2: _conjunction,
    3: _disjunction,
    4: _notBoth,
    5: _xorFromPrimitives,
    6: _halfAdder,
    7: _andFromNand,
    8: _orFromNand,
    9: _implication,
    10: _majority,
    11: _fullAdder,
    12: _selector,
    13: _compare2Bit,
    18: _xorFromNand,
    52: _orFromRingSum,
  };

  static CircuitBuilder _builderFor(int levelId) =>
      CircuitBuilder.forLevel(_level(levelId));

  static Level _level(int id) => kLevels.firstWhere((l) => l.id == id);

  /// Level 1 — NOT A.
  static Circuit _invert() {
    final b = _builderFor(1);
    final not = b.gate(GateType.not);
    b
      ..wire(b.input(0), not.at(0))
      ..wire(not.out, b.lamp(0));
    return b.build();
  }

  /// Level 2 — A AND B.
  static Circuit _conjunction() {
    final b = _builderFor(2);
    final and = b.gate(GateType.and);
    b
      ..wire(b.input(0), and.at(0))
      ..wire(b.input(1), and.at(1))
      ..wire(and.out, b.lamp(0));
    return b.build();
  }

  /// Level 3 — A OR B.
  static Circuit _disjunction() {
    final b = _builderFor(3);
    final or = b.gate(GateType.or);
    b
      ..wire(b.input(0), or.at(0))
      ..wire(b.input(1), or.at(1))
      ..wire(or.out, b.lamp(0));
    return b.build();
  }

  /// Level 4 — NOT(A AND B), chained from the two allowed gates.
  static Circuit _notBoth() {
    final b = _builderFor(4);
    final and = b.gate(GateType.and);
    final not = b.gate(GateType.not);
    b
      ..wire(b.input(0), and.at(0))
      ..wire(b.input(1), and.at(1))
      ..wire(and.out, not.at(0))
      ..wire(not.out, b.lamp(0));
    return b.build();
  }

  /// Level 5 — XOR as (A OR B) AND NOT(A AND B). Four gates, par is five.
  static Circuit _xorFromPrimitives() {
    final b = _builderFor(5);
    final or = b.gate(GateType.or);
    final and = b.gate(GateType.and);
    final not = b.gate(GateType.not);
    final gate = b.gate(GateType.and);
    b
      ..wire(b.input(0), or.at(0))
      ..wire(b.input(1), or.at(1))
      ..wire(b.input(0), and.at(0))
      ..wire(b.input(1), and.at(1))
      ..wire(and.out, not.at(0))
      ..wire(or.out, gate.at(0))
      ..wire(not.out, gate.at(1))
      ..wire(gate.out, b.lamp(0));
    return b.build();
  }

  /// Level 6 — SUM = A XOR B, CARRY = A AND B.
  static Circuit _halfAdder() {
    final b = _builderFor(6);
    final xor = b.gate(GateType.xor);
    final and = b.gate(GateType.and);
    b
      ..wire(b.input(0), xor.at(0))
      ..wire(b.input(1), xor.at(1))
      ..wire(b.input(0), and.at(0))
      ..wire(b.input(1), and.at(1))
      ..wire(xor.out, b.lamp(0))
      ..wire(and.out, b.lamp(1));
    return b.build();
  }

  /// Level 7 — AND from NAND: invert the NAND by feeding it to itself.
  static Circuit _andFromNand() {
    final b = _builderFor(7);
    final nand = b.gate(GateType.nand);
    final invert = b.gate(GateType.nand);
    b
      ..wire(b.input(0), nand.at(0))
      ..wire(b.input(1), nand.at(1))
      ..wire(nand.out, invert.at(0))
      ..wire(nand.out, invert.at(1))
      ..wire(invert.out, b.lamp(0));
    return b.build();
  }

  /// Level 8 — OR from NAND: NAND the two inverted inputs (De Morgan).
  static Circuit _orFromNand() {
    final b = _builderFor(8);
    final notA = b.gate(GateType.nand);
    final notB = b.gate(GateType.nand);
    final join = b.gate(GateType.nand);
    b
      ..wire(b.input(0), notA.at(0))
      ..wire(b.input(0), notA.at(1))
      ..wire(b.input(1), notB.at(0))
      ..wire(b.input(1), notB.at(1))
      ..wire(notA.out, join.at(0))
      ..wire(notB.out, join.at(1))
      ..wire(join.out, b.lamp(0));
    return b.build();
  }

  /// Level 9 — the hidden function is implication: NOT A OR B.
  static Circuit _implication() {
    final b = _builderFor(9);
    final not = b.gate(GateType.not);
    final or = b.gate(GateType.or);
    b
      ..wire(b.input(0), not.at(0))
      ..wire(not.out, or.at(0))
      ..wire(b.input(1), or.at(1))
      ..wire(or.out, b.lamp(0));
    return b.build();
  }

  /// Level 10 — majority as (A AND B) OR (C AND (A OR B)). Four gates.
  static Circuit _majority() {
    final b = _builderFor(10);
    final ab = b.gate(GateType.and);
    final aOrB = b.gate(GateType.or);
    final cAny = b.gate(GateType.and);
    final result = b.gate(GateType.or);
    b
      ..wire(b.input(0), ab.at(0))
      ..wire(b.input(1), ab.at(1))
      ..wire(b.input(0), aOrB.at(0))
      ..wire(b.input(1), aOrB.at(1))
      ..wire(b.input(2), cAny.at(0))
      ..wire(aOrB.out, cAny.at(1))
      ..wire(ab.out, result.at(0))
      ..wire(cAny.out, result.at(1))
      ..wire(result.out, b.lamp(0));
    return b.build();
  }

  /// Level 11 — two half adders plus an OR on the carries.
  static Circuit _fullAdder() {
    final b = _builderFor(11);
    final halfSum = b.gate(GateType.xor);
    final sum = b.gate(GateType.xor);
    final carryAb = b.gate(GateType.and);
    final carryIn = b.gate(GateType.and);
    final carry = b.gate(GateType.or);
    b
      ..wire(b.input(0), halfSum.at(0))
      ..wire(b.input(1), halfSum.at(1))
      ..wire(halfSum.out, sum.at(0))
      ..wire(b.input(2), sum.at(1))
      ..wire(b.input(0), carryAb.at(0))
      ..wire(b.input(1), carryAb.at(1))
      ..wire(halfSum.out, carryIn.at(0))
      ..wire(b.input(2), carryIn.at(1))
      ..wire(carryAb.out, carry.at(0))
      ..wire(carryIn.out, carry.at(1))
      ..wire(sum.out, b.lamp(0))
      ..wire(carry.out, b.lamp(1));
    return b.build();
  }

  /// Level 12 — 2:1 MUX as (A AND NOT S) OR (B AND S).
  static Circuit _selector() {
    final b = _builderFor(12);
    final notS = b.gate(GateType.not);
    final passA = b.gate(GateType.and);
    final passB = b.gate(GateType.and);
    final join = b.gate(GateType.or);
    b
      ..wire(b.input(2), notS.at(0))
      ..wire(b.input(0), passA.at(0))
      ..wire(notS.out, passA.at(1))
      ..wire(b.input(1), passB.at(0))
      ..wire(b.input(2), passB.at(1))
      ..wire(passA.out, join.at(0))
      ..wire(passB.out, join.at(1))
      ..wire(join.out, b.lamp(0));
    return b.build();
  }

  /// Level 13 — 2-bit comparator, nine gates.
  ///
  /// The trick that keeps the count down: `A AND (A XOR B)` is `A AND NOT B`
  /// without a separate inverter, and both remaining outputs fall out of the
  /// XORs — `EQ = NOR(x1, x0)` and `LT = NOR(GT, EQ)`.
  static Circuit _compare2Bit() {
    final b = _builderFor(13);
    final x1 = b.gate(GateType.xor);
    final x0 = b.gate(GateType.xor);
    final gtHigh = b.gate(GateType.and);
    final gtLow = b.gate(GateType.and);
    final sameHigh = b.gate(GateType.not);
    final gtLowGated = b.gate(GateType.and);
    final gt = b.gate(GateType.or);
    final eq = b.gate(GateType.nor);
    final lt = b.gate(GateType.nor);
    b
      // x1 = A1 XOR B1, x0 = A0 XOR B0
      ..wire(b.input(0), x1.at(0))
      ..wire(b.input(2), x1.at(1))
      ..wire(b.input(1), x0.at(0))
      ..wire(b.input(3), x0.at(1))
      // A1 AND NOT B1, and the same for the low bit
      ..wire(b.input(0), gtHigh.at(0))
      ..wire(x1.out, gtHigh.at(1))
      ..wire(b.input(1), gtLow.at(0))
      ..wire(x0.out, gtLow.at(1))
      // The low bit only decides when the high bits agree.
      ..wire(x1.out, sameHigh.at(0))
      ..wire(sameHigh.out, gtLowGated.at(0))
      ..wire(gtLow.out, gtLowGated.at(1))
      ..wire(gtHigh.out, gt.at(0))
      ..wire(gtLowGated.out, gt.at(1))
      // Equal when neither bit differs; less when neither greater nor equal.
      ..wire(x1.out, eq.at(0))
      ..wire(x0.out, eq.at(1))
      ..wire(gt.out, lt.at(0))
      ..wire(eq.out, lt.at(1))
      ..wire(gt.out, b.lamp(0))
      ..wire(eq.out, b.lamp(1))
      ..wire(lt.out, b.lamp(2));
    return b.build();
  }
  /// Level 18 — XOR from four NANDs, one fewer than the NOR version.
  ///
  /// `t = NAND(A, B)` is reused by both middle gates, which is the whole
  /// trick: `Q = NAND(NAND(A, t), NAND(B, t))`.
  static Circuit _xorFromNand() {
    final b = _builderFor(18);
    final t = b.gate(GateType.nand);
    final left = b.gate(GateType.nand);
    final right = b.gate(GateType.nand);
    final join = b.gate(GateType.nand);
    b
      ..wire(b.input(0), t.at(0))
      ..wire(b.input(1), t.at(1))
      ..wire(b.input(0), left.at(0))
      ..wire(t.out, left.at(1))
      ..wire(b.input(1), right.at(0))
      ..wire(t.out, right.at(1))
      ..wire(left.out, join.at(0))
      ..wire(right.out, join.at(1))
      ..wire(join.out, b.lamp(0));
    return b.build();
  }

  /// Level 52 — OR out of the ring-sum basis: `A + B = A XOR B XOR AB`.
  static Circuit _orFromRingSum() {
    final b = _builderFor(52);
    final sum = b.gate(GateType.xor);
    final both = b.gate(GateType.and);
    final join = b.gate(GateType.xor);
    b
      ..wire(b.input(0), sum.at(0))
      ..wire(b.input(1), sum.at(1))
      ..wire(b.input(0), both.at(0))
      ..wire(b.input(1), both.at(1))
      ..wire(sum.out, join.at(0))
      ..wire(both.out, join.at(1))
      ..wire(join.out, b.lamp(0));
    return b.build();
  }
}
