import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/data/levels/level_repository.dart';
import 'package:logic_circuit_builder/data/levels/levels_data.dart';
import 'package:logic_circuit_builder/data/levels/reference_functions.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';

void main() {
  group('content correctness (CLAUDE.md §15)', () {
    test('every level table matches its reference function', () {
      for (final level in kLevels) {
        final fn = ReferenceFunctions.byLevelId[level.id];
        expect(fn, isNotNull, reason: 'level ${level.id} has no reference fn');

        final recomputed =
            ReferenceFunctions.tabulate(level.inputCount, fn!);
        expect(
          level.target.rows,
          recomputed,
          reason: 'level ${level.id} (${level.name}) target table disagrees '
              'with its reference function',
        );
      }
    });

    test('every level is well formed', () {
      for (final level in kLevels) {
        expect(
          level.isWellFormed,
          isTrue,
          reason: 'level ${level.id} table shape does not match its counts',
        );
        expect(level.target.rowCount, 1 << level.inputCount);
        expect(level.target.inputNames, hasLength(level.inputCount));
        expect(level.target.outputNames, hasLength(level.outputCount));
      }
    });

    test('ids are unique, sequential, and in play order', () {
      expect(
        kLevels.map((l) => l.id).toList(),
        List<int>.generate(kLevels.length, (i) => i + 1),
      );
    });

    test('names and blurbs are present', () {
      for (final level in kLevels) {
        expect(level.name, isNotEmpty, reason: 'level ${level.id}');
        expect(level.blurb, isNotEmpty, reason: 'level ${level.id}');
      }
    });

    test('par is positive and palettes are non-empty', () {
      for (final level in kLevels) {
        expect(level.par, greaterThan(0), reason: 'level ${level.id}');
        expect(level.palette, isNotEmpty, reason: 'level ${level.id}');
      }
    });

    test('palettes contain only placeable gates, never pins or lamps', () {
      for (final level in kLevels) {
        for (final type in level.palette) {
          expect(
            type == GateType.input || type == GateType.output,
            isFalse,
            reason: 'level ${level.id} offers ${type.name} in its palette',
          );
        }
      }
    });
  });

  group('difficulty curve (CLAUDE.md §8)', () {
    // The capstone is the one deliberate exception: it stacks levers by
    // design and is gated behind finishing the teaching arc (CLAUDE.md §8).
    final taught = kLevels.sublist(0, kLevels.length - 1);

    test('input count never jumps by more than one', () {
      for (var i = 1; i < taught.length; i++) {
        final delta = taught[i].inputCount - taught[i - 1].inputCount;
        expect(
          delta,
          lessThanOrEqualTo(1),
          reason: 'level ${taught[i].id} adds $delta inputs at once',
        );
      }
    });

    test('output count never jumps by more than one', () {
      for (var i = 1; i < taught.length; i++) {
        final delta = taught[i].outputCount - taught[i - 1].outputCount;
        expect(
          delta,
          lessThanOrEqualTo(1),
          reason: 'level ${taught[i].id} adds $delta outputs at once',
        );
      }
    });

    test('exactly one level is a black box, and it is not the first', () {
      final hidden = kLevels.where((l) => !l.showTargetTable).toList();
      expect(hidden, hasLength(1));
      expect(hidden.single.id, greaterThan(1));
    });

    test('the NAND-only stages really are NAND-only', () {
      for (final id in [7, 8]) {
        final level = kLevels.firstWhere((l) => l.id == id);
        expect(level.palette, {GateType.nand}, reason: 'level $id');
      }
    });
  });

  group('truth table indexing', () {
    test('the first input is the most-significant bit', () {
      final table = kLevels.firstWhere((l) => l.id == 11).target;
      expect(table.inputsAt(0), [false, false, false]);
      expect(table.inputsAt(1), [false, false, true]);
      expect(table.inputsAt(4), [true, false, false]);
      expect(table.inputsAt(7), [true, true, true]);
    });

    test('tabulate agrees with inputsAt for the same combination', () {
      final rows = ReferenceFunctions.tabulate(3, ReferenceFunctions.majority);
      final table = kLevels.firstWhere((l) => l.id == 10).target;
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i], table.outputsAt(i), reason: 'row $i');
      }
    });
  });

  group('LevelRepository', () {
    const repo = LevelRepository();

    test('exposes every level by id', () {
      expect(repo.count, kLevels.length);
      for (final level in kLevels) {
        expect(repo.byId(level.id), same(level));
      }
      expect(repo.byId(999), isNull);
    });

    test('walks the arc in order and stops at the end', () {
      expect(repo.next(1)?.id, 2);
      expect(repo.next(kLevels.last.id), isNull);
      expect(repo.next(999), isNull);
    });
  });

  group('LevelFixtures', () {
    test('starts a level with only its pins and lamps', () {
      for (final level in kLevels) {
        final circuit = LevelFixtures.startingCircuit(level);

        expect(circuit.wires, isEmpty, reason: 'level ${level.id}');
        expect(circuit.gateCount, 0, reason: 'level ${level.id}');
        expect(circuit.inputPins, hasLength(level.inputCount));
        expect(circuit.outputLamps, hasLength(level.outputCount));
      }
    });

    test('orders pins and lamps to match truth-table column order', () {
      final level = kLevels.firstWhere((l) => l.id == 13);
      final circuit = LevelFixtures.startingCircuit(level);

      expect(
        circuit.inputPins.map((c) => c.id).toList(),
        ['in_0', 'in_1', 'in_2', 'in_3'],
      );
      expect(
        circuit.outputLamps.map((c) => c.id).toList(),
        ['out_0', 'out_1', 'out_2'],
      );
    });

    test('every fixture port starts floating', () {
      final level = kLevels.firstWhere((l) => l.id == 6);
      final circuit = LevelFixtures.startingCircuit(level);

      expect(circuit.isComplete, isFalse);
      expect(circuit.floatingPorts, hasLength(level.outputCount));
    });
  });
}
