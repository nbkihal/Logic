import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/levels/level_repository.dart';
import '../domain/engine/simulator.dart';
import '../domain/engine/win_checker.dart';
import '../domain/models/logic.dart';
import 'circuit_controller.dart';

/// Live values for the board, derived from the circuit alone.
///
/// Input pins carry their own toggle state, so the circuit is the whole input
/// to evaluation — there is no second source of truth to keep in sync.
final simulationProvider = Provider.family<SimulationResult, int>((
  ref,
  levelId,
) {
  return Simulator.evaluate(ref.watch(circuitControllerProvider(levelId)));
});

/// The verdict across *every* input combination: solved, or which rows fail.
///
/// This is what the tester panel renders and what fires the win state. It is
/// derived, so it recomputes on any edit and never goes stale.
final solveReportProvider = Provider.family<SolveReport, int>((ref, levelId) {
  final level = const LevelRepository().byId(levelId);
  final circuit = ref.watch(circuitControllerProvider(levelId));
  if (level == null) {
    return const SolveReport(status: SolveStatus.malformed, rows: []);
  }
  return WinChecker.check(circuit, level);
});

/// Gates placed, for the HUD's count against par.
final gateCountProvider = Provider.family<int, int>((ref, levelId) {
  return ref.watch(circuitControllerProvider(levelId)).gateCount;
});

/// Stars the current board would earn, or 0 while it is unsolved.
final earnedStarsProvider = Provider.family<int, int>((ref, levelId) {
  final level = const LevelRepository().byId(levelId);
  if (level == null) return 0;
  if (!ref.watch(solveReportProvider(levelId)).solved) return 0;
  return level.starsFor(ref.watch(gateCountProvider(levelId)));
});

/// Value at a single port, for a widget that only cares about one.
final portValueProvider = Provider.family<Logic, (int, String)>((ref, key) {
  return ref.watch(simulationProvider(key.$1)).valueAt(key.$2);
});

/// Whether the player has revealed a black-box level's target table.
class HintController extends FamilyNotifier<bool, int> {
  @override
  bool build(int levelId) => false;

  void reveal() => state = true;
}

final hintRevealedProvider =
    NotifierProvider.family<HintController, bool, int>(HintController.new);
