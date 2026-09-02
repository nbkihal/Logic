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
/// A monospace fallback carries pin labels, where character alignment matters
/// more than brand presence.
abstract final class AppTypography {
  static const display = 'Anton';
  static const body = 'DMSans';
  static const mono = 'monospace';

  /// DM Sans ships as a variable font; pin the weight axis to Medium.
  static const _medium = <FontVariation>[FontVariation('wght', 500)];

  /// Positive tracking scales with size (~0.02em) so heavy strokes breathe.
  static double _tracking(double size) => size * 0.02;

  static TextStyle _display(double size, double height) => TextStyle(
        fontFamily: display,
        fontSize: size,
        height: height,
        letterSpacing: _tracking(size),
        color: AppColors.obsidian,
      );

  static TextStyle _body(double size, double height) => TextStyle(
        fontFamily: body,
        fontVariations: _medium,
        fontWeight: FontWeight.w500,
        fontSize: size,
        height: height,
        color: AppColors.obsidian,
      );

  /// Maps the Caldera scale onto Material's slots so widgets inherit it.
  static TextTheme get textTheme => TextTheme(
        // Display face — structural scale only (>= 26px).
        displayLarge: _display(96, 0.95),
        displayMedium: _display(80, 1.1),
        displaySmall: _display(56, 1.0),
        headlineLarge: _display(48, 1.0),
        headlineMedium: _display(32, 1.0),
        headlineSmall: _display(26, 1.2),
        // Body face — DM Sans Medium.
        titleLarge: _body(30, 1.5),
        titleMedium: _body(18, 1.4),
        titleSmall: _body(16, 1.4),
        bodyLarge: _body(16, 1.55),
        bodyMedium: _body(14, 1.2),
        bodySmall: _body(12, 1.2),
        labelLarge: _body(16, 1.2),
        labelMedium: _body(14, 1.2),
        labelSmall: _body(12, 1.2),
      );

  /// Pin and port labels on the canvas.
  static const pinLabel = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.obsidian,
  );
}
