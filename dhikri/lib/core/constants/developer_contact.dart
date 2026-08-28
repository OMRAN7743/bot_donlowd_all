/// المصدر الوحيد لرقم المطور في كل التطبيق.
///
/// لا تُكرّر الرقم في أي ملف آخر — عدّله هنا فقط.
abstract final class DeveloperContact {
  /// رقم الهاتف بصيغة دولية كاملة (يُستخدم مع `tel:` و `sms:`).
  static const String phoneE164 = '+967774354548';

  /// نفس الرقم بدون علامة `+` — الصيغة التي يتطلبها واتساب.
  static const String whatsAppNumber = '967774354548';

  /// اسم مالك المشروع كما يظهر في شاشة "عن ذكري".
  static const String displayName = 'مطوّر تطبيق ذكري';
}
