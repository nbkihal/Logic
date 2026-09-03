import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/constants/canvas_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/component.dart';
import '../../domain/models/gate_type.dart';
import '../../domain/models/logic.dart';
import '../../domain/models/port.dart';

/// One component on the board: the body, its ports, and every gesture that
/// targets it.
///
/// The widget is larger than the component it draws — it carries
/// [CanvasConstants.portHitRadius] of padding on every side so the port
/// targets clear 44px without the dots visually leaving the body edge. Hit
/// tests do not reach children drawn outside their parent, so the padding is
/// what makes the ports tappable at all.
class GateWidget extends StatelessWidget {
  const GateWidget({
    super.key,
    required this.component,
    required this.valueAt,
    this.label,
    this.selected = false,
    this.wiringSource,
    this.onTap,
    this.onPortTap,
    this.onMoveStart,
    this.onMoveUpdate,
    this.onMoveEnd,
  });

  /// Total footprint including the port-target padding.
  static const double outerWidth =
      CanvasConstants.componentWidth + CanvasConstants.portHitRadius * 2;
  static const double outerHeight =
      CanvasConstants.componentHeight + CanvasConstants.portHitRadius * 2;
  static const double inset = CanvasConstants.portHitRadius;

  final Component component;
  final Logic Function(String portId) valueAt;
  final String? label;

  /// Draws the selection ring, and tells the HUD what Delete would remove.
  final bool selected;

  /// The output port a wire is currently being drawn from, if any. Compatible
  /// input ports pulse while this is set, so wiring feels guided.
  final Port? wiringSource;

  final VoidCallback? onTap;
  final void Function(Port port)? onPortTap;
  final VoidCallback? onMoveStart;
  final void Function(Offset globalPosition)? onMoveUpdate;
  final VoidCallback? onMoveEnd;

  Logic get _outputValue => component.hasOutputPort
      ? valueAt(Port.outputId(component.id))
      : valueAt(Port.inputId(component.id, 0));

  bool get _isWiring => wiringSource != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerWidth,
      height: outerHeight,
      child: Stack(
        children: [
          Positioned(
            left: inset,
            top: inset,
            width: CanvasConstants.componentWidth,
            height: CanvasConstants.componentHeight,
            child: Semantics(
              label: _semanticLabel,
              button: true,
              container: true,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                // Long-press to drag, so moving a component never fights the
                // canvas pan for the same one-finger gesture.
                onLongPressStart: (_) => onMoveStart?.call(),
                onLongPressMoveUpdate: (d) =>
                    onMoveUpdate?.call(d.globalPosition),
                onLongPressEnd: (_) => onMoveEnd?.call(),
                onLongPressCancel: onMoveEnd,
                child: _body(context),
              ),
            ),
          ),
          ..._ports(),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final body = switch (component.type) {
      GateType.input => _PinBody(label: label ?? 'IN', value: _outputValue),
      GateType.constant => _PinBody(
          label: component.constantValue ? '1' : '0',
          value: _outputValue,
        ),
      GateType.output => _LampBody(label: label ?? 'OUT', value: _outputValue),
      _ => _GateBody(type: component.type, value: _outputValue),
    };

    if (!selected) return body;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.small + 4),
        border: Border.all(color: context.colors.plasmaViolet, width: 3),
      ),
      child: Padding(padding: const EdgeInsets.all(3), child: body),
    );
  }

  List<Widget> _ports() {
    final dots = <Widget>[];
    final count = component.inputPortCount;

    for (var i = 0; i < count; i++) {
      final fraction = count <= 1 ? 0.5 : (i + 1) / (count + 1);
      final port = Port.input(component.id, i);
      dots.add(
        _PortTarget(
          centre: Offset(
            inset,
            inset + CanvasConstants.componentHeight * fraction,
          ),
          value: valueAt(port.id),
          // While a wire is being drawn, free input ports invite the drop.
          highlighted: _isWiring &&
              wiringSource!.componentId != component.id &&
              valueAt(port.id).isFloating,
          dimmed: _isWiring && !valueAt(port.id).isFloating,
          onTap: () => onPortTap?.call(port),
          semanticLabel: 'Input ${i + 1} of $_shortName',
        ),
      );
    }

    if (component.hasOutputPort) {
      final port = Port.output(component.id);
      dots.add(
        _PortTarget(
          centre: const Offset(
            inset + CanvasConstants.componentWidth,
            inset + CanvasConstants.componentHeight / 2,
          ),
          value: valueAt(port.id),
          highlighted: wiringSource?.id == port.id,
          dimmed: _isWiring && wiringSource?.id != port.id,
          onTap: () => onPortTap?.call(port),
          semanticLabel: 'Output of $_shortName',
        ),
      );
    }

    return dots;
  }

  String get _shortName => switch (component.type) {
        GateType.input => 'input ${label ?? ''}',
        GateType.output => 'output ${label ?? ''}',
        GateType.constant => 'constant',
        _ => '${component.type.label} gate',
      };

  String get _semanticLabel {
    final state = switch (_outputValue) {
      Logic.high => 'high',
      Logic.low => 'low',
      Logic.floating => 'not connected',
    };
    return switch (component.type) {
      GateType.input =>
        'Input ${label ?? ''} switch, $state. Double tap to flip.',
      GateType.output => 'Output ${label ?? ''} lamp, $state',
      GateType.constant => 'Constant ${component.constantValue ? '1' : '0'}',
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
    return ValuePulse(
      value: value,
      child: AnimatedContainer(
        duration: AnimationConstants.gateFire,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: value.isHigh
              ? Color.lerp(context.colors.limestone, context.colors.ember, 0.18)
              : context.colors.limestone,
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: Border.all(
            color:
                value.isHigh ? context.colors.ember : context.colors.obsidian,
            width: value.isHigh ? 2.5 : 1.5,
          ),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Text(
              type.label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            // Gates carry their glyph too, so a gate's output value never
            // depends on the border colour alone (CLAUDE.md §16).
            Text(value.glyph, style: pinLabelOf(context)),
          ],
        ),
      ),
    );
  }
}

/// A quick swell when [value] rises to high, and nothing at all otherwise.
///
/// This is the "gate fire" beat from the animation catalogue: the moment a
/// gate starts asserting a 1 is the moment worth pointing at, and it reads
/// even when the gate is one of twenty on the board.
class ValuePulse extends StatefulWidget {
  const ValuePulse({super.key, required this.value, required this.child});

  final Logic value;
  final Widget child;

  @override
  State<ValuePulse> createState() => _ValuePulseState();
}

class _ValuePulseState extends State<ValuePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fire = AnimationController(
    vsync: this,
    duration: AnimationConstants.gateFire,
  );

  @override
  void didUpdateWidget(ValuePulse old) {
    super.didUpdateWidget(old);
    if (widget.value.isHigh && !old.value.isHigh) {
      _fire.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fire,
      builder: (context, child) {
        // Out and back within the one controller: 0 -> 1 -> 0 on scale.
        final t = _fire.value == 0 ? 0.0 : (1 - (_fire.value * 2 - 1).abs());
        return Transform.scale(
          scale: 1 + Curves.easeOut.transform(t) * 0.06,
          child: child,
        );
      },
      child: widget.child,
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
    final ink = high ? context.colors.onEmber : context.colors.obsidian;
    return AnimatedContainer(
      duration: AnimationConstants.toggleSwitch,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: high ? context.colors.ember : context.colors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: context.colors.obsidian, width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: ink),
            ),
            const SizedBox(width: AppSpacing.x4),
            Text(value.glyph, style: pinLabelOf(context, on: ink)),
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
        AnimatedContainer(
          duration: high
              ? AnimationConstants.lampGlowIn
              : AnimationConstants.lampGlowOut,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: high ? context.colors.ember : context.colors.limestone,
            border: Border.all(color: context.colors.obsidian, width: 1.5),
            boxShadow: [
              // Always present, so the halo grows and fades rather than
              // appearing from nothing.
              BoxShadow(
                color: high
                    ? context.colors.bloom
                    : context.colors.bloom.withValues(alpha: 0),
                blurRadius: high ? 20 : 0,
                spreadRadius: high ? 3 : 0,
              ),
            ],
          ),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: Text(
                value.glyph,
                style: pinLabelOf(
                  context,
                  on: high ? context.colors.onEmber : context.colors.obsidian,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A port: a small dot with a touch target far larger than it looks.
class _PortTarget extends StatelessWidget {
  const _PortTarget({
    required this.centre,
    required this.value,
    required this.highlighted,
    required this.dimmed,
    required this.onTap,
    required this.semanticLabel,
  });

  final Offset centre;
  final Logic value;
  final bool highlighted;
  final bool dimmed;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    const hit = CanvasConstants.portHitRadius;
    final radius =
        highlighted ? CanvasConstants.portRadius + 3 : CanvasConstants.portRadius;

    final fill = switch (value) {
      Logic.high => context.colors.signalHigh,
      Logic.low => context.colors.signalLow,
      Logic.floating => context.colors.limestone,
    };

    return Positioned(
      left: centre.dx - hit,
      top: centre.dy - hit,
      width: hit * 2,
      height: hit * 2,
      child: Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedOpacity(
              opacity: dimmed ? 0.35 : 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: highlighted
                        ? context.colors.plasmaViolet
                        : value.isFloating
                            ? context.colors.signalFloating
                            : context.colors.obsidian,
                    width: highlighted ? 3 : 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
