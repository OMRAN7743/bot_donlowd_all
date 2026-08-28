/// ثوابت عامة للتطبيق.
abstract final class AppConstants {
  /// الاسم العربي الإلزامي — ينتهي بياء، لا بألف مقصورة.
  /// قاعدة التسمية كاملة في CLAUDE.md، ويحرسها اختبار في test/core.
  static const String appNameArabic = 'ذكري';

  /// الاسم الداخلي الإنجليزي.
  static const String appNameLatin = 'Dhikri';

  static const String adhkarAssetPath = 'assets/data/adhkar.json';
  static const String categoriesAssetPath = 'assets/data/categories.json';

  /// بعد هذه المدة نسأل المستخدم: هل تتابع وردك السابق أم تبدأ من جديد؟
  static const Duration staleSessionThreshold = Duration(hours: 12);

  /// مهلة الانتقال التلقائي للذكر التالي بعد الإكمال.
  static const Duration autoNextDelay = Duration(milliseconds: 700);

  /// مدد الحركة القصيرة (spec §32).
  static const Duration shortMotion = Duration(milliseconds: 180);
  static const Duration mediumMotion = Duration(milliseconds: 260);
  static const Duration completionMotion = Duration(milliseconds: 400);

  /// أقل مساحة لمس مقبولة، ونظيرتها في وضع كبار السن.
  static const double minTouchTarget = 48.0;
  static const double seniorTouchTarget = 64.0;
}
