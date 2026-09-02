import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/canvas_constants.dart';
import '../data/levels/level_repository.dart';
import '../domain/models/circuit.dart';
import '../domain/models/component.dart';
import '../domain/models/gate_type.dart';
import '../domain/models/level.dart';
import '../domain/models/port.dart';
import '../domain/models/wire.dart';
import 'level_scope.dart';

/// Why a wiring attempt did not take.
enum WireOutcome {
  connected,

  /// That input port already holds a wire. Fan-in stays explicit: one wire in,
  /// many out (CLAUDE.md §20.3 — reject rather than replace).
  inputOccupied,

  /// Ports face the wrong way, or one of them no longer exists.
  invalid,
}

/// Why a placement did not take.
enum PlaceOutcome { placed, gateLimitReached, occupied }

/// The board for one level, and the only thing that may change it.
///
/// Every edit goes through an intent method here, and every intent pushes the
/// previous board onto the undo stack first. Because `Circuit` is immutable,
/// a snapshot is a cheap map copy rather than a deep clone.
class CircuitController extends Notifier<Circuit> {
  final _undo = <Circuit>[];
  final _redo = <Circuit>[];
  var _nextId = 0;

  Level? get _level => ref.read(levelProvider);

  @override
  Circuit build() {
    final level = ref.watch(levelProvider);
    return level == null
        ? const Circuit.empty()
        : LevelFixtures.startingCircuit(level);
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Snapshots the current board before a change, capping history so a long
  /// session cannot grow without bound.
  void _checkpoint() {
    _undo.add(state);
    if (_undo.length > CanvasConstants.undoStackLimit) _undo.removeAt(0);
    _redo.clear();
  }

  String _freshId(GateType type) {
    while (true) {
      final id = '${type.name}_${_nextId++}';
      if (!state.components.containsKey(id)) return id;
    }
  }

  /// Places a new component at a grid cell.
  PlaceOutcome placeComponent(
    GateType type, {
    required int gridX,
    required int gridY,
    bool constantValue = false,
  }) {
    final limit = _level?.gateLimit;
    if (type.isGate && limit != null && state.gateCount >= limit) {
      return PlaceOutcome.gateLimitReached;
    }
    if (_isCellTaken(gridX, gridY, ignoring: null)) {
      return PlaceOutcome.occupied;
    }

    _checkpoint();
    final id = _freshId(type);
    state = state.copyWith(
      components: {
        ...state.components,
        id: Component(
          id: id,
          type: type,
          gridX: gridX,
          gridY: gridY,
          constantValue: constantValue,
        ),
      },
    );
    return PlaceOutcome.placed;
  }

  /// Moves a component. Wires follow automatically — they are stored by port,
  /// not by coordinate.
  void moveComponent(String id, {required int gridX, required int gridY}) {
    final component = state.components[id];
    if (component == null) return;
    if (component.gridX == gridX && component.gridY == gridY) return;
    if (_isCellTaken(gridX, gridY, ignoring: id)) return;

    _checkpoint();
    state = state.copyWith(
      components: {
        ...state.components,
        id: component.copyWith(gridX: gridX, gridY: gridY),
      },
    );
  }

  /// Connects an output port to an input port.
  WireOutcome addWire(Port from, Port to) {
    if (!from.isOutput || !to.isInput) return WireOutcome.invalid;
    if (!state.components.containsKey(from.componentId) ||
        !state.components.containsKey(to.componentId)) {
      return WireOutcome.invalid;
    }
    final target = state.components[to.componentId]!;
    if (to.index >= target.inputPortCount) return WireOutcome.invalid;
    if (state.isInputPortConnected(to.id)) return WireOutcome.inputOccupied;

    _checkpoint();
    final id = 'w_${_nextId++}';
    state = state.copyWith(
      wires: {...state.wires, id: Wire(id: id, from: from, to: to)},
    );
    return WireOutcome.connected;
  }

  void removeWire(String wireId) {
    if (!state.wires.containsKey(wireId)) return;
    _checkpoint();
    state = state.copyWith(
      wires: {...state.wires}..remove(wireId),
    );
  }

  /// Removes a component and every wire touching it.
  ///
  /// A level's own pins and lamps are fixtures and cannot be deleted — the
  /// target table is defined in terms of them.
  bool removeComponent(String id) {
    final component = state.components[id];
    if (component == null || !component.countsAsGate) return false;

    _checkpoint();
    state = Circuit(
      components: {...state.components}..remove(id),
      wires: {
        for (final entry in state.wires.entries)
          if (entry.value.fromComponentId != id &&
              entry.value.toComponentId != id)
            entry.key: entry.value,
      },
    );
    return true;
  }

  /// Flips an input pin. Toggling is an edit like any other, so it undoes.
  void toggleInput(String id) {
    final component = state.components[id];
    if (component == null || component.type != GateType.input) return;

    _checkpoint();
    state = state.copyWith(
      components: {
        ...state.components,
        id: component.copyWith(inputValue: !component.inputValue),
      },
    );
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(state);
    state = _undo.removeLast();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(state);
    state = _redo.removeLast();
  }

  /// Back to the level's starting fixtures, with history cleared.
  void reset() {
    final level = _level;
    if (level == null) return;
    _undo.clear();
    _redo.clear();
    state = LevelFixtures.startingCircuit(level);
  }

  /// Replaces the board wholesale, e.g. to load a saved layout.
  void load(Circuit circuit) {
    _checkpoint();
    state = circuit;
  }

  /// True when another component already sits on that cell.
  bool _isCellTaken(int gridX, int gridY, {required String? ignoring}) {
    for (final component in state.components.values) {
      if (component.id == ignoring) continue;
      final dx = gridX - component.gridX;
      final dy = gridY - component.gridY;
      if (dx > -CanvasConstants.componentWidthCells &&
          dx < CanvasConstants.componentWidthCells &&
          dy > -CanvasConstants.componentHeightCells &&
          dy < CanvasConstants.componentHeightCells) {
        return true;
      }
    }
    return false;
  }
}

final circuitControllerProvider =
    NotifierProvider<CircuitController, Circuit>(CircuitController.new);
