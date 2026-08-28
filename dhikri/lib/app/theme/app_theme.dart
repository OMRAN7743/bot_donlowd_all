import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// يبني ثيمات "ذكري" الفاتحة والداكنة.
abstract final class AppTheme {
  static ThemeData light({
    double textScale = 1.0,
    bool highContrast = false,
    bool seniorMode = false,
  }) {
    final onSurface = highContrast
        ? AppColors.hcLightText
        : AppColors.textPrimary;
    final onSurfaceVariant = highContrast
        ? AppColors.hcLightSecondaryText
        : AppColors.textSecondary;

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.secondarySurface,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.primaryDark,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: onSurface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.secondarySurface,
      surfaceContainerHighest: AppColors.secondarySurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: AppColors.background,
      textScale: textScale,
      seniorMode: seniorMode,
      successColor: AppColors.success,
      accentColor: AppColors.gold,
    );
  }

  static ThemeData dark({
    double textScale = 1.0,
    bool highContrast = false,
    bool seniorMode = false,
  }) {
    final onSurface = highContrast
        ? AppColors.hcDarkText
        : AppColors.darkTextPrimary;
    final onSurfaceVariant = highContrast
        ? AppColors.hcDarkSecondaryText
        : AppColors.darkTextSecondary;

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: const Color(0xFF04231A),
      primaryContainer: AppColors.darkElevatedSurface,
      onPrimaryContainer: AppColors.darkPrimary,
      secondary: AppColors.darkPrimary,
      onSecondary: const Color(0xFF04231A),
      tertiary: AppColors.darkGold,
      onTertiary: const Color(0xFF23190A),
      error: const Color(0xFFE79191),
      onError: const Color(0xFF3A0F0F),
      surface: AppColors.darkSurface,
      onSurface: onSurface,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkElevatedSurface,
      surfaceContainerHighest: AppColors.darkElevatedSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: AppColors.darkDivider,
      outlineVariant: AppColors.darkDivider,
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: AppColors.darkBackground,
      textScale: textScale,
      seniorMode: seniorMode,
      successColor: AppColors.darkPrimary,
      accentColor: AppColors.darkGold,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required double textScale,
    required bool seniorMode,
    required Color successColor,
    required Color accentColor,
  }) {
    final textTheme = AppTypography.textTheme(
      scale: textScale,
      onSurface: scheme.onSurface,
      onSurfaceVariant: scheme.onSurfaceVariant,
    );
    final minButtonHeight = seniorMode ? 64.0 : 52.0;
    final radius = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: scheme.onSurface,
          size: seniorMode ? 30 : 26,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: scheme.primary,
        minVerticalPadding: seniorMode ? 16 : 10,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: seniorMode ? 8 : 4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, seniorMode ? 56 : 48),
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size.square(seniorMode ? 56 : 48),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: seniorMode ? 82 : 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              (states.contains(WidgetState.selected)
                      ? textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        )
                      : textTheme.labelMedium)
                  ?.copyWith(fontSize: (seniorMode ? 16 : 14) * textScale),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: seniorMode ? 30 : 26,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelStyle: textTheme.labelMedium ?? const TextStyle(),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
      extensions: <ThemeExtension<dynamic>>[
        DhikriTokens(
          success: successColor,
          accent: accentColor,
          seniorMode: seniorMode,
          textScale: textScale,
        ),
      ],
    );
  }
}

/// قيم تصميمية خاصة بـ"ذكري" لا يوفّرها [ColorScheme].
@immutable
class DhikriTokens extends ThemeExtension<DhikriTokens> {
  const DhikriTokens({
    required this.success,
    required this.accent,
    required this.seniorMode,
    required this.textScale,
  });

  /// لون الإكمال — يُستخدم دائمًا مع أيقونة أو نص، لا بمفرده.
  final Color success;

  /// الذهبي: Accent فقط، وممنوع لونًا لفقرة طويلة.
  final Color accent;
  final bool seniorMode;
  final double textScale;

  /// الحشو الأفقي الرئيسي للصفحات (16 – 20dp).
  double get pagePadding => seniorMode ? 20 : 18;

  /// أقل ارتفاع لزر رئيسي.
  double get primaryButtonHeight => seniorMode ? 68 : 56;

  double get sectionGap => seniorMode ? 28 : 22;

  static DhikriTokens of(BuildContext context) =>
      Theme.of(context).extension<DhikriTokens>() ??
      const DhikriTokens(
        success: AppColors.success,
        accent: AppColors.gold,
        seniorMode: false,
        textScale: 1,
      );

  @override
  DhikriTokens copyWith({
    Color? success,
    Color? accent,
    bool? seniorMode,
    double? textScale,
  }) {
    return DhikriTokens(
      success: success ?? this.success,
      accent: accent ?? this.accent,
      seniorMode: seniorMode ?? this.seniorMode,
      textScale: textScale ?? this.textScale,
    );
  }

  @override
  DhikriTokens lerp(covariant DhikriTokens? other, double t) {
    if (other == null) return this;
    return DhikriTokens(
      success: Color.lerp(success, other.success, t) ?? success,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      seniorMode: t < 0.5 ? seniorMode : other.seniorMode,
      textScale: textScale + (other.textScale - textScale) * t,
    );
  }
}
