import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/persistence/progress_model.dart';
import '../data/persistence/progress_store.dart';

/// The store backing progress. Overridden in tests with an in-memory one.
final progressStoreProvider =
    Provider<ProgressStore>((ref) => const SharedPreferencesProgressStore());

/// Stars, best gate counts, unlocks and settings.
///
/// Loading is async, so the app renders a sensible empty profile first and
/// swaps in the stored one when it arrives — nobody waits on a spinner to see
/// the home screen.
class ProgressController extends AsyncNotifier<Progress> {
  @override
  Future<Progress> build() => ref.read(progressStoreProvider).load();

  Future<void> _write(Progress next) async {
    state = AsyncData(next);
    await ref.read(progressStoreProvider).save(next);
  }

  /// Records a solve, keeping the player's best stars and fewest gates.
  Future<void> recordSolve({
    required int levelId,
    required int stars,
    required int gateCount,
  }) async {
    final current = state.valueOrNull ?? const Progress();
    await _write(
      current.withLevel(
        levelId,
        current.forLevel(levelId).merge(stars: stars, gateCount: gateCount),
      ),
    );
  }

  Future<void> updateSettings(GameSettings settings) async {
    final current = state.valueOrNull ?? const Progress();
    await _write(current.withSettings(settings));
  }

  /// Wipes stars and bests but keeps the player's settings — resetting
  /// progress should not also undo their motion or sound preferences.
  Future<void> resetProgress() async {
    final settings = (state.valueOrNull ?? const Progress()).settings;
    await _write(Progress(settings: settings));
  }
}

final progressControllerProvider =
    AsyncNotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);

/// Progress with a safe default while the store is still loading.
final progressProvider = Provider<Progress>((ref) {
  return ref.watch(progressControllerProvider).valueOrNull ?? const Progress();
});

/// Current settings, likewise defaulted.
final settingsProvider = Provider<GameSettings>((ref) {
  return ref.watch(progressProvider).settings;
});
