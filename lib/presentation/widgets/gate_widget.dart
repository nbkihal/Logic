import 'package:flutter/material.dart';

import '../../core/constants/canvas_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/component.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/logic.dart';
import '../../domain/models/port.dart';

/// One component rendered on the board: the body plus its ports.
///
/// Components are widgets rather than paint calls so they can host gestures
/// (Phase 3) and semantics, and so each can run its own micro-animations
/// later without repainting the whole canvas.
class GateWidget extends StatelessWidget {
  const GateWidget({
    super.key,
    required this.component,
    required this.valueAt,
    this.label,
  });

  final Component component;

  /// Resolves a port id to its current value.
  final Logic Function(String portId) valueAt;

  /// Column name for a pin or lamp, e.g. `A` or `SUM`. Gates have none.
  final String? label;

  Logic get _outputValue => component.hasOutputPort
      ? valueAt(Port.outputId(component.id))
      : valueAt(Port.inputId(component.id, 0));

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      container: true,
      // The label already states type and value; without this, the body's
      // own text ("AND", "1") is folded in and announced twice.
      excludeSemantics: true,
      child: SizedBox(
        width: CanvasConstants.componentWidth,
        height: CanvasConstants.componentHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _body()),
            ..._ports(),
          ],
        ),
      ),
    );
  }

  Widget _body() => switch (component.type) {
        GateType.input => _PinBody(
            label: label ?? 'IN',
            value: _outputValue,
          ),
        GateType.constant => _PinBody(
            label: component.constantValue ? '1' : '0',
            value: _outputValue,
          ),
        GateType.output => _LampBody(
            label: label ?? 'OUT',
            value: _outputValue,
          ),
        _ => _GateBody(type: component.type, value: _outputValue),
      };

  List<Widget> _ports() {
    final dots = <Widget>[];
    final count = component.inputPortCount;

    for (var i = 0; i < count; i++) {
      final fraction = count <= 1 ? 0.5 : (i + 1) / (count + 1);
      dots.add(
        Positioned(
          left: -CanvasConstants.portRadius,
          top: CanvasConstants.componentHeight * fraction -
              CanvasConstants.portRadius,
          child: _PortDot(value: valueAt(Port.inputId(component.id, i))),
        ),
      );
    }

    if (component.hasOutputPort) {
      dots.add(
        Positioned(
          left: CanvasConstants.componentWidth - CanvasConstants.portRadius,
          top: CanvasConstants.componentHeight / 2 -
              CanvasConstants.portRadius,
          child: _PortDot(value: valueAt(Port.outputId(component.id))),
        ),
      );
    }

    return dots;
  }

  String get _semanticLabel {
    final value = _outputValue;
    final state = switch (value) {
      Logic.high => 'high',
      Logic.low => 'low',
      Logic.floating => 'not connected',
    };
    return switch (component.type) {
      GateType.input => 'Input ${label ?? ''} switch, $state',
      GateType.output => 'Output ${label ?? ''} lamp, $state',
      GateType.constant =>
        'Constant ${component.constantValue ? '1' : '0'}',
      _ => '${component.type.label} gate, output $state',
    };
  }
}

/// A Boolean operator: a flat Limestone block with a hard label.
class _GateBody extends StatelessWidget {
  const _GateBody({required this.type, required this.value});

  final GateType type;
  final Logic value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(
          color: value.isHigh ? AppColors.ember : AppColors.obsidian,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            type.label,
            style: AppTypography.textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
          // Gates carry their glyph too, so a gate's output value never
          // depends on the border colour alone (CLAUDE.md §16).
          Text(value.glyph, style: AppTypography.pinLabel),
        ],
      ),
    );
  }
}

/// An input pin or a constant: a pill that reads its value at a glance.
class _PinBody extends StatelessWidget {
  const _PinBody({required this.label, required this.value});

  final String label;
  final Logic value;

  @override
  Widget build(BuildContext context) {
    final high = value.isHigh;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: high ? AppColors.ember : AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.obsidian, width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.textTheme.labelMedium),
            const SizedBox(width: AppSpacing.x4),
            Text(value.glyph, style: AppTypography.pinLabel),
          ],
        ),
      ),
    );
  }
}

/// An output lamp. Value is carried by fill, by a halo, and by the glyph —
/// never by hue alone.
class _LampBody extends StatelessWidget {
  const _LampBody({required this.label, required this.value});

  final String label;
  final Logic value;

  @override
  Widget build(BuildContext context) {
    final high = value.isHigh;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: high ? AppColors.ember : AppColors.limestone,
            border: Border.all(color: AppColors.obsidian, width: 1.5),
            boxShadow: high
                ? const [
                    BoxShadow(
                      color: SignalColors.bloom,
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: Text(value.glyph, style: AppTypography.pinLabel),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x4),
        Flexible(
          child: Text(
            label,
            style: AppTypography.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A connection point. Filled with its value, ringed in Obsidian so it stays
/// visible against both the Limestone body and the Pumice canvas.
class _PortDot extends StatelessWidget {
  const _PortDot({required this.value});

  final Logic value;

  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      Logic.high => SignalColors.high,
      Logic.low => SignalColors.low,
      Logic.floating => AppColors.limestone,
    };
    return Container(
      width: CanvasConstants.portRadius * 2,
      height: CanvasConstants.portRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: value.isFloating
              ? SignalColors.floating
              : AppColors.obsidian,
          width: 1.5,
        ),
      ),
    );
  }
}
