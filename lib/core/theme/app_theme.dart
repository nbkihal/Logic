import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles a palette into a Material theme.
///
/// The system is deliberately shadowless: hierarchy comes from color contrast
/// (canvas -> card -> accent) and generous radii. Every colour comes from the
/// [AppPalette] passed in, and the palette itself rides along as a theme
/// extension so widgets can reach tokens Material has no slot for.
abstract final class AppTheme {
  /// The default theme, for tests and the first frame before settings load.
  static ThemeData get light => build(AppPalette.caldera);

  static ThemeData build(AppPalette palette) {
    final scheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.ember,
      onPrimary: palette.onEmber,
      secondary: palette.sulfur,
      onSecondary: palette.onSulfur,
      tertiary: palette.plasmaViolet,
      onTertiary: palette.chalk,
      error: palette.ember,
      onError: palette.chalk,
      surface: palette.limestone,
      onSurface: palette.obsidian,
      surfaceContainerLowest: palette.chalk,
      surfaceContainer: palette.limestone,
      surfaceContainerHighest: palette.pumice,
      outline: palette.obsidian,
      outlineVariant: palette.hairline,
      inverseSurface: palette.obsidian,
      onInverseSurface: palette.chalk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.pumice,
      canvasColor: palette.pumice,
      textTheme: AppTypography.textThemeFor(palette.obsidian),
      fontFamily: AppTypography.body,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pumice,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: palette.obsidian,
      ),
      cardTheme: CardThemeData(
        color: palette.limestone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      // Primary CTA: Ember fill, Obsidian text, full pill, 12/24 padding.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.ember,
          foregroundColor: palette.onEmber,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x24,
            vertical: AppSpacing.x12,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      // Secondary: Limestone fill, same pill geometry.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.limestone,
          foregroundColor: palette.obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x24,
            vertical: AppSpacing.x12,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      // Ghost: outlined pill, Obsidian hairline.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.obsidian,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x24,
            vertical: AppSpacing.x12,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
          side: BorderSide(color: palette.obsidian, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.obsidian,
          textStyle: AppTypography.textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.obsidian,
          // >= 44px effective touch target (CLAUDE.md §16).
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.sulfur,
        side: BorderSide.none,
        labelStyle: AppTypography.textThemeFor(palette.onSulfur).labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x4,
        ),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: AppSpacing.x24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.limestone,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x32,
          vertical: AppSpacing.x24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: palette.obsidian, width: 1.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.ember,
        inactiveTrackColor: palette.hairline,
        thumbColor: palette.obsidian,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? palette.obsidian
              : palette.limestone,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? palette.ember
              : palette.obsidianFaint,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.limestone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      extensions: [palette],
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.obsidian,
        contentTextStyle:
            AppTypography.textThemeFor(palette.chalk).bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
    );
  }
}
