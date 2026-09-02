import 'package:flutter/painting.dart';

import '../../core/constants/canvas_constants.dart';
import '../../domain/models/circuit.dart';
import '../../domain/models/component.dart';
import '../../domain/models/port.dart';

/// The one place logical grid coordinates become pixels.
///
/// `domain/` speaks only in grid cells; everything downstream of here is
/// world pixels, and the pan/zoom `Matrix4` turns those into screen pixels.
/// Keeping the conversion in a single pure class means the painter, the
/// component widgets and (from Phase 3) hit-testing cannot drift apart.
abstract final class CanvasGeometry {
  /// World-pixel origin of the cell at grid `(gridX, gridY)`.
  static Offset cellOrigin(int gridX, int gridY) => Offset(
        (gridX + CanvasConstants.originCellX) * CanvasConstants.gridCell,
        (gridY + CanvasConstants.originCellY) * CanvasConstants.gridCell,
      );

  /// The world-pixel box a component occupies.
  static Rect boundsOf(Component component) {
    final origin = cellOrigin(component.gridX, component.gridY);
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      CanvasConstants.componentWidth,
      CanvasConstants.componentHeight,
    );
  }

  /// Where a wire attaches for [port] on [component].
  ///
  /// Inputs sit on the left edge, spread evenly down it; the single output
  /// sits centred on the right edge.
  static Offset anchorOf(Component component, Port port) {
    final bounds = boundsOf(component);
    if (port.isOutput) return Offset(bounds.right, bounds.center.dy);

    final count = component.inputPortCount;
    if (count <= 1) return Offset(bounds.left, bounds.center.dy);
    final step = bounds.height / (count + 1);
    return Offset(bounds.left, bounds.top + step * (port.index + 1));
  }

  /// Anchor for a port on a component that has already been resolved.
  static Offset anchorAt(Component component, {required int inputIndex}) =>
      anchorOf(component, Port.input(component.id, inputIndex));

  /// Snaps a world-pixel point to the nearest grid cell. Used from Phase 3
  /// when a dragged component is dropped.
  static ({int gridX, int gridY}) cellAt(Offset world) => (
        gridX: (world.dx / CanvasConstants.gridCell).floor() -
            CanvasConstants.originCellX,
        gridY: (world.dy / CanvasConstants.gridCell).floor() -
            CanvasConstants.originCellY,
      );

  /// The whole board in world pixels.
  static const Size worldSize = Size(
    CanvasConstants.worldWidth,
    CanvasConstants.worldHeight,
  );

  /// The box containing every placed component, or null on an empty board.
  static Rect? contentBounds(Iterable<Component> components) {
    Rect? bounds;
    for (final component in components) {
      final rect = boundsOf(component);
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds;
  }

  /// A cubic Bezier from an output anchor to an input anchor.
  ///
  /// Control points reach sideways so fan-out from one port spreads into
  /// distinguishable curves instead of overlapping straight lines. The reach
  /// has a floor so a short backwards hop still bows rather than kinking.
  static Path wirePath(Offset from, Offset to) {
    final span = (to.dx - from.dx).abs();
    final reach = (span * CanvasConstants.wireCurvature)
        .clamp(CanvasConstants.gridCell, CanvasConstants.gridCell * 4);
    return Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + reach,
        from.dy,
        to.dx - reach,
        to.dy,
        to.dx,
        to.dy,
      );
  }

  /// The wire whose curve passes closest to [world], or null if none is
  /// within [tolerance].
  ///
  /// Walks each Bezier's metrics and samples along it — exact enough for a
  /// tap target, and far simpler than solving the cubic.
  static String? wireIdAt(
    Circuit circuit,
    Offset world, {
    double tolerance = 18,
  }) {
    String? closest;
    var best = tolerance;

    for (final wire in circuit.wires.values) {
      final source = circuit.components[wire.fromComponentId];
      final target = circuit.components[wire.toComponentId];
      if (source == null || target == null) continue;

      final path = wirePath(
        anchorOf(source, wire.from),
        anchorOf(target, wire.to),
      );
      for (final metric in path.computeMetrics()) {
        const samples = 24;
        for (var i = 0; i <= samples; i++) {
          final point =
              metric.getTangentForOffset(metric.length * i / samples)?.position;
          if (point == null) continue;
          final distance = (point - world).distance;
          if (distance < best) {
            best = distance;
            closest = wire.id;
          }
        }
      }
    }
    return closest;
  }
}
