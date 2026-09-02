import 'package:flutter/material.dart';

import '../../domain/models/circuit.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/logic.dart';
import '../../domain/models/port.dart';
import '../widgets/gate_widget.dart';
import 'canvas_geometry.dart';

/// Positions one [GateWidget] per component over the painter and routes their
/// gestures back up to the canvas.
class ComponentLayer extends StatelessWidget {
  const ComponentLayer({
    super.key,
    required this.circuit,
    required this.valueAt,
    this.inputNames = const [],
    this.outputNames = const [],
    this.selectedComponentId,
    this.wiringSource,
    this.onComponentTap,
    this.onPortTap,
    this.onMoveStart,
    this.onMoveUpdate,
    this.onMoveEnd,
  });

  final Circuit circuit;
  final Logic Function(String portId) valueAt;

  /// Truth-table column names, in the same order as [Circuit.inputPins].
  final List<String> inputNames;
  final List<String> outputNames;

  final String? selectedComponentId;
  final Port? wiringSource;

  final void Function(String componentId)? onComponentTap;
  final void Function(Port port)? onPortTap;
  final void Function(String componentId)? onMoveStart;
  final void Function(String componentId, Offset globalPosition)? onMoveUpdate;
  final VoidCallback? onMoveEnd;

  @override
  Widget build(BuildContext context) {
    final labels = _labels();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final component in circuit.components.values)
          Positioned(
            // The widget carries port-target padding, so it sits back and up
            // from the component's own bounds by that inset.
            left: CanvasGeometry.boundsOf(component).left - GateWidget.inset,
            top: CanvasGeometry.boundsOf(component).top - GateWidget.inset,
            child: GateWidget(
              key: ValueKey(component.id),
              component: component,
              valueAt: valueAt,
              label: labels[component.id],
              selected: component.id == selectedComponentId,
              wiringSource: wiringSource,
              onTap: () => onComponentTap?.call(component.id),
              onPortTap: onPortTap,
              onMoveStart: () => onMoveStart?.call(component.id),
              onMoveUpdate: (global) =>
                  onMoveUpdate?.call(component.id, global),
              onMoveEnd: onMoveEnd,
            ),
          ),
      ],
    );
  }

  /// Maps each pin and lamp to its truth-table column name, falling back to a
  /// positional name when the level has not supplied one.
  Map<String, String> _labels() {
    final labels = <String, String>{};

    final pins = circuit.inputPins;
    for (var i = 0; i < pins.length; i++) {
      labels[pins[i].id] =
          i < inputNames.length ? inputNames[i] : _positional(i);
    }

    final lamps = circuit.outputLamps;
    for (var i = 0; i < lamps.length; i++) {
      labels[lamps[i].id] =
          i < outputNames.length ? outputNames[i] : 'Q${i + 1}';
    }

    for (final component in circuit.componentsOfType(GateType.constant)) {
      labels[component.id] = component.constantValue ? '1' : '0';
    }

    return labels;
  }

  /// A, B, C, ... for pins the level did not name.
  static String _positional(int index) =>
      String.fromCharCode('A'.codeUnitAt(0) + index);
}
