import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_controller.dart';

/// Every noise the game makes.
///
/// Short synthesized tones rather than samples: the whole set is under 120 KB
/// and each one is pitched to say something — placing lands low, a wire
/// snapping rises, a rejected action sits flat and never scolds.
enum Sfx {
  /// Any button, tab or card.
  tap('tap.wav'),

  /// A component dropped on the board.
  place('place.wav'),

  /// A wire completed between two ports.
  wire('wire.wav'),

  /// An input pin flipped.
  toggle('toggle.wav'),

  /// A component or wire removed.
  delete('delete.wav'),

  /// An action the board refused — occupied port, gate limit, cycle.
  nope('nope.wav'),

  /// The level is solved.
  win('win.wav'),

  /// One star landing in the win overlay.
  star('star.wav');

  const Sfx(this.file);

  final String file;

  String get asset => 'sfx/$file';
}

/// Plays [Sfx], honouring the sound setting, and pairs each with a haptic.
///
/// Sound and touch are one feedback channel here: the haptic fires even with
/// sound off, so the board still feels responsive on a muted phone.
class SoundController {
  SoundController(this._ref);

  final Ref _ref;

  /// A small pool, so a fast sequence of clicks overlaps instead of cutting
  /// itself off. Players tap quickly when wiring.
  final List<AudioPlayer> _pool = [];
  var _next = 0;
  static const _poolSize = 4;

  bool get _enabled => _ref.read(settingsProvider).soundEnabled;

  AudioPlayer _player() {
    if (_pool.length < _poolSize) {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _pool.add(player);
      return player;
    }
    final player = _pool[_next];
    _next = (_next + 1) % _poolSize;
    return player;
  }

  void play(Sfx sfx) {
    _haptic(sfx);
    if (!_enabled) return;
    // Fire and forget: a failed sound must never interrupt play, and on some
    // platforms the first call races the audio session opening.
    unawaited(_player().play(AssetSource(sfx.asset), volume: _volume(sfx)));
  }

  double _volume(Sfx sfx) => switch (sfx) {
        Sfx.win => 0.85,
        Sfx.star => 0.7,
        Sfx.tap => 0.45,
        _ => 0.6,
      };

  void _haptic(Sfx sfx) {
    switch (sfx) {
      case Sfx.tap:
      case Sfx.toggle:
        HapticFeedback.selectionClick();
      case Sfx.place:
      case Sfx.wire:
      case Sfx.delete:
        HapticFeedback.lightImpact();
      case Sfx.nope:
        HapticFeedback.mediumImpact();
      case Sfx.win:
      case Sfx.star:
        HapticFeedback.heavyImpact();
    }
  }

  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
  }
}

/// Ignores a future without waiting on it, and without a lint.
void unawaited(Future<void> future) {
  future.catchError((Object _) {});
}

final soundProvider = Provider<SoundController>((ref) {
  final controller = SoundController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
