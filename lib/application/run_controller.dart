import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/animation_constants.dart';
import 'circuit_controller.dart';
import 'level_scope.dart';
import 'progress_controller.dart';

/// Where a run-through has got to.
class RunState {
  const RunState({this.playing = false, this.row = 0});

  /// True while the walk is advancing on its own.
  final bool playing;

  /// The truth-table row currently driven onto the input pins.
  final int row;

  bool get idle => !playing && row == 0;

  RunState copyWith({bool? playing, int? row}) =>
      RunState(playing: playing ?? this.playing, row: row ?? this.row);
}

/// Walks the board through every input combination, one row at a time.
///
/// Solving a level answers "does it work?"; this answers "watch it work".
/// It drives the real input pins and lets the ordinary simulation and
/// animations do the rest, so what the player sees during a run is exactly
/// what they would see toggling the pins by hand — just in order, and hands
/// free.
class RunController extends Notifier<RunState> {
  Timer? _timer;

  @override
  RunState build() {
    ref.onDispose(() => _timer?.cancel());
    return const RunState();
  }

  int get _rowCount {
    final level = ref.read(levelProvider);
    return level == null ? 0 : level.target.rowCount;
  }

  /// Puts row [row] on the pins. Wraps, so a run loops until stopped.
  void showRow(int row) {
    final level = ref.read(levelProvider);
    if (level == null || _rowCount == 0) return;

    final wrapped = row % _rowCount;
    ref
        .read(circuitControllerProvider.notifier)
        .driveInputs(level.target.inputsAt(wrapped));
    state = state.copyWith(row: wrapped);
  }

  void step() {
    pause();
    showRow(state.row + 1);
  }

  void stepBack() {
    pause();
    showRow(state.row + _rowCount - 1);
  }

  void play() {
    if (_rowCount == 0 || state.playing) return;
    state = state.copyWith(playing: true);
    showRow(state.row);
    _timer = Timer.periodic(_interval, (_) => showRow(state.row + 1));
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    if (state.playing) state = state.copyWith(playing: false);
  }

  void toggle() => state.playing ? pause() : play();

  /// Stops and puts the board back on row zero.
  void stop() {
    pause();
    showRow(0);
    state = const RunState();
  }

  /// A step lasts long enough for the signal to actually travel, and follows
  /// the player's animation-speed setting so a fast reader is not held up.
  Duration get _interval => AnimationConstants.scaled(
        AnimationConstants.runStep,
        ref.read(settingsProvider).animationSpeed,
      );
}

final runProvider = NotifierProvider<RunController, RunState>(
  RunController.new,
  dependencies: [levelIdProvider, levelProvider, circuitControllerProvider],
);
