import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circuit_controller.dart';
import '../../application/simulation_provider.dart';
import '../../core/constants/canvas_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'canvas_geometry.dart';
import 'circuit_painter.dart';
import 'component_layer.dart';

/// The board: a pannable, zoomable world holding the grid, the wires, and
/// the component widgets.
///
/// One `Matrix4` carries pan and zoom for everything, so world-to-screen and
/// its inverse stay in one place — which is what makes Phase 3 hit-testing
/// tractable.
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

  /// Set once the first layout has told us how big the viewport is.
  bool _framed = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circuit = ref.watch(circuitControllerProvider);
    final simulation = ref.watch(simulationProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_framed && viewport.isFinite && !viewport.isEmpty) {
          _framed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitToContent(viewport);
          });
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.pumice,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: CanvasConstants.minZoom,
                    maxScale: CanvasConstants.maxZoom,
                    boundaryMargin: const EdgeInsets.all(
                      CanvasConstants.fitPadding,
                    ),
                    child: SizedBox(
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
                              ),
                            ),
                          ),
                          ComponentLayer(
                            circuit: circuit,
                            valueAt: simulation.valueAt,
                            inputNames: widget.inputNames,
                            outputNames: widget.outputNames,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.x12,
                  bottom: AppSpacing.x12,
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

  /// Scales about the centre of the viewport, so zooming does not drift.
  void _zoomBy(double factor, Size viewport) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor)
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    if (target == current) return;

    final centre = Offset(viewport.width / 2, viewport.height / 2);
    final worldCentre = _toWorld(centre);
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
        .min(
          viewport.width / padded.width,
          viewport.height / padded.height,
        )
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);

    setState(() {
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          viewport.width / 2,
          viewport.height / 2,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1)
        ..translateByDouble(-padded.center.dx, -padded.center.dy, 0, 1);
    });
  }

  /// Screen point to world point, through the inverse of the live transform.
  ///
  /// Every gesture in Phase 3 resolves its target this way, so there is one
  /// inverse and no chance of the painter and hit-testing disagreeing.
  Offset _toWorld(Offset screen) => MatrixUtils.transformPoint(
        Matrix4.inverted(_transform.value),
        screen,
      );
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
          ),
          IconButton(
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_outlined),
            tooltip: 'Fit to board',
          ),
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
            tooltip: 'Zoom in',
          ),
        ],
      ),
    );
  }
}
