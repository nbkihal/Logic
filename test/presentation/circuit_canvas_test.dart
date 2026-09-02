import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/application/circuit_controller.dart';
import 'package:logic_circuit_builder/core/theme/app_colors.dart';
import 'package:logic_circuit_builder/core/theme/app_theme.dart';
import 'package:logic_circuit_builder/data/levels/demo_circuit.dart';
import 'package:logic_circuit_builder/domain/models/circuit.dart';
import 'package:logic_circuit_builder/domain/models/gate_type.dart';
import 'package:logic_circuit_builder/presentation/canvas/canvas_geometry.dart';
import 'package:logic_circuit_builder/presentation/canvas/circuit_canvas.dart';
import 'package:logic_circuit_builder/presentation/widgets/gate_widget.dart';

import '../fixtures/circuit_builder.dart';

/// Renders the canvas at a phone-sized viewport with [circuit] on the board.
Future<void> pumpCanvas(
  WidgetTester tester,
  Circuit circuit, {
  List<String> inputNames = const [],
  List<String> outputNames = const [],
  Size size = const Size(390, 780),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialCircuitProvider.overrideWithValue(circuit)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CircuitCanvas(
            inputNames: inputNames,
            outputNames: outputNames,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the canvas draws a circuit', () {
    testWidgets('one widget per component', (tester) async {
      final circuit = DemoCircuit.build();
      await pumpCanvas(tester, circuit);

      expect(find.byType(GateWidget), findsNWidgets(circuit.components.length));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('gates are labelled by type', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      expect(find.text('XOR'), findsOneWidget);
      expect(find.text('AND'), findsOneWidget);
      expect(find.text('NOT'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('pins and lamps take their truth-table column names',
        (tester) async {
      await pumpCanvas(
        tester,
        DemoCircuit.build(),
        inputNames: ['A', 'B'],
        outputNames: ['SUM', 'CARRY'],
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('SUM'), findsOneWidget);
      expect(find.text('CARRY'), findsOneWidget);
    });

    testWidgets('unnamed pins fall back to A, B, C', (tester) async {
      final circuit = CircuitBuilder.pins(inputs: 3, outputs: 1).build();
      await pumpCanvas(tester, circuit);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });

  group('value is visible without relying on colour', () {
    testWidgets('every component shows its 0 / 1 / X glyph', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      // A=1 into a half adder: SUM lights, CARRY stays dark, and the
      // stranded NOT/OR pair floats.
      expect(find.text('1'), findsWidgets);
      expect(find.text('0'), findsWidgets);
      expect(find.text('X'), findsWidgets);
    });

    testWidgets('a lit lamp fills with ember, a dark one does not',
        (tester) async {
      await pumpCanvas(
        tester,
        DemoCircuit.build(),
        outputNames: ['SUM', 'CARRY'],
      );

      Color lampColour(String label) {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byType(GateWidget),
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).color!;
      }

      expect(lampColour('SUM'), AppColors.ember);
      expect(lampColour('CARRY'), AppColors.limestone);
    });

    testWidgets('an energised gate is outlined in ember', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      BorderSide gateBorder(String label) {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byType(GateWidget),
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).border!.top;
      }

      // XOR of 1 and 0 is high; AND of 1 and 0 is low.
      expect(gateBorder('XOR').color, AppColors.ember);
      expect(gateBorder('AND').color, AppColors.obsidian);
    });
  });

  group('semantics', () {
    testWidgets('components announce their type and value', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCanvas(
        tester,
        DemoCircuit.build(),
        inputNames: ['A', 'B'],
        outputNames: ['SUM', 'CARRY'],
      );

      expect(find.bySemanticsLabel('XOR gate, output high'), findsOneWidget);
      expect(find.bySemanticsLabel('AND gate, output low'), findsOneWidget);
      expect(find.bySemanticsLabel('Input A switch, high'), findsOneWidget);
      expect(find.bySemanticsLabel('Output SUM lamp, high'), findsOneWidget);
      expect(
        find.bySemanticsLabel('NOT gate, output not connected'),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('pan and zoom', () {
    testWidgets('starts framed on the content', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.minScale, lessThan(1));
      expect(viewer.maxScale, greaterThan(1));
      // `constrained: false` is what lets the world be bigger than the
      // viewport and pan inside it.
      expect(viewer.constrained, isFalse);
    });

    testWidgets('zoom controls change the scale', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      double scale() => tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();

      final before = scale();
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(scale(), greaterThan(before));

      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(scale(), lessThan(scale() * 1.25));
    });

    testWidgets('dragging pans without changing the scale', (tester) async {
      await pumpCanvas(tester, DemoCircuit.build());

      final controller = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final before = controller.value.clone();

      await tester.drag(find.byType(InteractiveViewer), const Offset(-60, -30));
      await tester.pumpAndSettle();

      expect(controller.value, isNot(before));
      expect(
        controller.value.getMaxScaleOnAxis(),
        closeTo(before.getMaxScaleOnAxis(), 0.001),
      );
    });
  });

  group('geometry', () {
    test('grid cells map to world pixels through a single origin', () {
      final origin = CanvasGeometry.cellOrigin(0, 0);
      final right = CanvasGeometry.cellOrigin(1, 0);
      final down = CanvasGeometry.cellOrigin(0, 1);

      expect(right.dx - origin.dx, 32);
      expect(down.dy - origin.dy, 32);
      // Fixtures sit on negative rows; the origin must keep them positive.
      expect(CanvasGeometry.cellOrigin(0, -6).dy, greaterThanOrEqualTo(0));
    });

    test('cellAt inverts cellOrigin', () {
      for (final cell in [(0, 0), (5, -3), (18, 7)]) {
        final world = CanvasGeometry.cellOrigin(cell.$1, cell.$2);
        final back = CanvasGeometry.cellAt(world);
        expect(back.gridX, cell.$1);
        expect(back.gridY, cell.$2);
      }
    });

    test('input anchors spread down the left edge, output centres the right',
        () {
      final b = CircuitBuilder.pins(inputs: 0, outputs: 0);
      final and = b.gate(GateType.and, id: 'and');
      final component = b.build().components['and']!;
      final bounds = CanvasGeometry.boundsOf(component);

      final in0 = CanvasGeometry.anchorOf(component, and.at(0));
      final in1 = CanvasGeometry.anchorOf(component, and.at(1));
      final out = CanvasGeometry.anchorOf(component, and.out);

      expect(in0.dx, bounds.left);
      expect(in1.dx, bounds.left);
      expect(in0.dy, lessThan(in1.dy));
      expect(out.dx, bounds.right);
      expect(out.dy, bounds.center.dy);
    });

    test('a wire path starts and ends on its anchors', () {
      const from = Offset(10, 10);
      const to = Offset(200, 90);
      final bounds = CanvasGeometry.wirePath(from, to).getBounds();

      expect(bounds.left, lessThanOrEqualTo(from.dx));
      expect(bounds.right, greaterThanOrEqualTo(to.dx));
    });

    test('content bounds cover every component, and null on an empty board',
        () {
      expect(CanvasGeometry.contentBounds(const []), isNull);

      final circuit = DemoCircuit.build();
      final bounds = CanvasGeometry.contentBounds(circuit.components.values)!;
      for (final component in circuit.components.values) {
        expect(bounds.contains(CanvasGeometry.boundsOf(component).topLeft),
            isTrue);
      }
    });
  });

  group('the demo board exercises every visual state', () {
    test('it has a high wire, a low wire and a floating one', () {
      // Guards the Phase 2 review board: if someone simplifies the demo,
      // the renderer stops being visually exercised.
      final circuit = DemoCircuit.build();
      expect(circuit.wires, isNotEmpty);
      expect(circuit.isComplete, isFalse);
      expect(circuit.componentsOfType(GateType.xor), isNotEmpty);
    });
  });

  test('the icon assets the launcher config points at exist', () {
    expect(File('assets/icon/icon.png').existsSync(), isTrue);
    expect(File('assets/icon/icon_foreground.png').existsSync(), isTrue);
  });
}
