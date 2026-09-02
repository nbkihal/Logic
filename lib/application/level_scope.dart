import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/levels/level_repository.dart';
import '../domain/models/level.dart';

/// The level currently being played.
///
/// The game screen wraps itself in a `ProviderScope` that overrides this, so
/// every board provider downstream is scoped to one level and gets a clean
/// slate when another is opened. Nothing has to push state into a controller
/// from a widget lifecycle, which Riverpod refuses anyway.
final levelIdProvider = Provider<int>(
  (ref) => throw StateError(
    'levelIdProvider must be overridden by the game screen scope',
  ),
);

final levelRepositoryProvider =
    Provider<LevelRepository>((ref) => const LevelRepository());

/// The level record itself, or null if the route named one that does not
/// exist.
final levelProvider = Provider<Level?>((ref) {
  return ref
      .watch(levelRepositoryProvider)
      .byId(ref.watch(levelIdProvider));
});
