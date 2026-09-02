import 'package:flutter/painting.dart';

/// Caldera palette — see `DESIGN.md`. Three chromatic tones only
/// (Ember, Plasma Violet, Sulfur) against warm monochrome grays.
///
/// Do not introduce accent colors beyond these; the palette is
/// deliberately constrained.
abstract final class AppColors {
  /// Primary action buttons, featured surfaces — the only aggressive accent.
  static const ember = Color(0xFFFC5000);

  /// Hero halftone / a single accent surface. Never used for controls.
  static const plasmaViolet = Color(0xFF524AE9);

  /// Tag and category badge backgrounds.
  static const sulfur = Color(0xFFF5F28E);

  /// Card surfaces, content blocks, secondary button fills.
  static const limestone = Color(0xFFF7F6F2);

  /// Page canvas — the dominant background.
  static const pumice = Color(0xFFE2E2DF);

  /// Primary text, headings, borders.
  static const obsidian = Color(0xFF070607);

  /// Text on dark surfaces only.
  static const chalk = Color(0xFFFFFFFF);

  // --- Derived, non-brand utility tints (opacity of the above only) ---

  /// Hairline rules and dotted dividers.
  static const hairline = Color(0x1A070607);

  /// Muted/secondary text.
  static const obsidianMuted = Color(0x99070607);

  /// Disabled/locked surfaces.
  static const obsidianFaint = Color(0x33070607);
}

/// Colors that encode circuit *values*. Value is never carried by hue alone —
/// brightness, glyphs, and dash patterns carry it too (see CLAUDE.md §16).
abstract final class SignalColors {
  /// Logic low (0): dark, de-energized.
  static const low = Color(0xFF3A3739);

  /// Logic high (1): energized ember.
  static const high = AppColors.ember;

  /// Floating (X): rendered dashed and grey.
  static const floating = Color(0xFF9A9793);

  /// Glow halo around an energized lamp.
  static const bloom = Color(0x66FC5000);

  /// Cycle / error emphasis (amber-side of ember, still within family).
  static const warning = Color(0xFFF5F28E);
}
