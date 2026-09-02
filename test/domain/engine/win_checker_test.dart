import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/data/levels/levels_data.dart';
import 'package:logic_circuit_builder/domain/engine/win_checker.dart';
import 'package:logic_circuit_builder/domain/models/circuit.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/level.dart';
import 'package:logic_circuit_builder/domain/models/wire.dart';

import '../../fixtures/circuit_builder.dart';
import '../../fixtures/reference_solutions.dart';

Level levelById(int id) => kLevels.firstWhere((l) => l.id == id);

void main() {
  final xorLevel = levelById(5);

  group('a known-good XOR from primitives', () {
    test('is solved', () {
      final circuit = ReferenceSolutions.forLevel(5);
      final report = WinChecker.check(circuit, xorLevel);

      expect(report.status, SolveStatus.solved);
      expect(report.solved, isTrue);
      expect(report.rows, hasLength(4));
      expect(report.failingRows, isEmpty);
    });

    test('is incomplete, not wrong, when a wire is removed', () {
      final solved = ReferenceSolutions.forLevel(5);
      final firstWire = solved.wires.keys.first;
      final broken = solved.copyWith(
        wires: Map<String, Wire>.from(solved.wires)..remove(firstWire),
      );

      final report = WinChecker.check(broken, xorLevel);
      expect(report.status, SolveStatus.incomplete);
      expect(report.solved, isFalse);
      // Rows are still reported so the tester can show what it can.
      expect(report.rows, hasLength(4));
    });

    test('is mismatched when a gate is swapped', () {
      // OR in place of the final AND: the two branches stop gating each
      // other, so both A=B rows light up when they should not.
      final b = CircuitBuilder.forLevel(xorLevel);
      final or = b.gate(GateType.or, id: 'or');
      final and = b.gate(GateType.and, id: 'and');
      final not = b.gate(GateType.not, id: 'not');
      final wrong = b.gate(GateType.or, id: 'wrong');
      b
        ..wire(b.input(0), or.at(0))
        ..wire(b.input(1), or.at(1))
        ..wire(b.input(0), and.at(0))
        ..wire(b.input(1), and.at(1))
        ..wire(and.out, not.at(0))
        ..wire(or.out, wrong.at(0))
        ..wire(not.out, wrong.at(1))
        ..wire(wrong.out, b.lamp(0));

      final report = WinChecker.check(b.build(), xorLevel);
      expect(report.status, SolveStatus.mismatched);
      expect(report.failingRows, [0, 3]);
      expect(report.rows[0].mismatchedOutputs, {0});
      expect(report.rows[1].matches, isTrue);
    });
  });

  group('degenerate states', () {
    test('a cycle is reported as cyclic, not as a mismatch', () {
      final b = CircuitBuilder.forLevel(xorLevel);
      final a = b.gate(GateType.buffer, id: 'a');
      final c = b.gate(GateType.buffer, id: 'c');
      b
        ..wire(a.out, c.at(0))
        ..wire(c.out, a.at(0))
        ..wire(c.out, b.lamp(0));

      final report = WinChecker.check(b.build(), xorLevel);
      expect(report.status, SolveStatus.cyclic);
      expect(report.cycle, isNotNull);
      expect(report.rows, isEmpty);
    });

    test('a board with the wrong pin count is malformed', () {
      final circuit = CircuitBuilder.pins(inputs: 3, outputs: 1).build();
      final report = WinChecker.check(circuit, xorLevel);
      expect(report.status, SolveStatus.malformed);
    });

    test('an empty board is incomplete', () {
      final report = WinChecker.check(
        CircuitBuilder.forLevel(xorLevel).build(),
        xorLevel,
      );
      expect(report.status, SolveStatus.incomplete);
    });
  });

  group('every level has a working reference solution', () {
    for (final level in kLevels) {
      test('level ${level.id} — ${level.name}', () {
        final circuit = ReferenceSolutions.forLevel(level.id);

        expect(
          WinChecker.isSolved(circuit, level),
          isTrue,
          reason: 'reference solution for level ${level.id} does not solve it',
        );
      });
    }
  });

  group('reference solutions respect their level', () {
    for (final level in kLevels) {
      test('level ${level.id} — ${level.name}', () {
        final Circuit circuit = ReferenceSolutions.forLevel(level.id);

        // Par is never impossible: the reference fits inside it (CLAUDE.md §15).
        expect(
          circuit.gateCount,
          lessThanOrEqualTo(level.par),
          reason: 'level ${level.id} par ${level.par} is below its reference '
              'solution of ${circuit.gateCount} gates',
        );

        // And it only uses gates the level actually offers.
        final used = circuit.components.values
            .where((c) => c.countsAsGate)
            .map((c) => c.type)
            .toSet();
        expect(
          used.difference(level.palette),
          isEmpty,
          reason: 'level ${level.id} reference uses gates outside its palette',
        );

        // A gate limit, where set, must also admit the reference.
        final limit = level.gateLimit;
        if (limit != null) {
          expect(circuit.gateCount, lessThanOrEqualTo(limit));
        }
      });
    }
  });

  group('star bands', () {
    test('three stars at or under par, two within the band, one beyond', () {
      final level = levelById(5); // par 5 -> two-star band is <= 8
      expect(level.starsFor(4), 3);
      expect(level.starsFor(5), 3);
      expect(level.starsFor(6), 2);
      expect(level.starsFor(8), 2);
      expect(level.starsFor(9), 1);
    });

    test('a par of one still leaves room for a two-star band', () {
      final level = levelById(1); // par 1 -> two stars at <= 2
      expect(level.starsFor(1), 3);
      expect(level.starsFor(2), 2);
      expect(level.starsFor(3), 1);
    });
  });

  test('gate count ignores pins, lamps and constants', () {
    final b = CircuitBuilder.pins(inputs: 2, outputs: 1)
      ..constant(value: true)
      ..gate(GateType.and)
      ..gate(GateType.not);

    expect(b.build().components, hasLength(6));
    expect(b.build().gateCount, 2);
  });
}
