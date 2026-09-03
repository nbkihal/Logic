import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engine/simulator.dart';
import '../domain/engine/win_checker.dart';
import '../domain/models/gate_type.dart';
import 'circuit_controller.dart';
import 'level_scope.dart';

/// Live values for the board, derived from the circuit alone.
///
/// Input pins carry their own toggle state, so the circuit is the whole input
/// to evaluation — there is no second source of truth to keep in sync.
final simulationProvider = Provider<SimulationResult>(
  (ref) => Simulator.evaluate(ref.watch(circuitControllerProvider)),
  dependencies: [circuitControllerProvider],
);

/// The verdict across *every* input combination: solved, or which rows fail.
///
/// This is what the tester panel renders and what fires the win state. It is
/// derived, so it recomputes on any edit and never goes stale.
final solveReportProvider = Provider<SolveReport>(
  (ref) {
    final level = ref.watch(levelProvider);
    final circuit = ref.watch(circuitControllerProvider);
    if (level == null) {
      return const SolveReport(status: SolveStatus.malformed, rows: []);
    }
    return WinChecker.check(circuit, level);
  },
  dependencies: [levelProvider, circuitControllerProvider],
);

/// Gates placed, for the HUD's count against par.
final gateCountProvider = Provider<int>(
  (ref) => ref.watch(circuitControllerProvider).gateCount,
  dependencies: [circuitControllerProvider],
);

/// Stars the current board would earn, or 0 while it is unsolved.
final earnedStarsProvider = Provider<int>(
  (ref) {
    final level = ref.watch(levelProvider);
    if (level == null) return 0;
    if (!ref.watch(solveReportProvider).solved) return 0;
    return level.starsFor(ref.watch(gateCountProvider));
  },
  dependencies: [levelProvider, solveReportProvider, gateCountProvider],
);

/// How much help the player has asked for on this level.
///
/// Hints are a ladder, not a switch: each rung gives away a little more, and
/// the player decides how far down it to go. Nothing here costs stars — the
/// game stays forgiving (CLAUDE.md §7) — but nothing is offered unasked
/// either.
enum HintLevel {
  /// Nothing given away.
  none,

  /// A black box's target table is revealed. On a level whose table is
  /// already visible this rung is skipped.
  table,

  /// Palette entries no known solution needs are crossed off.
  narrowed,

  /// One gate is named as the place to start.
  keystone;

  bool operator >=(HintLevel other) => index >= other.index;
}

/// The hint ladder for the level currently open. Resets with the level,
/// because it is scoped to [levelIdProvider].
class HintController extends Notifier<HintLevel> {
  @override
  HintLevel build() => HintLevel.none;

  /// Steps one rung down, skipping the reveal on a level with a visible
  /// table. Returns false when there is nothing left to give.
  bool next({required bool tableAlreadyVisible}) {
    final from = state;
    var target = HintLevel.values[from.index + 1 > HintLevel.keystone.index
        ? HintLevel.keystone.index
        : from.index + 1];
    if (target == HintLevel.table && tableAlreadyVisible) {
      target = HintLevel.narrowed;
    }
    state = target;
    return target != from;
  }

  /// Straight to the revealed table, for the tester panel's own button.
  void reveal() {
    if (state.index < HintLevel.table.index) state = HintLevel.table;
  }
}

final hintProvider = NotifierProvider<HintController, HintLevel>(
  HintController.new,
  dependencies: [levelIdProvider],
);

/// Whether a black-box level's table is on show.
final hintRevealedProvider = Provider<bool>(
  (ref) => ref.watch(hintProvider) >= HintLevel.table,
  dependencies: [hintProvider],
);

/// Palette entries the hints have crossed off, or empty until asked.
final ruledOutGatesProvider = Provider<Set<GateType>>(
  (ref) {
    final level = ref.watch(levelProvider);
    if (level == null) return const {};
    if (!(ref.watch(hintProvider) >= HintLevel.narrowed)) return const {};
    return level.unusedGates;
  },
  dependencies: [levelProvider, hintProvider],
);

/// The one gate the hints suggest starting from, once asked.
final suggestedGateProvider = Provider<GateType?>(
  (ref) {
    final level = ref.watch(levelProvider);
    if (level == null) return null;
    if (!(ref.watch(hintProvider) >= HintLevel.keystone)) return null;
    return level.keystoneGate;
  },
  dependencies: [levelProvider, hintProvider],
);
