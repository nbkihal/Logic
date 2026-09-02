import 'package:shared_preferences/shared_preferences.dart';

import 'progress_model.dart';

/// Reads and writes the single persisted blob.
///
/// One key, versioned JSON, so the schema can move without stranding
/// anyone's stars (CLAUDE.md §14). Nothing here leaves the device.
abstract interface class ProgressStore {
  Future<Progress> load();
  Future<void> save(Progress progress);
  Future<void> clear();
}

class SharedPreferencesProgressStore implements ProgressStore {
  const SharedPreferencesProgressStore();

  static const key = 'logic.progress.v1';

  @override
  Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Progress.decode(prefs.getString(key));
  }

  @override
  Future<void> save(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, progress.encode());
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// In-memory store for tests and for platforms where storage is unavailable.
class InMemoryProgressStore implements ProgressStore {
  InMemoryProgressStore([this._progress = const Progress()]);

  Progress _progress;

  @override
  Future<Progress> load() async => _progress;

  @override
  Future<void> save(Progress progress) async => _progress = progress;

  @override
  Future<void> clear() async => _progress = const Progress();
}
