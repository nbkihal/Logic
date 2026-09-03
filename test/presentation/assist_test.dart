import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/application/circuit_controller.dart';
import 'package:logic_circuit_builder/application/level_scope.dart';
import 'package:logic_circuit_builder/application/run_controller.dart';
import 'package:logic_circuit_builder/application/simulation_provider.dart';
import 'package:logic_circuit_builder/data/levels/levels_data.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/port.dart';
import 'package:logic_circuit_builder/presentation/widgets/run_bar.dart';

import 'gameplay_test.dart' show levelContainer, pumpGame;

/// Wires a NOT gate between the pin and the lamp — level 1, solved.
void solveLevelOne(WidgetTester tester) {
  final container = levelContainer(tester);
  final circuit = container.read(circuitControllerProvider.notifier);

  circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
  final gate = container
      .read(circuitControllerProvider)
      .components
      .values
      .firstWhere((c) => c.type == GateType.not)
      .id;
  circuit
    ..addWire(Port.output('in_0'), Port.input(gate, 0))
    ..addWire(Port.output(gate), Port.input('out_0', 0));
}

void main() {
  group('hints', () {
    testWidgets('the ladder narrows the palette, then names a gate',
        (tester) async {
      // The selector has a wide palette and a four-gate solution, so both
      // rungs have something real to say.
      await pumpGame(tester, 12);
      final container = levelContainer(tester);
      final level = container.read(levelProvider)!;

      expect(container.read(ruledOutGatesProvider), isEmpty);
      expect(container.read(suggestedGateProvider), isNull);

      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();

      // Level 12 shows its table, so the first rung skips the reveal and
      // goes straight to crossing gates off.
      expect(container.read(hintProvider), HintLevel.narrowed);
      expect(container.read(ruledOutGatesProvider), isNotEmpty);
      expect(
        container.read(ruledOutGatesProvider)
            .intersection(level.solutionGates.keys.toSet()),
        isEmpty,
        reason: 'a hint must never cross off a gate the solution uses',
      );

      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();

      expect(container.read(suggestedGateProvider), level.keystoneGate);
      expect(level.palette, contains(level.keystoneGate));
    });

    testWidgets('a black box spends its first rung on the table',
        (tester) async {
      await pumpGame(tester, 9);
      final container = levelContainer(tester);

      expect(container.read(hintRevealedProvider), isFalse);

      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();

      expect(container.read(hintRevealedProvider), isTrue);
      expect(container.read(ruledOutGatesProvider), isEmpty);
    });

    test('every level can back its own hints', () {
      for (final level in kLevels) {
        expect(
          level.solutionGates,
          isNotEmpty,
          reason: 'level ${level.id} has no solution to hint from',
        );
        expect(
          level.solutionGates.keys.toSet().difference(level.palette),
          isEmpty,
          reason: 'level ${level.id} hints at a gate it does not offer',
        );
        expect(
          level.solutionGates.values.reduce((a, b) => a + b),
          lessThanOrEqualTo(level.par),
          reason: 'level ${level.id} hint solution is bigger than par',
        );
        expect(level.keystoneGate, isNotNull, reason: 'level ${level.id}');
      }
    });
  });

  group('running a solved board', () {
    testWidgets('the transport appears only once the level is solved',
        (tester) async {
      await pumpGame(tester, 1);
      expect(find.byType(RunBar), findsNothing);

      solveLevelOne(tester);
      await tester.pumpAndSettle();

      // The win overlay is up; stepping past it reveals the board again.
      await tester.tap(find.text('See it run'));
      await tester.pumpAndSettle();

      expect(find.byType(RunBar), findsOneWidget);
      expect(find.text('ROW 1 / 2'), findsOneWidget);
    });

    testWidgets('stepping drives the pins through the truth table',
        (tester) async {
      await pumpGame(tester, 1);
      solveLevelOne(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See it run'));
      await tester.pumpAndSettle();

      final container = levelContainer(tester);
      bool pin() =>
          container.read(circuitControllerProvider).inputPins.single.inputValue;

      expect(pin(), isFalse);

      await tester.tap(find.byTooltip('Next row'));
      await tester.pumpAndSettle();
      expect(container.read(runProvider).row, 1);
      expect(pin(), isTrue, reason: 'row 1 of a 1-input table is A = 1');

      // And it wraps rather than running off the end.
      await tester.tap(find.byTooltip('Next row'));
      await tester.pumpAndSettle();
      expect(container.read(runProvider).row, 0);
      expect(pin(), isFalse);
    });

    testWidgets('a run is a reading of the board, not an edit', (tester) async {
      await pumpGame(tester, 1);
      solveLevelOne(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See it run'));
      await tester.pumpAndSettle();

      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);
      final before = container.read(circuitControllerProvider);

      await tester.tap(find.byTooltip('Next row'));
      await tester.pumpAndSettle();

      // Undo must rewind the player's own building, not the run-through.
      circuit.undo();
      expect(
        container.read(circuitControllerProvider).wires.length,
        lessThan(before.wires.length),
        reason: 'undo should have removed a wire, not replayed a run step',
      );
    });
  });
}
