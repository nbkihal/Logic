import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/data/persistence/progress_model.dart';
import 'package:logic_circuit_builder/data/persistence/progress_store.dart';

void main() {
  group('LevelProgress', () {
    test('keeps the best of each measure when a level is replayed', () {
      const first = LevelProgress(stars: 2, bestGateCount: 6, solved: true);

      final tighter = first.merge(stars: 3, gateCount: 4);
      expect(tighter.stars, 3);
      expect(tighter.bestGateCount, 4);

      // A sloppier replay must not erase the earlier record.
      final looser = tighter.merge(stars: 1, gateCount: 9);
      expect(looser.stars, 3);
      expect(looser.bestGateCount, 4);
      expect(looser.solved, isTrue);
    });

    test('a first solve sets both measures', () {
      const fresh = LevelProgress();
      expect(fresh.solved, isFalse);
      expect(fresh.bestGateCount, isNull);

      final solved = fresh.merge(stars: 2, gateCount: 5);
      expect(solved.solved, isTrue);
      expect(solved.stars, 2);
      expect(solved.bestGateCount, 5);
    });
  });

  group('unlocking', () {
    test('level 1 is always open and each solve opens the next', () {
      const progress = Progress();
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.isUnlocked(2), isFalse);

      final afterOne = progress.withLevel(
        1,
        const LevelProgress(stars: 1, solved: true),
      );
      expect(afterOne.isUnlocked(2), isTrue);
      expect(afterOne.isUnlocked(3), isFalse);
    });

    test('one star is enough to advance', () {
      final progress = const Progress().withLevel(
        1,
        const LevelProgress(stars: 1, bestGateCount: 9, solved: true),
      );
      expect(progress.isUnlocked(2), isTrue);
    });

    test('highestUnlocked walks the run and stops at the first lock', () {
      var progress = const Progress();
      expect(progress.highestUnlocked(13), 1);

      for (final id in [1, 2, 3]) {
        progress = progress.withLevel(
          id,
          const LevelProgress(stars: 2, solved: true),
        );
      }
      expect(progress.highestUnlocked(13), 4);
    });

    test('totalStars adds up across levels', () {
      final progress = const Progress()
          .withLevel(1, const LevelProgress(stars: 3, solved: true))
          .withLevel(2, const LevelProgress(stars: 2, solved: true));
      expect(progress.totalStars, 5);
    });
  });

  group('encoding', () {
    test('round-trips levels and settings', () {
      final original = const Progress()
          .withLevel(
            1,
            const LevelProgress(stars: 3, bestGateCount: 1, solved: true),
          )
          .withSettings(
            const GameSettings(
              animationSpeed: 1.5,
              reducedMotion: true,
              soundEnabled: false,
            ),
          );

      final restored = Progress.decode(original.encode());

      expect(restored.forLevel(1).stars, 3);
      expect(restored.forLevel(1).bestGateCount, 1);
      expect(restored.forLevel(1).solved, isTrue);
      expect(restored.settings.animationSpeed, 1.5);
      expect(restored.settings.reducedMotion, isTrue);
      expect(restored.settings.soundEnabled, isFalse);
    });

    test('a fresh profile decodes from nothing', () {
      expect(Progress.decode(null).levels, isEmpty);
      expect(Progress.decode('').levels, isEmpty);
    });

    test('garbage never blocks the player from playing', () {
      // A corrupt blob resets rather than throwing on launch.
      expect(Progress.decode('not json').levels, isEmpty);
      expect(Progress.decode('[1,2,3]').levels, isEmpty);
      expect(Progress.decode('{"v":99,"levels":{}}').levels, isEmpty);
    });

    test('an out-of-range animation speed is clamped on the way in', () {
      final wild = Progress.decode(
        '{"v":1,"levels":{},"settings":{"speed":99.0}}',
      );
      expect(wild.settings.animationSpeed, 2.0);
    });
  });

  group('InMemoryProgressStore', () {
    test('saves, loads and clears', () async {
      final store = InMemoryProgressStore();
      expect((await store.load()).levels, isEmpty);

      await store.save(
        const Progress().withLevel(
          1,
          const LevelProgress(stars: 3, bestGateCount: 1, solved: true),
        ),
      );
      expect((await store.load()).forLevel(1).stars, 3);

      await store.clear();
      expect((await store.load()).levels, isEmpty);
    });
  });
}
