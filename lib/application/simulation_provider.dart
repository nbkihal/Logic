import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engine/simulator.dart';
import '../domain/models/logic.dart';
import 'circuit_controller.dart';

/// Live values for the board, derived from the circuit alone.
///
/// Input pins carry their own toggle state, so the circuit is the whole
/// input to evaluation — there is no second source of truth to keep in sync.
/// The truth-table tester (Phase 4) drives explicit assignments through
/// `Simulator.evaluate` directly instead of going through this provider.
final simulationProvider = Provider((ref) {
  return Simulator.evaluate(ref.watch(circuitControllerProvider));
});

/// Value at a single port. Watching this rather than the whole result keeps
/// a component widget from rebuilding when an unrelated port changes.
final portValueProvider = Provider.family<Logic, String>((ref, portId) {
  return ref.watch(simulationProvider).valueAt(portId);
});
