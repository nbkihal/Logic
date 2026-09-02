import 'package:flutter/material.dart';

import '../../core/constants/canvas_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/engine/simulator.dart';
import '../../domain/models/circuit.dart';
import '../../domain/models/logic.dart';
import 'canvas_geometry.dart';

/// Draws the board behind the components: the grid, then every wire.
///
/// Components themselves are widgets stacked over this painter so they can
/// carry gestures and semantics (CLAUDE.md §12).
class CircuitPainter extends CustomPainter {
  const CircuitPainter({
    required this.circuit,
    required this.simulation,
    required this.showGrid,
  });

  final Circuit circuit;
  final SimulationResult simulation;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _paintGrid(canvas, size);
    _paintWires(canvas);
  }

  /// The grid reads as a halftone dot field rather than graph-paper rules —
  /// the same motif the rest of the design system uses.
  void _paintGrid(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.hairline;
    const step = CanvasConstants.gridCell;

    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  void _paintWires(Canvas canvas) {
    final cycleWires = simulation.cycle?.wireIds ?? const <String>{};

    for (final wire in circuit.wires.values) {
      final source = circuit.components[wire.fromComponentId];
      final target = circuit.components[wire.toComponentId];
      if (source == null || target == null) continue;

      final path = CanvasGeometry.wirePath(
        CanvasGeometry.anchorOf(source, wire.from),
        CanvasGeometry.anchorOf(target, wire.to),
      );

      if (cycleWires.contains(wire.id)) {
        _strokeCycle(canvas, path);
        continue;
      }

      final value = simulation.valueAt(wire.from.id);
      switch (value) {
        case Logic.high:
          // An energised wire gets a soft bloom under the stroke, so value
          // reads from brightness as well as hue.
          canvas.drawPath(path, _paint(SignalColors.bloom, width: 8));
          canvas.drawPath(path, _paint(SignalColors.high));
        case Logic.low:
          canvas.drawPath(path, _paint(SignalColors.low));
        case Logic.floating:
          // Dashed, so floating is legible without relying on colour.
          canvas.drawPath(
            _dashed(path),
            _paint(SignalColors.floating, width: 2),
          );
      }
    }
  }

  void _strokeCycle(Canvas canvas, Path path) {
    canvas.drawPath(path, _paint(SignalColors.warning, width: 7));
    canvas.drawPath(path, _paint(AppColors.obsidian, width: 2));
  }

  Paint _paint(Color color, {double width = CanvasConstants.wireStroke}) =>
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

  /// Rebuilds [path] as a dash pattern by walking its metrics.
  Path _dashed(Path path, {double dash = 8, double gap = 6}) {
    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gap;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(CircuitPainter old) =>
      old.showGrid != showGrid ||
      !identical(old.circuit, circuit) ||
      !identical(old.simulation, simulation);
}
