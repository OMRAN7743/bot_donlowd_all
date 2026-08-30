import 'package:flutter/material.dart';

/// خط التطبيق ونظام أحجامه.
///
/// الملف `assets/fonts/NotoSansArabic.ttf` خط متغيّر (variable font)، لذلك
/// نضبط الوزن عبر [FontVariation] وليس عبر `fontWeight` وحده — وإلا استُخدم
/// الوزن الافتراضي 400 أو حدث تعتيم صناعي غير مضبوط.
abstract final class AppTypography {
  static const String fontFamily = 'NotoSansArabic';

  /// تباعد الأسطر للنصوص الطويلة (المواصفات: 1.7 – 1.9).
  static const double bodyLineHeight = 1.8;
  static const double dhikrLineHeight = 1.9;

  /// يبني نمط نص بالوزن الصحيح للخط المتغيّر.
  static TextStyle styled({
    required double fontSize,
    FontWeight weight = FontWeight.w400,
    double? height,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: weight,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// أحجام النص الأساسية قبل تطبيق معامل المستخدم.
  ///
  /// [scale] هو `AppSettings.effectiveTextScale`.
  static TextTheme textTheme({
    required double scale,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    double s(double v) => v * scale;

    return TextTheme(
      // العناوين الكبيرة (24 – 30sp)
      displaySmall: styled(
        fontSize: s(30),
        weight: FontWeight.w700,
        height: 1.35,
        color: onSurface,
      ),
      headlineMedium: styled(
        fontSize: s(26),
        weight: FontWeight.w700,
        height: 1.4,
        color: onSurface,
      ),
      headlineSmall: styled(
        fontSize: s(24),
        weight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      titleLarge: styled(
        fontSize: s(22),
        weight: FontWeight.w600,
        height: 1.45,
        color: onSurface,
      ),
      titleMedium: styled(
        fontSize: s(20),
        weight: FontWeight.w600,
        height: 1.5,
        color: onSurface,
      ),
      titleSmall: styled(
        fontSize: s(18),
        weight: FontWeight.w600,
        height: 1.5,
        color: onSurface,
      ),
      // النص العادي — 20sp افتراضيًا
      bodyLarge: styled(
        fontSize: s(20),
        height: bodyLineHeight,
        color: onSurface,
      ),
      bodyMedium: styled(
        fontSize: s(18),
        height: bodyLineHeight,
        color: onSurface,
      ),
      // البيانات الثانوية — لا تقل عن 14 – 16sp
      bodySmall: styled(fontSize: s(16), height: 1.6, color: onSurfaceVariant),
      labelLarge: styled(
        fontSize: s(19),
        weight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      labelMedium: styled(
        fontSize: s(16),
        weight: FontWeight.w500,
        height: 1.3,
        color: onSurfaceVariant,
      ),
      labelSmall: styled(
        fontSize: s(14),
        weight: FontWeight.w500,
        height: 1.3,
        color: onSurfaceVariant,
      ),
    );
  }

  /// حجم نص الذكر نفسه: 22–26sp عاديًا، و28–34sp في وضع كبار السن.
  static double dhikrFontSize({
    required double scale,
    required bool seniorMode,
    required double screenWidth,
  }) {
    final base = seniorMode
        ? (screenWidth < 360 ? 28.0 : 31.0)
        : (screenWidth < 360 ? 22.0 : 24.0);
    return base * scale;
  }
}
