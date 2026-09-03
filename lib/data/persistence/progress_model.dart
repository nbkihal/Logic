import 'dart:convert';

/// How one level has gone for this player.
class LevelProgress {
  const LevelProgress({
    this.stars = 0,
    this.bestGateCount,
    this.solved = false,
  });

  final int stars;

  /// Fewest gates the player has solved it with, or null if never solved.
  final int? bestGateCount;

  final bool solved;

  /// Folds a new result in, keeping the player's best of each measure.
  LevelProgress merge({required int stars, required int gateCount}) =>
      LevelProgress(
        stars: stars > this.stars ? stars : this.stars,
        bestGateCount: bestGateCount == null || gateCount < bestGateCount!
            ? gateCount
            : bestGateCount,
        solved: true,
      );

  Map<String, Object?> toJson() => {
        'stars': stars,
        'best': bestGateCount,
        'solved': solved,
      };

  static LevelProgress fromJson(Map<String, Object?> json) => LevelProgress(
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        bestGateCount: (json['best'] as num?)?.toInt(),
        solved: json['solved'] as bool? ?? false,
      );
}

/// Player-facing preferences.
class GameSettings {
  const GameSettings({
    this.animationSpeed = 1.0,
    this.reducedMotion = false,
    this.soundEnabled = true,
    this.themeId = 'caldera',
  });

  /// 0.5x to 2.0x. Higher is faster.
  final double animationSpeed;

  /// Collapses motion to instant state changes.
  final bool reducedMotion;

  final bool soundEnabled;

  /// Which [AppPalette] the player picked. An id rather than the palette
  /// itself, so persistence never has to know about colours.
  final String themeId;

  GameSettings copyWith({
    double? animationSpeed,
    bool? reducedMotion,
    bool? soundEnabled,
    String? themeId,
  }) =>
      GameSettings(
        animationSpeed: animationSpeed ?? this.animationSpeed,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        themeId: themeId ?? this.themeId,
      );

  Map<String, Object?> toJson() => {
        'speed': animationSpeed,
        'reducedMotion': reducedMotion,
        'sound': soundEnabled,
        'theme': themeId,
      };

  static GameSettings fromJson(Map<String, Object?> json) => GameSettings(
        animationSpeed:
            (json['speed'] as num?)?.toDouble().clamp(0.5, 2.0) ?? 1.0,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        soundEnabled: json['sound'] as bool? ?? true,
        themeId: json['theme'] as String? ?? 'caldera',
      );
}

/// Everything persisted, under one versioned key (CLAUDE.md §14).
class Progress {
  const Progress({
    this.levels = const {},
    this.settings = const GameSettings(),
  });

  /// Keyed by level id.
  final Map<int, LevelProgress> levels;

  final GameSettings settings;

  static const schemaVersion = 1;

  LevelProgress forLevel(int id) => levels[id] ?? const LevelProgress();

  bool isSolved(int id) => forLevel(id).solved;

  /// Linear unlock: level 1 is always open, and each later level opens once
  /// the previous one is solved with at least one star (CLAUDE.md §20.6).
  bool isUnlocked(int id) => id <= 1 || isSolved(id - 1);

  /// The furthest level the player can currently open.
  int highestUnlocked(int levelCount) {
    var highest = 1;
    for (var id = 2; id <= levelCount; id++) {
      if (!isUnlocked(id)) break;
      highest = id;
    }
    return highest;
  }

  int get totalStars =>
      levels.values.fold(0, (sum, level) => sum + level.stars);

  Progress withLevel(int id, LevelProgress progress) => Progress(
        levels: {...levels, id: progress},
        settings: settings,
      );

  Progress withSettings(GameSettings settings) =>
      Progress(levels: levels, settings: settings);

  String encode() => jsonEncode({
        'v': schemaVersion,
        'levels': {
          for (final entry in levels.entries)
            entry.key.toString(): entry.value.toJson(),
        },
        'settings': settings.toJson(),
      });

  /// Decodes stored JSON, falling back to a fresh profile on anything
  /// unreadable — a corrupt blob should never block the player from playing.
  static Progress decode(String? raw) {
    if (raw == null || raw.isEmpty) return const Progress();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return const Progress();
      if ((json['v'] as num?)?.toInt() != schemaVersion) {
        return const Progress();
      }

      final levels = <int, LevelProgress>{};
      final stored = json['levels'];
      if (stored is Map<String, Object?>) {
        for (final entry in stored.entries) {
          final id = int.tryParse(entry.key);
          final value = entry.value;
          if (id != null && value is Map<String, Object?>) {
            levels[id] = LevelProgress.fromJson(value);
          }
        }
      }

      final settings = json['settings'];
      return Progress(
        levels: levels,
        settings: settings is Map<String, Object?>
            ? GameSettings.fromJson(settings)
            : const GameSettings(),
      );
    } on FormatException {
      return const Progress();
    }
  }
}
