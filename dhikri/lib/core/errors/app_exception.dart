/// أخطاء التطبيق المعروفة، برسائل عربية جاهزة للعرض.
sealed class AppException implements Exception {
  const AppException(this.userMessage, {this.debugDetail});

  /// رسالة عربية قصيرة تُعرض للمستخدم.
  final String userMessage;

  /// تفاصيل تقنية تُسجَّل في وضع التطوير فقط.
  final String? debugDetail;

  @override
  String toString() =>
      '$runtimeType: $userMessage${debugDetail == null ? '' : ' ($debugDetail)'}';
}

/// تعذّر تحميل ملف بيانات الأذكار أو أنه غير صالح.
class ContentLoadException extends AppException {
  const ContentLoadException(super.userMessage, {super.debugDetail});
}

/// سجل ذكر أو قسم غير صالح داخل ملف البيانات.
class ContentValidationException extends AppException {
  const ContentValidationException(
    super.userMessage, {
    super.debugDetail,
    this.issues = const <String>[],
  });

  /// قائمة المشكلات المكتشفة (تُستخدم في أداة التحقق وفي الاختبارات).
  final List<String> issues;
}

/// تعذّر تشغيل الصوت.
class NarrationException extends AppException {
  const NarrationException(super.userMessage, {super.debugDetail});
}

/// تعذّر فتح تطبيق خارجي (واتساب، الهاتف، الرسائل).
class ExternalAppException extends AppException {
  const ExternalAppException(super.userMessage, {super.debugDetail});
}
