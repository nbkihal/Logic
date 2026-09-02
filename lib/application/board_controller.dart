import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/gate_type.dart';
import '../domain/models/port.dart';

/// Transient, per-level board state that belongs to the UI rather than to the
/// circuit: what is armed in the palette, what is selected, and whether a
/// wire is half-drawn.
///
/// Kept out of [CircuitController] so undo never rewinds a selection — undo
/// should move the circuit, not the cursor.
class BoardUiState {
  const BoardUiState({
    this.armed,
    this.selectedComponentId,
    this.selectedWireId,
    this.wiringSource,
    this.nudge,
    this.nudgeToken = 0,
  });

  /// The palette item waiting to be dropped on the board.
  final GateType? armed;

  final String? selectedComponentId;
  final String? selectedWireId;

  /// The output port a wire is being drawn from.
  final Port? wiringSource;

  /// A short message to show the player — a rejected wire, a full board.
  final String? nudge;

  /// Bumped on every nudge so the same message can be shown twice in a row.
  final int nudgeToken;

  bool get hasSelection =>
      selectedComponentId != null || selectedWireId != null;

  BoardUiState copyWith({
    GateType? armed,
    String? selectedComponentId,
    String? selectedWireId,
    Port? wiringSource,
    String? nudge,
    int? nudgeToken,
    bool clearArmed = false,
    bool clearSelection = false,
    bool clearWiring = false,
  }) =>
      BoardUiState(
        armed: clearArmed ? null : (armed ?? this.armed),
        selectedComponentId: clearSelection
            ? null
            : (selectedComponentId ?? this.selectedComponentId),
        selectedWireId:
            clearSelection ? null : (selectedWireId ?? this.selectedWireId),
        wiringSource: clearWiring ? null : (wiringSource ?? this.wiringSource),
        nudge: nudge,
        nudgeToken: nudgeToken ?? this.nudgeToken,
      );
}

class BoardController extends FamilyNotifier<BoardUiState, int> {
  @override
  BoardUiState build(int levelId) => const BoardUiState();

  /// Arms a palette item, or disarms it when the same one is tapped again.
  void arm(GateType type) {
    state = state.armed == type
        ? state.copyWith(clearArmed: true)
        : BoardUiState(armed: type);
  }

  void disarm() => state = state.copyWith(clearArmed: true);

  /// Selecting replaces the whole UI state: a new selection cancels a
  /// half-drawn wire and any armed palette item, which is what a player
  /// expects from tapping something else.
  void selectComponent(String id) =>
      state = BoardUiState(selectedComponentId: id);

  void selectWire(String id) => state = BoardUiState(selectedWireId: id);

  void clearSelection() => state = state.copyWith(clearSelection: true);

  /// Begins, retargets, or cancels a wire depending on what was tapped.
  void beginWiring(Port from) {
    state = state.wiringSource?.id == from.id
        ? state.copyWith(clearWiring: true)
        : BoardUiState(wiringSource: from, armed: state.armed);
  }

  void cancelWiring() => state = state.copyWith(clearWiring: true);

  void nudge(String message) => state = state.copyWith(
        nudge: message,
        nudgeToken: state.nudgeToken + 1,
      );

  void clearNudge() => state = state.copyWith(nudgeToken: state.nudgeToken);
}

final boardControllerProvider =
    NotifierProvider.family<BoardController, BoardUiState, int>(
  BoardController.new,
);
