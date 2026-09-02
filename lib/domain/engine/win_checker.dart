import '../models/circuit.dart';
import '../models/level.dart';
import '../models/logic.dart';
import 'cycle_detector.dart';
import 'simulator.dart';

/// How one input combination fared against the target.
class RowDiff {
  const RowDiff({
    required this.combination,
    required this.expected,
    required this.actual,
    required this.mismatchedOutputs,
  });

  /// Index into the truth table, `0 .. 2^n - 1`.
  final int combination;
  final List<bool> expected;
  final List<Logic> actual;

  /// Indices of the output lamps that disagree with the target.
  final Set<int> mismatchedOutputs;

  bool get matches => mismatchedOutputs.isEmpty;

  @override
  String toString() =>
      'RowDiff($combination, ${matches ? 'ok' : 'mismatch $mismatchedOutputs'})';
}

/// Why a circuit is not yet a solution.
enum SolveStatus {
  /// A required input port has no wire — not wrong, just unfinished.
  incomplete,

  /// A feedback loop; evaluation is blocked.
  cyclic,

  /// The shape does not match the level (wrong pin or lamp count).
  malformed,

  /// Complete and evaluable, but at least one row disagrees.
  mismatched,

  /// Every row matches.
  solved,
}

/// The full verdict for a circuit against a level. Drives the tester panel.
class SolveReport {
  const SolveReport({
    required this.status,
    required this.rows,
    this.cycle,
  });

  final SolveStatus status;

  /// One entry per input combination, in table order. Empty when the circuit
  /// could not be evaluated at all.
  final List<RowDiff> rows;

  final CycleError? cycle;

  bool get solved => status == SolveStatus.solved;

  /// Combination indices the player still needs to fix.
  List<int> get failingRows => [
        for (final r in rows)
          if (!r.matches) r.combination,
      ];
}

/// Win detection (CLAUDE.md §6.5).
abstract final class WinChecker {
  /// Evaluates [circuit] across *every* input combination of [level].
  static SolveReport check(Circuit circuit, Level level) {
    final pins = circuit.inputPins;
    final lamps = circuit.outputLamps;
    if (pins.length != level.inputCount ||
        lamps.length != level.outputCount ||
        !level.isWellFormed) {
      return const SolveReport(status: SolveStatus.malformed, rows: []);
    }

    final cycle = circuit.findCycle();
    if (cycle != null) {
      return SolveReport(
        status: SolveStatus.cyclic,
        rows: const [],
        cycle: cycle,
      );
    }

    final rows = <RowDiff>[];
    for (var i = 0; i < level.target.rowCount; i++) {
      final result = Simulator.evaluate(
        circuit,
        inputAssignment: Simulator.assignmentFor(circuit, i),
      );
      final expected = level.target.outputsAt(i);
      final actual = result.outputs;
      rows.add(
        RowDiff(
          combination: i,
          expected: expected,
          actual: actual,
          mismatchedOutputs: {
            for (var j = 0; j < expected.length; j++)
              if (j >= actual.length ||
                  actual[j] != Logic.fromBool(expected[j]))
                j,
          },
        ),
      );
    }

    // Incompleteness outranks mismatch: a half-built circuit is unfinished,
    // not wrong, and the tester says so (CLAUDE.md §6.3).
    if (!circuit.isComplete) {
      return SolveReport(status: SolveStatus.incomplete, rows: rows);
    }
    final allMatch = rows.every((r) => r.matches);
    return SolveReport(
      status: allMatch ? SolveStatus.solved : SolveStatus.mismatched,
      rows: rows,
    );
  }

  /// Convenience predicate for the win state.
  static bool isSolved(Circuit circuit, Level level) =>
      check(circuit, level).solved;
}
