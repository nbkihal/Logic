import 'package:flutter/material.dart';

import '../../domain/models/circuit.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/logic.dart';
import '../widgets/gate_widget.dart';
import 'canvas_geometry.dart';

/// Positions one [GateWidget] per component over the painter.
///
/// Kept separate from the painter so components stay real widgets: from
/// Phase 3 they carry the drag and tap gestures, and they already carry the
/// semantics a screen reader walks.
class ComponentLayer extends StatelessWidget {
  const ComponentLayer({
    super.key,
    required this.circuit,
    required this.valueAt,
    this.inputNames = const [],
    this.outputNames = const [],
  });

  final Circuit circuit;
  final Logic Function(String portId) valueAt;

  /// Truth-table column names, in the same order as [Circuit.inputPins].
  final List<String> inputNames;

  /// Truth-table column names, in the same order as [Circuit.outputLamps].
  final List<String> outputNames;

  @override
  Widget build(BuildContext context) {
    final labels = _labels();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final component in circuit.components.values)
          Positioned(
            left: CanvasGeometry.boundsOf(component).left,
            top: CanvasGeometry.boundsOf(component).top,
            child: GateWidget(
              key: ValueKey(component.id),
              component: component,
              valueAt: valueAt,
              label: labels[component.id],
            ),
          ),
      ],
    );
  }

  /// Maps each pin and lamp to its truth-table column name, falling back to
  /// a positional name when the level has not supplied one.
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
