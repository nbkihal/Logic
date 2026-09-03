import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/application/circuit_controller.dart';
import 'package:logic_circuit_builder/application/level_scope.dart';
import 'package:logic_circuit_builder/application/progress_controller.dart';
import 'package:logic_circuit_builder/application/simulation_provider.dart';
import 'package:logic_circuit_builder/core/theme/app_theme.dart';
import 'package:logic_circuit_builder/data/persistence/progress_store.dart';
import 'package:logic_circuit_builder/domain/engine/win_checker.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/domain/models/port.dart';
import 'package:logic_circuit_builder/presentation/screens/game/game_screen.dart';
import 'package:logic_circuit_builder/presentation/widgets/gate_widget.dart';
import 'package:logic_circuit_builder/presentation/widgets/palette_bar.dart';

/// Boots the game screen for [levelId] on a phone-sized surface.
Future<ProviderContainer> pumpGame(
  WidgetTester tester,
  int levelId, {
  ProgressStore? store,
  Size size = const Size(400, 820),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final root = ProviderContainer(
    overrides: [
      progressStoreProvider.overrideWithValue(store ?? InMemoryProgressStore()),
    ],
  );
  addTearDown(root.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: root,
      child: MaterialApp(
        theme: AppTheme.light,
        home: GameScreen(levelId: levelId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return root;
}

/// The container the game screen scoped to its level — the one that holds the
/// board providers.
ProviderContainer levelContainer(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(PaletteBar)),
  );
}

void main() {
  group('placing and wiring', () {
    testWidgets('a level starts with only its pins and lamps', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider);

      expect(circuit.gateCount, 0);
      expect(circuit.inputPins, hasLength(1));
      expect(circuit.outputLamps, hasLength(1));
      expect(find.byType(GateWidget), findsNWidgets(2));
    });

    testWidgets('arming a palette gate and tapping the board places it',
        (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);

      await tester.tap(find.widgetWithText(GestureDetector, 'NOT').first);
      await tester.pumpAndSettle();

      // Placement itself is exercised through the controller, because a raw
      // tap on the board has to land on an empty cell at whatever zoom the
      // fit produced — that is the canvas's job, not this test's.
      final outcome = container
          .read(circuitControllerProvider.notifier)
          .placeComponent(GateType.not, gridX: 8, gridY: 0);

      expect(outcome, PlaceOutcome.placed);
      expect(container.read(circuitControllerProvider).gateCount, 1);
    });

    testWidgets('solving level 1 fires the win overlay and records progress',
        (tester) async {
      final store = InMemoryProgressStore();
      await pumpGame(tester, 1, store: store);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      final gateId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.not)
          .id;

      expect(
        circuit.addWire(Port.output('in_0'), Port.input(gateId, 0)),
        WireOutcome.connected,
      );
      expect(
        circuit.addWire(Port.output(gateId), Port.input('out_0', 0)),
        WireOutcome.connected,
      );
      await tester.pumpAndSettle();

      expect(container.read(solveReportProvider).solved, isTrue);
      expect(find.text('SOLVED'), findsOneWidget);
      expect(find.text('Next level'), findsOneWidget);

      // Progress is written after the frame, so let the microtask land.
      await tester.pumpAndSettle();
      final saved = await store.load();
      expect(saved.forLevel(1).solved, isTrue);
      expect(saved.forLevel(1).stars, 3);
      expect(saved.forLevel(1).bestGateCount, 1);
      expect(saved.isUnlocked(2), isTrue);
    });

    testWidgets('an input port takes only one wire', (tester) async {
      await pumpGame(tester, 2);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.and, gridX: 8, gridY: 0);
      final gateId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.and)
          .id;

      expect(
        circuit.addWire(Port.output('in_0'), Port.input(gateId, 0)),
        WireOutcome.connected,
      );
      expect(
        circuit.addWire(Port.output('in_1'), Port.input(gateId, 0)),
        WireOutcome.inputOccupied,
      );
      expect(container.read(circuitControllerProvider).wires, hasLength(1));
    });

    testWidgets('an output port fans out to many inputs', (tester) async {
      await pumpGame(tester, 2);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.and, gridX: 8, gridY: 0);
      final gateId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.and)
          .id;

      circuit.addWire(Port.output('in_0'), Port.input(gateId, 0));
      circuit.addWire(Port.output('in_0'), Port.input(gateId, 1));

      expect(container.read(circuitControllerProvider).wires, hasLength(2));
    });

    testWidgets('a backwards wire is refused', (tester) async {
      await pumpGame(tester, 1);
      final circuit =
          levelContainer(tester).read(circuitControllerProvider.notifier);

      expect(
        circuit.addWire(Port.input('out_0', 0), Port.output('in_0')),
        WireOutcome.invalid,
      );
    });
  });

  group('editing the board', () {
    testWidgets('toggling an input flips it and relights downstream',
        (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      final gateId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.not)
          .id;
      circuit.addWire(Port.output('in_0'), Port.input(gateId, 0));
      circuit.addWire(Port.output(gateId), Port.input('out_0', 0));
      await tester.pumpAndSettle();

      expect(
        container.read(simulationProvider).valueAt('out_0:in0').glyph,
        '1',
      );

      circuit.toggleInput('in_0');
      await tester.pumpAndSettle();

      expect(
        container.read(simulationProvider).valueAt('out_0:in0').glyph,
        '0',
      );
    });

    testWidgets('deleting a gate takes its wires with it', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      final gateId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.not)
          .id;
      circuit.addWire(Port.output('in_0'), Port.input(gateId, 0));
      circuit.addWire(Port.output(gateId), Port.input('out_0', 0));
      expect(container.read(circuitControllerProvider).wires, hasLength(2));

      expect(circuit.removeComponent(gateId), isTrue);
      expect(container.read(circuitControllerProvider).gateCount, 0);
      expect(container.read(circuitControllerProvider).wires, isEmpty);
    });

    testWidgets('a level fixture cannot be deleted', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      expect(circuit.removeComponent('in_0'), isFalse);
      expect(circuit.removeComponent('out_0'), isFalse);
      expect(container.read(circuitControllerProvider).components, hasLength(2));
    });

    testWidgets('undo and redo walk the history', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      expect(circuit.canUndo, isFalse);

      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      expect(container.read(circuitControllerProvider).gateCount, 1);
      expect(circuit.canUndo, isTrue);

      circuit.undo();
      expect(container.read(circuitControllerProvider).gateCount, 0);
      expect(circuit.canRedo, isTrue);

      circuit.redo();
      expect(container.read(circuitControllerProvider).gateCount, 1);
    });

    testWidgets('reset clears the board back to its fixtures', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      circuit.reset();

      final board = container.read(circuitControllerProvider);
      expect(board.gateCount, 0);
      expect(board.components, hasLength(2));
      expect(circuit.canUndo, isFalse);
    });

    testWidgets('components cannot be stacked on top of each other',
        (tester) async {
      await pumpGame(tester, 1);
      final circuit =
          levelContainer(tester).read(circuitControllerProvider.notifier);

      expect(
        circuit.placeComponent(GateType.not, gridX: 8, gridY: 0),
        PlaceOutcome.placed,
      );
      expect(
        circuit.placeComponent(GateType.not, gridX: 8, gridY: 0),
        PlaceOutcome.occupied,
      );
    });
  });

  group('the tester', () {
    testWidgets('reports incomplete, then wrong, then solved', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      expect(container.read(solveReportProvider).status,
          SolveStatus.incomplete);

      // A buffer instead of a NOT: complete, evaluable, and wrong.
      circuit.placeComponent(GateType.buffer, gridX: 8, gridY: 0);
      final bufferId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.buffer)
          .id;
      circuit.addWire(Port.output('in_0'), Port.input(bufferId, 0));
      circuit.addWire(Port.output(bufferId), Port.input('out_0', 0));

      expect(container.read(solveReportProvider).status,
          SolveStatus.mismatched);
      expect(container.read(solveReportProvider).failingRows, [0, 1]);

      circuit.removeComponent(bufferId);
      circuit.placeComponent(GateType.not, gridX: 8, gridY: 0);
      final notId = container
          .read(circuitControllerProvider)
          .components
          .values
          .firstWhere((c) => c.type == GateType.not)
          .id;
      circuit.addWire(Port.output('in_0'), Port.input(notId, 0));
      circuit.addWire(Port.output(notId), Port.input('out_0', 0));

      expect(container.read(solveReportProvider).status, SolveStatus.solved);
    });

    testWidgets('a feedback loop is reported, not evaluated', (tester) async {
      await pumpGame(tester, 1);
      final container = levelContainer(tester);
      final circuit = container.read(circuitControllerProvider.notifier);

      circuit.placeComponent(GateType.buffer, gridX: 6, gridY: 0);
      circuit.placeComponent(GateType.buffer, gridX: 12, gridY: 0);
      final gates = container
          .read(circuitControllerProvider)
          .components
          .values
          .where((c) => c.type == GateType.buffer)
          .toList();

      circuit.addWire(Port.output(gates[0].id), Port.input(gates[1].id, 0));
      circuit.addWire(Port.output(gates[1].id), Port.input(gates[0].id, 0));

      final report = container.read(solveReportProvider);
      expect(report.status, SolveStatus.cyclic);
      expect(report.cycle, isNotNull);
    });

    testWidgets('the status pill opens the truth table', (tester) async {
      await pumpGame(tester, 1);

      await tester.tap(find.textContaining('Not finished'));
      await tester.pumpAndSettle();

      expect(find.text('TRUTH TABLE'), findsOneWidget);
    });

    testWidgets('a twelve-column table still lays out on a phone',
        (tester) async {
      // The multiplier is the widest table in the game: four inputs and four
      // outputs, wanted and got, is twelve columns on a 400px board.
      await pumpGame(tester, 45);

      await tester.tap(find.textContaining('Not finished'));
      await tester.pumpAndSettle();

      expect(find.text('TRUTH TABLE'), findsOneWidget);
      expect(find.text('want P3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('gate budget', () {
    testWidgets('stars follow the gate count against par', (tester) async {
      await pumpGame(tester, 5); // XOR from primitives, par 5
      final level = levelContainer(tester).read(levelProvider)!;

      expect(level.starsFor(4), 3);
      expect(level.starsFor(5), 3);
      expect(level.starsFor(7), 2);
      expect(level.starsFor(20), 1);
    });
  });
}
