import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/levels/demo_circuit.dart';
import '../domain/models/circuit.dart';

/// What a freshly opened board starts as.
///
/// Declaring the seed as its own provider keeps the screen out of the
/// business of pushing state in — nothing has to mutate a provider from a
/// widget lifecycle, which Riverpod rightly refuses. Phase 3 repoints this at
/// `LevelFixtures.startingCircuit` for the level being played.
final initialCircuitProvider = Provider<Circuit>((ref) => DemoCircuit.build());

/// The single source of truth for what is on the board.
///
/// Phase 2 only needs to *hold* a circuit so the canvas has something to
/// draw. Phase 3 adds the editing intents — place, move, wire, delete,
/// toggle, undo, redo, reset — and every mutation will go through here.
class CircuitController extends Notifier<Circuit> {
  @override
  Circuit build() => ref.watch(initialCircuitProvider);

  /// Replaces the board wholesale. Used to open a level and to reset one.
  void load(Circuit circuit) => state = circuit;
}

final circuitControllerProvider =
    NotifierProvider<CircuitController, Circuit>(CircuitController.new);
