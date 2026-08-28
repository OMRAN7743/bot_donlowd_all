import 'package:flutter/material.dart';

/// لوحة ألوان "ذكري".
///
/// القاعدة: الأخضر الزمردي والكريمي هما الأساس، والذهبي لمسة Accent فقط
/// ولا يُستخدم أبدًا لونًا لنص طويل.
abstract final class AppColors {
  // ---------------- Light ----------------
  static const Color primary = Color(0xFF0F5A4A);
  static const Color primaryDark = Color(0xFF0A473B);
  static const Color gold = Color(0xFFC79A3B);
  static const Color background = Color(0xFFF7F4EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color secondarySurface = Color(0xFFEEF3EF);
  static const Color textPrimary = Color(0xFF1D2A26);
  static const Color textSecondary = Color(0xFF66736E);
  static const Color success = Color(0xFF2E7D5B);
  static const Color error = Color(0xFFB54545);
  static const Color divider = Color(0xFFE3E8E4);

  // ---------------- Dark ----------------
  static const Color darkBackground = Color(0xFF0C1714);
  static const Color darkSurface = Color(0xFF13211D);
  static const Color darkElevatedSurface = Color(0xFF192A25);
  static const Color darkPrimary = Color(0xFF7AC7A8);
  static const Color darkGold = Color(0xFFE2BD68);
  static const Color darkTextPrimary = Color(0xFFF4F7F5);
  static const Color darkTextSecondary = Color(0xFFB7C4BF);
  static const Color darkDivider = Color(0xFF24352F);

  // ------ High contrast overrides (إعداد التباين العالي) ------
  static const Color hcLightText = Color(0xFF0B1512);
  static const Color hcLightSecondaryText = Color(0xFF3A4642);
  static const Color hcDarkText = Color(0xFFFFFFFF);
  static const Color hcDarkSecondaryText = Color(0xFFDCE6E2);
}
