import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Caldera type system.
///
/// Two bundled faces:
/// * [display] — Anton, the substitute for PP Neue Corp Compact. Ultrabold
///   compressed; used at 26px and up only, always with positive tracking.
/// * [body] — DM Sans (variable), pinned to Medium (500). Never Regular,
///   never Bold.
///
/// Canvas value glyphs reuse the body face with tabular figures, so digits
/// keep a fixed advance without depending on a platform monospace family.
abstract final class AppTypography {
  static const display = 'Anton';
  static const body = 'DMSans';

  /// DM Sans ships as a variable font; pin the weight axis to Medium.
  static const _medium = <FontVariation>[FontVariation('wght', 500)];

  /// Positive tracking scales with size (~0.02em) so heavy strokes breathe.
  static double _tracking(double size) => size * 0.02;

  static TextStyle _display(double size, double height, Color ink) => TextStyle(
        fontFamily: display,
        fontSize: size,
        height: height,
        letterSpacing: _tracking(size),
        color: ink,
      );

  static TextStyle _body(double size, double height, Color ink) => TextStyle(
        fontFamily: body,
        fontVariations: _medium,
        fontWeight: FontWeight.w500,
        fontSize: size,
        height: height,
        color: ink,
      );

  /// The scale in the default palette's ink. Themed screens go through
  /// [textThemeFor], which is what `AppTheme.build` hands to Material.
  static TextTheme get textTheme => textThemeFor(AppPalette.caldera.obsidian);

  /// Maps the type scale onto Material's slots, in [ink].
  static TextTheme textThemeFor(Color ink) => TextTheme(
        // Display face — structural scale only (>= 26px).
        displayLarge: _display(96, 0.95, ink),
        displayMedium: _display(80, 1.1, ink),
        displaySmall: _display(56, 1.0, ink),
        headlineLarge: _display(48, 1.0, ink),
        headlineMedium: _display(32, 1.0, ink),
        headlineSmall: _display(26, 1.2, ink),
        // Body face — DM Sans Medium.
        titleLarge: _body(30, 1.5, ink),
        titleMedium: _body(18, 1.4, ink),
        titleSmall: _body(16, 1.4, ink),
        bodyLarge: _body(16, 1.55, ink),
        bodyMedium: _body(14, 1.2, ink),
        bodySmall: _body(12, 1.2, ink),
        labelLarge: _body(16, 1.2, ink),
        labelMedium: _body(14, 1.2, ink),
        labelSmall: _body(12, 1.2, ink),
      );

  /// Value glyphs and pin labels on the canvas.
  ///
  /// Tabular figures rather than a monospace *family*: `0`, `1` and `X` want
  /// a fixed advance so they do not jitter as a value flips, but a bare
  /// `monospace` family only resolves on some platforms and renders as tofu
  /// on the rest.
  static const pinLabel = TextStyle(
    fontFamily: body,
    fontVariations: _medium,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 12,
    height: 1.2,
    letterSpacing: 0.5,
    // No colour: pin labels inherit the surrounding ink, so they follow the
    // active palette without every call site restating it.
  );
}

/// The monospace pin/table face, in the active palette's ink.
///
/// [AppTypography.pinLabel] deliberately carries no colour so it inherits;
/// this is where a widget says what it should inherit *from*. Pass [on] for
/// a label that sits on an accent fill rather than on a page surface.
TextStyle pinLabelOf(BuildContext context, {Color? on}) =>
    AppTypography.pinLabel.copyWith(color: on ?? context.colors.obsidian);
