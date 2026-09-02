import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engine/simulator.dart';
import '../domain/engine/win_checker.dart';
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

/// Whether the player has revealed a black-box level's target table.
class HintController extends Notifier<bool> {
  @override
  bool build() => false;

  void reveal() => state = true;
}

final hintRevealedProvider = NotifierProvider<HintController, bool>(
  HintController.new,
  dependencies: [levelIdProvider],
);
