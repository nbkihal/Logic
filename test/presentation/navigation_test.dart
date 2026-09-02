import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/app.dart';
import 'package:logic_circuit_builder/application/progress_controller.dart';
import 'package:logic_circuit_builder/core/theme/app_colors.dart';
import 'package:logic_circuit_builder/data/persistence/progress_model.dart';
import 'package:logic_circuit_builder/data/persistence/progress_store.dart';
import 'package:logic_circuit_builder/presentation/screens/level_select/level_select_screen.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Progress progress = const Progress(),
  Size size = const Size(400, 820),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressStoreProvider
            .overrideWithValue(InMemoryProgressStore(progress)),
      ],
      child: const LogicCircuitBuilderApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('home', () {
    testWidgets('boots to a themed Home', (tester) async {
      await pumpApp(tester);

      expect(find.text('LOGIC'), findsOneWidget);
      expect(find.text('CIRCUIT BUILDER'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.pumice);
    });

    testWidgets('offers Play on a fresh profile', (tester) async {
      await pumpApp(tester);
      expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);
      expect(find.textContaining('stars'), findsNothing);
    });

    testWidgets('offers Continue once there is progress', (tester) async {
      await pumpApp(
        tester,
        progress: const Progress().withLevel(
          1,
          const LevelProgress(stars: 3, bestGateCount: 1, solved: true),
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
      expect(find.textContaining('3 of 39 stars'), findsOneWidget);
    });
  });

  group('routes', () {
    testWidgets('Home to Levels and back', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Levels'));
      await tester.pumpAndSettle();
      expect(find.text('LEVELS'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIC'), findsOneWidget);
    });

    testWidgets('Home to How to play and into the game', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'How to play'));
      await tester.pumpAndSettle();
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('Wire it up'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Start playing'),
        200,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Start playing'));
      await tester.pumpAndSettle();
      expect(find.text('LEVELS'), findsOneWidget);
    });

    testWidgets('Home to Settings and back', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Settings'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Reduced motion'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIC'), findsOneWidget);
    });

    testWidgets('Play opens the level the player is up to', (tester) async {
      await pumpApp(
        tester,
        progress: const Progress()
            .withLevel(1, const LevelProgress(stars: 3, solved: true))
            .withLevel(2, const LevelProgress(stars: 1, solved: true)),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Levels 1 and 2 solved, so level 3 is where they left off.
      expect(find.text('EITHER ON'), findsOneWidget);
    });
  });

  group('level select', () {
    testWidgets('locks everything past the furthest solve', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Levels'));
      await tester.pumpAndSettle();

      final cards = tester.widgetList<LevelCard>(find.byType(LevelCard));
      expect(cards.first.unlocked, isTrue);
      expect(cards.where((c) => c.unlocked), hasLength(1));
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('shows stars and best gate count on a solved level',
        (tester) async {
      await pumpApp(
        tester,
        progress: const Progress().withLevel(
          1,
          const LevelProgress(stars: 3, bestGateCount: 1, solved: true),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Levels'));
      await tester.pumpAndSettle();

      expect(find.text('BEST 1'), findsOneWidget);
      expect(find.text('PAR 1'), findsWidgets);
    });

    testWidgets('tapping an unlocked card opens that level', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LevelCard).first);
      await tester.pumpAndSettle();

      expect(find.text('INVERT IT'), findsOneWidget);
    });

    testWidgets('a locked card does not open', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LevelCard).at(3), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('LEVELS'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('toggling reduced motion persists it', (tester) async {
      final store = InMemoryProgressStore();
      await tester.binding.setSurfaceSize(const Size(400, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [progressStoreProvider.overrideWithValue(store)],
          child: const LogicCircuitBuilderApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect((await store.load()).settings.reducedMotion, isTrue);
    });

    testWidgets('reset asks before wiping progress', (tester) async {
      final store = InMemoryProgressStore(
        const Progress().withLevel(
          1,
          const LevelProgress(stars: 3, bestGateCount: 1, solved: true),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(400, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [progressStoreProvider.overrideWithValue(store)],
          child: const LogicCircuitBuilderApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset all progress'));
      await tester.pumpAndSettle();

      expect(find.text('Reset all progress?'), findsOneWidget);

      // Backing out leaves the record alone.
      await tester.tap(find.widgetWithText(TextButton, 'Keep it'));
      await tester.pumpAndSettle();
      expect((await store.load()).forLevel(1).stars, 3);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset all progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();

      expect((await store.load()).levels, isEmpty);
    });
  });
}
