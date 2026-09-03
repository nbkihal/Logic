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
    required this.palette,
    required this.pulse,
    this.selectedWireId,
  });

  /// Where the travelling dots are along their wires, 0 to 1.
  ///
  /// One phase for the whole board rather than one per wire: the dots stay in
  /// step, so a chain of gates reads as a single wave moving left to right
  /// instead of a scatter of unrelated blips. Zero freezes them (reduced
  /// motion), and the dots are drawn only on wires actually carrying a 1.
  final double pulse;

  /// A painter has no `BuildContext`, so the active palette is handed in.
  final AppPalette palette;

  final Circuit circuit;
  final SimulationResult simulation;
  final bool showGrid;

  /// Drawn in Plasma Violet so a tapped wire is obviously the delete target.
  final String? selectedWireId;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _paintGrid(canvas, size);
    _paintWires(canvas);
  }

  /// The grid reads as a halftone dot field rather than graph-paper rules —
  /// the same motif the rest of the design system uses.
  void _paintGrid(Canvas canvas, Size size) {
    final dot = Paint()..color = palette.hairline;
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
      if (wire.id == selectedWireId) {
        canvas.drawPath(path, _paint(palette.plasmaViolet, width: 9));
      }

      final value = simulation.valueAt(wire.from.id);
      switch (value) {
        case Logic.high:
          // An energised wire gets a soft bloom under the stroke, so value
          // reads from brightness as well as hue.
          canvas.drawPath(path, _paint(palette.bloom, width: 8));
          canvas.drawPath(path, _paint(palette.signalHigh));
          _paintTravellingDot(canvas, path);
        case Logic.low:
          canvas.drawPath(path, _paint(palette.signalLow));
        case Logic.floating:
          // Dashed, so floating is legible without relying on colour.
          canvas.drawPath(
            _dashed(path),
            _paint(palette.signalFloating, width: 2),
          );
      }
    }
  }

  /// A dot riding the wire from driver to reader.
  ///
  /// This is the part that teaches: a `1` is not a colour the wire happens to
  /// be, it is a value arriving from somewhere (CLAUDE.md §13.1).
  void _paintTravellingDot(Canvas canvas, Path path) {
    if (pulse <= 0) return;
    for (final metric in path.computeMetrics()) {
      final at = metric.getTangentForOffset(metric.length * pulse)?.position;
      if (at == null) continue;
      canvas
        ..drawCircle(at, 7, Paint()..color = palette.bloom)
        ..drawCircle(at, 3.5, Paint()..color = palette.signalHigh);
    }
  }

  void _strokeCycle(Canvas canvas, Path path) {
    canvas.drawPath(path, _paint(palette.warning, width: 7));
    canvas.drawPath(path, _paint(palette.obsidian, width: 2));
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
      old.pulse != pulse ||
      old.palette != palette ||
      old.showGrid != showGrid ||
      old.selectedWireId != selectedWireId ||
      !identical(old.circuit, circuit) ||
      !identical(old.simulation, simulation);
}
