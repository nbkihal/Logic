import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';
import '../../application/circuit_controller.dart';
import '../../application/simulation_provider.dart';
import '../../core/constants/canvas_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/port.dart';
import 'canvas_geometry.dart';
import 'circuit_painter.dart';
import 'component_layer.dart';

/// The board: a pannable, zoomable world holding the grid, the wires, and the
/// component widgets — and the place every board gesture is resolved.
///
/// Wiring is tap-to-tap rather than drag-to-drag: tap an output port, then tap
/// an input port. On a phone that beats dragging between 12px dots, and it
/// leaves the canvas pan gesture uncontested. Moving a component is a
/// long-press drag for the same reason.
class CircuitCanvas extends ConsumerStatefulWidget {
  const CircuitCanvas({
    super.key,
    this.inputNames = const [],
    this.outputNames = const [],
  });

  final List<String> inputNames;
  final List<String> outputNames;

  @override
  ConsumerState<CircuitCanvas> createState() => _CircuitCanvasState();
}

class _CircuitCanvasState extends ConsumerState<CircuitCanvas> {
  final _transform = TransformationController();
  final _worldKey = GlobalKey();

  /// The viewport the board was last framed for. Tracking the size rather
  /// than a one-shot flag means a layout that settles late — or a rotation —
  /// reframes instead of leaving the board scaled for a viewport that no
  /// longer exists.
  Size? _framedFor;

  /// Id of the component currently being long-press dragged.
  String? _dragging;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  CircuitController get _circuit =>
      ref.read(circuitControllerProvider.notifier);

  BoardController get _board =>
      ref.read(boardControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final circuit = ref.watch(circuitControllerProvider);
    final simulation = ref.watch(simulationProvider);
    final board = ref.watch(boardControllerProvider);
    final armed = board.armed != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (_framedFor != viewport && viewport.isFinite && !viewport.isEmpty) {
          _framedFor = viewport;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitToContent(viewport);
          });
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.pumice,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: armed ? AppColors.ember : AppColors.hairline,
              width: armed ? 2 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card - 1),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: CanvasConstants.minZoom,
                    maxScale: CanvasConstants.maxZoom,
                    boundaryMargin:
                        const EdgeInsets.all(CanvasConstants.fitPadding),
                    child: SizedBox(
                      key: _worldKey,
                      width: CanvasGeometry.worldSize.width,
                      height: CanvasGeometry.worldSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CircuitPainter(
                                circuit: circuit,
                                simulation: simulation,
                                showGrid: true,
                                selectedWireId: board.selectedWireId,
                              ),
                            ),
                          ),
                          // Catches taps that miss every component: wires,
                          // and empty cells where an armed gate lands.
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapUp: (details) =>
                                  _onBackgroundTap(details.localPosition),
                            ),
                          ),
                          ComponentLayer(
                            circuit: circuit,
                            valueAt: simulation.valueAt,
                            inputNames: widget.inputNames,
                            outputNames: widget.outputNames,
                            selectedComponentId: board.selectedComponentId,
                            wiringSource: board.wiringSource,
                            onComponentTap: _onComponentTap,
                            onPortTap: _onPortTap,
                            onMoveStart: (id) => _dragging = id,
                            onMoveUpdate: _onMoveUpdate,
                            onMoveEnd: () => _dragging = null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.x8,
                  bottom: AppSpacing.x8,
                  child: _ZoomControls(
                    onZoomIn: () => _zoomBy(1.25, viewport),
                    onZoomOut: () => _zoomBy(0.8, viewport),
                    onFit: () => _fitToContent(viewport),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Gestures -------------------------------------------------------

  void _onComponentTap(String id) {
    final component =
        ref.read(circuitControllerProvider).components[id];
    if (component == null) return;

    // An input pin is a switch first and an object second: tapping it flips
    // it rather than selecting it.
    if (component.type == GateType.input) {
      _circuit.toggleInput(id);
      _board.clearSelection();
      return;
    }
    _board.selectComponent(id);
  }

  void _onPortTap(Port port) {
    final board = ref.read(boardControllerProvider);
    final source = board.wiringSource;

    if (source == null) {
      if (port.isOutput) {
        _board.beginWiring(port);
        return;
      }
      // Tapping a connected input port picks its wire, so it can be cut.
      final wire =
          ref.read(circuitControllerProvider).wiresInto(port.id);
      if (wire != null) {
        _board.selectWire(wire.id);
      } else {
        _board.nudge('Start from an output dot on the right of a gate.');
      }
      return;
    }

    // Tapping another output retargets; tapping the same one cancels.
    if (port.isOutput) {
      _board.beginWiring(port);
      return;
    }

    switch (_circuit.addWire(source, port)) {
      case WireOutcome.connected:
        _board.cancelWiring();
      case WireOutcome.inputOccupied:
        _board.nudge('That input already has a wire. Tap the wire to cut it.');
      case WireOutcome.invalid:
        _board.nudge('Those two cannot be joined.');
    }
  }

  void _onMoveUpdate(String id, Offset globalPosition) {
    if (_dragging != id) return;
    final cell = CanvasGeometry.cellAt(_globalToWorld(globalPosition));
    _circuit.moveComponent(id, gridX: cell.gridX, gridY: cell.gridY);
  }

  /// A tap that reached the background: a wire, or an empty cell.
  void _onBackgroundTap(Offset worldPoint) {
    final circuit = ref.read(circuitControllerProvider);
    final board = ref.read(boardControllerProvider);

    final wireId = CanvasGeometry.wireIdAt(circuit, worldPoint);
    if (wireId != null) {
      _board.selectWire(wireId);
      return;
    }

    final armed = board.armed;
    if (armed != null) {
      final cell = CanvasGeometry.cellAt(worldPoint);
      switch (_circuit.placeComponent(
        armed,
        gridX: cell.gridX,
        gridY: cell.gridY,
        constantValue: true,
      )) {
        case PlaceOutcome.placed:
          _board.disarm();
        case PlaceOutcome.occupied:
          _board.nudge('Not enough room there — try an emptier spot.');
        case PlaceOutcome.gateLimitReached:
          _board.nudge('This level caps how many gates you can place.');
      }
      return;
    }

    if (board.wiringSource != null) {
      _board.cancelWiring();
      return;
    }
    if (board.hasSelection) _board.clearSelection();
  }

  // --- View transform -------------------------------------------------

  void _zoomBy(double factor, Size viewport) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor)
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    if (target == current) return;

    final centre = Offset(viewport.width / 2, viewport.height / 2);
    final worldCentre = _localToWorld(centre);
    setState(() {
      _transform.value = Matrix4.identity()
        ..translateByDouble(centre.dx, centre.dy, 0, 1)
        ..scaleByDouble(target, target, target, 1)
        ..translateByDouble(-worldCentre.dx, -worldCentre.dy, 0, 1);
    });
  }

  /// Frames every placed component, or the whole world if the board is bare.
  void _fitToContent(Size viewport) {
    final circuit = ref.read(circuitControllerProvider);
    final content = CanvasGeometry.contentBounds(circuit.components.values) ??
        Offset.zero & CanvasGeometry.worldSize;
    final padded = content.inflate(CanvasConstants.fitPadding);

    // Fit the tighter of the two axes, then respect the zoom limits.
    final scale = math
        .min(viewport.width / padded.width, viewport.height / padded.height)
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);

    setState(() {
      _transform.value = Matrix4.identity()
        ..translateByDouble(viewport.width / 2, viewport.height / 2, 0, 1)
        ..scaleByDouble(scale, scale, scale, 1)
        ..translateByDouble(-padded.center.dx, -padded.center.dy, 0, 1);
    });
  }

  /// Viewport-local point to world point, through the inverse transform.
  Offset _localToWorld(Offset local) => MatrixUtils.transformPoint(
        Matrix4.inverted(_transform.value),
        local,
      );

  /// Global (screen) point to world point, via the world's own render box.
  /// Long-press drags report global coordinates, and this is the one place
  /// they are converted.
  Offset _globalToWorld(Offset globalPosition) {
    final box = _worldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.globalToLocal(globalPosition);
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.obsidian, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
            tooltip: 'Zoom out',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_outlined),
            tooltip: 'Fit to board',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
            tooltip: 'Zoom in',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
