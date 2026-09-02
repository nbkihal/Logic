import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the Caldera tokens into a Material theme.
///
/// The system is deliberately shadowless: hierarchy comes from color contrast
/// (Pumice canvas -> Limestone cards -> Ember features) and generous radii.
abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ember,
      onPrimary: AppColors.obsidian,
      secondary: AppColors.sulfur,
      onSecondary: AppColors.obsidian,
      tertiary: AppColors.plasmaViolet,
      onTertiary: AppColors.chalk,
      error: AppColors.ember,
      onError: AppColors.chalk,
      surface: AppColors.limestone,
      onSurface: AppColors.obsidian,
      surfaceContainerLowest: AppColors.chalk,
      surfaceContainer: AppColors.limestone,
      surfaceContainerHighest: AppColors.pumice,
      outline: AppColors.obsidian,
      outlineVariant: AppColors.hairline,
      inverseSurface: AppColors.obsidian,
      onInverseSurface: AppColors.chalk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.pumice,
      canvasColor: AppColors.pumice,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.body,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pumice,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.obsidian,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.limestone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      // Primary CTA: Ember fill, Obsidian text, full pill, 12/24 padding.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: AppColors.obsidian,
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
          backgroundColor: AppColors.limestone,
          foregroundColor: AppColors.obsidian,
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
          foregroundColor: AppColors.obsidian,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x24,
            vertical: AppSpacing.x12,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
          side: const BorderSide(color: AppColors.obsidian, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.obsidian,
          textStyle: AppTypography.textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.obsidian,
          // >= 44px effective touch target (CLAUDE.md §16).
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sulfur,
        side: BorderSide.none,
        labelStyle: AppTypography.textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x4,
        ),
        shape: const StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: AppSpacing.x24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.limestone,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x32,
          vertical: AppSpacing.x24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.obsidian, width: 1.5),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.ember,
        inactiveTrackColor: AppColors.hairline,
        thumbColor: AppColors.obsidian,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.obsidian
              : AppColors.limestone,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.ember
              : AppColors.obsidianFaint,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.limestone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.obsidian,
        contentTextStyle:
            AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.chalk),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
    );
  }
}
